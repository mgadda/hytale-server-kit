#!/bin/bash
# Deploy Hytale server files to remote instance
set -euo pipefail

usage() {
    echo "Usage: $0 <server-ip> [path-to-server-files]"
    echo ""
    echo "Arguments:"
    echo "  server-ip          IP address of the Linode server"
    echo "  path-to-server-files  Directory containing HytaleServer.jar and Assets.zip"
    echo "                        Default: ./server-files"
    echo ""
    echo "Example:"
    echo "  $0 192.168.1.100"
    echo "  $0 192.168.1.100 ~/Downloads/HytaleServer"
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

SERVER_IP="$1"
SERVER_FILES="${2:-./server-files}"

# Validate files exist
if [[ ! -f "$SERVER_FILES/HytaleServer.jar" ]]; then
    echo "Error: HytaleServer.jar not found in $SERVER_FILES"
    echo ""
    echo "To get server files, copy them from your Hytale installation:"
    echo "  Windows: %appdata%\\Hytale\\install\\release\\package\\game\\latest\\Server"
    echo "  macOS: ~/Library/Application Support/Hytale/install/release/package/game/latest/Server"
    exit 1
fi

if [[ ! -f "$SERVER_FILES/Assets.zip" ]]; then
    echo "Error: Assets.zip not found in $SERVER_FILES"
    exit 1
fi

echo "=== Deploying Hytale Server to $SERVER_IP ==="

# Stop the service if running
echo "Stopping Hytale service..."
ssh "root@$SERVER_IP" "systemctl stop hytale 2>/dev/null || true"

# Upload files
echo "Uploading server files..."
scp "$SERVER_FILES/HytaleServer.jar" "root@$SERVER_IP:/opt/hytale/"
scp "$SERVER_FILES/Assets.zip" "root@$SERVER_IP:/opt/hytale/"

# Fix ownership
echo "Setting permissions..."
ssh "root@$SERVER_IP" "chown hytale:hytale /opt/hytale/HytaleServer.jar /opt/hytale/Assets.zip"

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "If this is first-time setup, you need to authenticate:"
echo "  1. SSH to server: ssh root@$SERVER_IP"
echo "  2. Run: sudo -u hytale java -jar /opt/hytale/HytaleServer.jar --assets /opt/hytale/Assets.zip"
echo "  3. In the console, type: /auth login device"
echo "  4. Go to https://accounts.hytale.com/device and enter the code"
echo "  5. Press Ctrl+C to stop the server"
echo "  6. Start service: sudo systemctl start hytale"
echo ""
echo "If already authenticated, start the service:"
echo "  ssh root@$SERVER_IP 'systemctl start hytale'"
echo ""
echo "Connect from Hytale client: $SERVER_IP:5520"
