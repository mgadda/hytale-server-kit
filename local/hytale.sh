#!/bin/bash
# Hytale Server Management Script
#
# Usage:
#   ./hytale.sh start     - Start server in background
#   ./hytale.sh stop      - Stop server
#   ./hytale.sh restart   - Restart server
#   ./hytale.sh status    - Show server status
#   ./hytale.sh logs      - Follow server logs
#   ./hytale.sh console   - Attach to server console (for commands)
#   ./hytale.sh auth      - Start interactively for authentication
#   ./hytale.sh build     - Rebuild image from launcher files
#   ./hytale.sh backup    - Backup universe data

set -euo pipefail
cd "$(dirname "$0")"

CONTAINER_NAME="hytale-local"
BACKUP_DIR="./backups"

cmd_start() {
    echo "Starting Hytale server..."
    docker compose up -d
    echo "Server started. Use './hytale.sh logs' to view output."
    echo "Connect from client: localhost:5520"
}

cmd_stop() {
    echo "Stopping Hytale server..."
    docker compose down
    echo "Server stopped."
}

cmd_restart() {
    echo "Restarting Hytale server..."
    docker compose restart
    echo "Server restarted."
}

cmd_status() {
    if docker compose ps --quiet 2>/dev/null | grep -q .; then
        echo "Hytale server is RUNNING"
        echo ""
        docker compose ps
    else
        echo "Hytale server is STOPPED"
    fi
}

cmd_logs() {
    docker compose logs -f
}

cmd_console() {
    if ! docker compose ps --quiet 2>/dev/null | grep -q .; then
        echo "Server is not running. Start it first with: ./hytale.sh start"
        exit 1
    fi
    echo "Attaching to server console..."
    echo "Type server commands directly."
    echo ""
    echo "To detach WITHOUT stopping: press Ctrl+] (control + right bracket)"
    echo ""
    docker attach --detach-keys="ctrl-]" "$CONTAINER_NAME"
}

cmd_auth() {
    # Stop any existing instance first
    if docker compose ps --quiet 2>/dev/null | grep -q .; then
        echo "Stopping existing server..."
        docker compose down
    fi

    echo "Starting server interactively for authentication..."
    echo ""
    echo "Once started:"
    echo "  1. Type: /auth login device"
    echo "  2. Visit the URL shown and enter the code"
    echo "  3. Press Ctrl+C when done"
    echo ""
    # Use 'run' instead of 'up' for proper stdin attachment
    # --service-ports exposes the port mapping from compose file
    # --rm removes the container after exit
    docker compose run --rm --service-ports hytale
}

cmd_build() {
    ./build.sh
}

cmd_backup() {
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/universe_$TIMESTAMP.tar.gz"

    echo "Creating backup..."

    # Stop if running to ensure consistent backup
    WAS_RUNNING=false
    if docker compose ps --quiet 2>/dev/null | grep -q .; then
        WAS_RUNNING=true
        echo "Stopping server for consistent backup..."
        docker compose stop
    fi

    tar -czf "$BACKUP_FILE" -C data universe

    if $WAS_RUNNING; then
        echo "Restarting server..."
        docker compose start
    fi

    echo "Backup created: $BACKUP_FILE"
    echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
}

cmd_help() {
    echo "Hytale Server Management"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  start     Start server in background"
    echo "  stop      Stop server"
    echo "  restart   Restart server"
    echo "  status    Show server status"
    echo "  logs      Follow server logs (Ctrl+C to stop following)"
    echo "  console   Attach to server console for commands"
    echo "  auth      Start interactively for first-time authentication"
    echo "  build     Rebuild Docker image from launcher files"
    echo "  backup    Backup universe data to ./backups/"
    echo ""
    echo "First-time setup:"
    echo "  1. ./hytale.sh build    # Build image from launcher files"
    echo "  2. ./hytale.sh auth     # Authenticate with Hytale"
    echo "  3. ./hytale.sh start    # Run in background"
}

# Parse command
case "${1:-help}" in
    start)   cmd_start ;;
    stop)    cmd_stop ;;
    restart) cmd_restart ;;
    status)  cmd_status ;;
    logs)    cmd_logs ;;
    console) cmd_console ;;
    auth)    cmd_auth ;;
    build)   cmd_build ;;
    backup)  cmd_backup ;;
    help|--help|-h) cmd_help ;;
    *)
        echo "Unknown command: $1"
        echo ""
        cmd_help
        exit 1
        ;;
esac
