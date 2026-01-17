#!/bin/bash
# Build Hytale server Docker image and copy server files
#
# Usage:
#   ./build.sh                    # Use launcher files (default)
#   ./build.sh --downloader       # Use hytale-downloader CLI
#   ./build.sh --downloader --pre-release  # Use pre-release channel
#   ./build.sh --force            # Force copy even if unchanged
#
# Directory structure:
#   ./server/  - Server binaries (copied from launcher or downloader)
#   ./data/    - User data (created if needed, persists across runs)

set -euo pipefail
cd "$(dirname "$0")"

USE_DOWNLOADER=false
PATCHLINE="release"
FORCE_COPY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --downloader|-d)
            USE_DOWNLOADER=true
            shift
            ;;
        --pre-release|--prerelease)
            PATCHLINE="pre-release"
            shift
            ;;
        --force|-f)
            FORCE_COPY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --downloader, -d    Use hytale-downloader CLI instead of launcher files"
            echo "  --pre-release       Download from pre-release channel (requires --downloader)"
            echo "  --force, -f         Force copy even if files haven't changed"
            echo ""
            echo "Environment variables:"
            echo "  HYTALE_LAUNCHER_PATH    Override launcher installation path"
            echo "  HYTALE_DOWNLOADER_PATH  Path to hytale-downloader binary"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Checksum helper - returns md5 hash of a file
file_hash() {
    md5 -q "$1" 2>/dev/null || md5sum "$1" 2>/dev/null | cut -d' ' -f1 || echo ""
}

# Check if file needs copying (different or missing)
needs_copy() {
    local src="$1"
    local dst="$2"

    if $FORCE_COPY; then
        return 0  # Force copy
    fi

    if [[ ! -f "$dst" ]]; then
        return 0  # Destination missing
    fi

    local src_hash=$(file_hash "$src")
    local dst_hash=$(file_hash "$dst")

    [[ "$src_hash" != "$dst_hash" ]]
}

mkdir -p server/

if $USE_DOWNLOADER; then
    echo "=== Downloading Server Binaries (via downloader) ==="
    echo "Patchline: $PATCHLINE"
    echo ""
    echo "Note: Downloader always fetches fresh (use launcher method for caching)"
    echo ""

    DOWNLOADER="${HYTALE_DOWNLOADER_PATH:-./hytale-downloader}"

    if [[ ! -x "$DOWNLOADER" ]]; then
        echo "hytale-downloader not found at: $DOWNLOADER"
        echo ""
        echo "Download it from: https://downloader.hytale.com/hytale-downloader.zip"
        echo "Extract and place in this directory, or set HYTALE_DOWNLOADER_PATH"
        exit 1
    fi

    # Clear existing and download fresh
    rm -rf server/*

    # Download to temp zip
    echo "Downloading server files..."
    "$DOWNLOADER" -patchline "$PATCHLINE" -download-path server/game.zip

    # Extract
    echo "Extracting..."
    unzip -q server/game.zip -d server/
    rm server/game.zip

    # Move files to expected locations
    mv server/Server/* server/
    rmdir server/Server
    # Assets.zip should already be at the right level

else
    # Default: copy from launcher
    LAUNCHER_PATH="${HYTALE_LAUNCHER_PATH:-$HOME/Library/Application Support/Hytale/install/release/package/game/latest}"

    echo "=== Copying Server Binaries (from launcher) ==="
    echo "Source: $LAUNCHER_PATH"
    echo ""

    # Verify launcher files exist
    if [[ ! -d "$LAUNCHER_PATH/Server" ]]; then
        echo "Error: Server directory not found at $LAUNCHER_PATH/Server"
        echo ""
        echo "Make sure Hytale is installed and you've launched the game at least once."
        echo "Or set HYTALE_LAUNCHER_PATH to your installation directory."
        echo ""
        echo "Alternatively, use --downloader to fetch files directly."
        exit 1
    fi

    if [[ ! -f "$LAUNCHER_PATH/Assets.zip" ]]; then
        echo "Error: Assets.zip not found at $LAUNCHER_PATH/Assets.zip"
        echo ""
        echo "The server requires Assets.zip (game assets) alongside HytaleServer.jar."
        echo "This file should be in the same directory as the Server folder."
        exit 1
    fi

    # Copy server files with checksum comparison
    COPIED_COUNT=0
    SKIPPED_COUNT=0

    for src_path in "$LAUNCHER_PATH/Server/"*; do
        filename=$(basename "$src_path")
        dst_path="server/$filename"

        if [[ -d "$src_path" ]]; then
            # Directory - always sync with rsync for efficiency
            echo "  Syncing $filename/..."
            rsync -a --delete "$src_path/" "$dst_path/"
            ((COPIED_COUNT++))
        elif needs_copy "$src_path" "$dst_path"; then
            echo "  Copying $filename..."
            cp "$src_path" "$dst_path"
            ((COPIED_COUNT++))
        else
            echo "  Skipping $filename (unchanged)"
            ((SKIPPED_COUNT++))
        fi
    done

    # Copy Assets.zip
    if needs_copy "$LAUNCHER_PATH/Assets.zip" "server/Assets.zip"; then
        echo "  Copying Assets.zip..."
        cp "$LAUNCHER_PATH/Assets.zip" server/
        ((COPIED_COUNT++))
    else
        echo "  Skipping Assets.zip (unchanged)"
        ((SKIPPED_COUNT++))
    fi

    echo ""
    echo "Copied: $COPIED_COUNT, Skipped: $SKIPPED_COUNT (unchanged)"
fi

# Verify required files
echo ""
echo "=== Server Binaries (./server/) ==="

if [[ ! -f server/HytaleServer.jar ]]; then
    echo "Error: HytaleServer.jar not found after copy/extract"
    exit 1
fi
echo "  HytaleServer.jar  $(du -h server/HytaleServer.jar | cut -f1)"

if [[ ! -f server/Assets.zip ]]; then
    echo "Error: Assets.zip not found after copy/extract"
    exit 1
fi
echo "  Assets.zip        $(du -h server/Assets.zip | cut -f1)"

if [[ -f server/HytaleServer.aot ]]; then
    echo "  HytaleServer.aot  $(du -h server/HytaleServer.aot | cut -f1) (AOT cache)"
fi

# Create data directory for user data
echo ""
echo "=== User Data (./data/) ==="
mkdir -p data
echo "  Directory ready"

# Generate stable machine ID for encrypted credential storage
if [[ ! -f data/machine-id ]]; then
    echo "  Generating machine-id for credential encryption..."
    uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]' > data/machine-id
fi
echo "  machine-id: $(cat data/machine-id)"

# Build Docker image (minimal - just Java runtime)
echo ""
echo "=== Building Docker Image ==="
docker build -t hytale-server:local .

echo ""
echo "=== Build Complete ==="
echo ""
echo "Directory structure:"
echo "  ./server/  - Server binaries (read-only at runtime)"
echo "  ./data/    - User data (config, worlds, logs, mods)"
echo ""
echo "Next steps:"
echo "  First time? Run interactively for authentication:"
echo "    ./hytale.sh auth"
echo "    (then type: /auth login device)"
echo ""
echo "  Already authenticated? Start in background:"
echo "    ./hytale.sh start"
echo ""
echo "  Connect from Hytale client: localhost:5520"
