# Hytale Local Server

Docker-based tooling for running a Hytale server locally on macOS.

## Prerequisites

- **Docker Desktop** - Install from [docker.com](https://www.docker.com/products/docker-desktop/)
- **Hytale** - Installed and launched at least once (to download game files)

## Quick Start

```bash
cd local

# 1. Build the Docker image from your launcher files
./build.sh

# 2. Start interactively and authenticate
./hytale.sh auth
# In the console, type: /auth login device
# Visit the URL and enter the code
# Press Ctrl+C when done

# 3. Start the server
./hytale.sh start

# 4. Connect from Hytale client
# Server address: localhost:5520
```

## Commands

| Command | Description |
|---------|-------------|
| `./hytale.sh start` | Start server in background |
| `./hytale.sh stop` | Stop server |
| `./hytale.sh restart` | Restart server |
| `./hytale.sh status` | Show server status |
| `./hytale.sh logs` | Follow server logs (Ctrl+C to stop) |
| `./hytale.sh console` | Attach to console for server commands |
| `./hytale.sh auth` | Start interactively for authentication |
| `./hytale.sh build` | Rebuild image from launcher files |
| `./hytale.sh backup` | Backup universe data |

## Building the Image

### From Launcher Files (Default)

The simplest approach—uses files that auto-update when you play Hytale:

```bash
./build.sh           # Only copies changed files (checksum comparison)
./build.sh --force   # Force copy all files
```

The script copies from:
```
~/Library/Application Support/Hytale/install/release/package/game/latest/
├── Server/
│   ├── HytaleServer.jar
│   └── HytaleServer.aot    # AOT cache (optional, improves startup)
└── Assets.zip              # Required game assets
```

Override the path with:
```bash
HYTALE_LAUNCHER_PATH="/path/to/game/files" ./build.sh
```

### From Hytale Downloader

For explicit version control or pre-release builds:

```bash
# Download the tool
curl -O https://downloader.hytale.com/hytale-downloader.zip
unzip hytale-downloader.zip

# Build from release channel
./build.sh --downloader

# Or use pre-release channel
./build.sh --downloader --pre-release
```

## Authentication

Hytale servers require authentication on first run. The auth flow uses OAuth device authorization:

1. Start the server interactively:
   ```bash
   ./hytale.sh auth
   ```

2. In the server console, type:
   ```
   /auth login device
   ```

3. You'll see output like:
   ```
   ===================================================================
   DEVICE AUTHORIZATION
   ===================================================================
   Visit: https://accounts.hytale.com/device
   Enter code: ABCD-1234
   ===================================================================
   ```

4. Visit the URL in your browser and enter the code

5. Once authenticated, press `Ctrl+C` to stop

6. Start normally:
   ```bash
   ./hytale.sh start
   ```

Authentication tokens are stored in `data/` and persist across restarts.

## Server Console

To run server commands (ban players, change settings, etc.):

```bash
./hytale.sh console
```

This attaches to the running container's stdin. Type commands directly.

To detach without stopping: `Ctrl+]` (control + right bracket)

To see available commands, type `/help` in the console.

## Configuration

### JVM Memory Settings

Edit `docker-compose.yml` to adjust memory allocation:

```yaml
environment:
  JAVA_OPTS: "-Xmx3G -Xms1G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200"
```

- `-Xmx3G` — Maximum heap size (adjust based on available RAM)
- `-Xms1G` — Initial heap size

### Server Options

Add Hytale server flags via `HYTALE_OPTS`:

```yaml
environment:
  HYTALE_OPTS: "--disable-sentry --backup --backup-frequency 30"
```

Common options:
| Option | Description |
|--------|-------------|
| `--disable-sentry` | Disable crash reporting (recommended for development) |
| `--backup` | Enable automatic backups |
| `--backup-frequency N` | Backup interval in minutes (default: 30) |
| `--bind 0.0.0.0:PORT` | Change port (default: 5520) |
| `--allow-op` | Enable operator commands |

Run `java -jar HytaleServer.jar --help` for all options.

### Server Configuration Files

Persistent configuration is stored in `data/`:

| File | Purpose |
|------|---------|
| `config.json` | Server configuration |
| `permissions.json` | Permission groups and assignments |
| `whitelist.json` | Whitelisted players |
| `bans.json` | Banned players |

These files are read on startup. Changes made via in-game commands will be saved automatically.

### World Data

World saves are stored in `data/universe/`. Each world has its own directory with:
- Chunk data
- Player data
- World-specific `config.json`

## Updating After Game Updates

When Hytale releases an update:

1. Launch the Hytale client (this updates your local files)
2. Run build to copy updated files:
   ```bash
   ./hytale.sh build
   ```
   Only changed files are copied (checksum comparison).
3. Restart the server:
   ```bash
   ./hytale.sh restart
   ```

Your world data and configuration in `data/` are unaffected—only `server/` is updated.

## Backups

### Manual Backup

```bash
./hytale.sh backup
```

Creates a timestamped archive in `backups/`:
```
backups/universe_20260117_143022.tar.gz
```

The server is briefly stopped during backup to ensure consistency.

### Automatic Backups

Enable in `docker-compose.yml`:
```yaml
environment:
  HYTALE_OPTS: "--backup --backup-frequency 30"
```

Server-managed backups are stored in `data/` (configure with `--backup-dir`).

### Restore from Backup

```bash
./hytale.sh stop
rm -rf data/universe
tar -xzf backups/universe_TIMESTAMP.tar.gz -C data/
./hytale.sh start
```

## Network Configuration

The server uses **QUIC over UDP** (not TCP). Port 5520/udp is exposed by default.

### Local Play

Connect from the Hytale client on the same machine:
```
localhost:5520
```

### LAN Play

Other machines on your network can connect using your local IP:
```
192.168.x.x:5520
```

Find your IP with: `ipconfig getifaddr en0`

### Internet Play

To allow connections from the internet:
1. Forward UDP port 5520 on your router to your machine
2. Share your public IP (or use a dynamic DNS service)

Note: For serious hosting, consider using the `linode/` deployment instead.

## Troubleshooting

### Server won't start

Check logs for errors:
```bash
docker compose logs
```

Common issues:
- **Out of memory**: Reduce `-Xmx` in `JAVA_OPTS`
- **Port in use**: Change port via `--bind` or stop conflicting service
- **Auth expired**: Re-run `./hytale.sh auth`

### Can't connect from client

1. Verify server is running: `./hytale.sh status`
2. Check server finished starting: `./hytale.sh logs` (look for "Server started")
3. Ensure you're using the correct address (`localhost:5520`)
4. Verify UDP port is exposed: `docker compose ps`

### Performance issues

- **High CPU**: Reduce entity counts, limit player count
- **High RAM**: Reduce view distance in world config, lower `-Xmx`
- **Slow startup**: Ensure `HytaleServer.aot` is present (AOT cache)

### Reset everything

To start fresh (removes all world data!):
```bash
./hytale.sh stop
rm -rf data/           # Remove user data (worlds, config, auth)
./hytale.sh build      # Regenerates data/ directory
./hytale.sh auth       # Re-authenticate
```

To also reset server binaries:
```bash
rm -rf server/
./hytale.sh build --force
```

## File Structure

```
local/
├── Dockerfile              # Container definition (minimal - just Java)
├── docker-compose.yml      # Service configuration
├── build.sh                # Copy server files from launcher
├── hytale.sh               # Management script
├── server/                 # (generated) Server binaries - read-only at runtime
│   ├── HytaleServer.jar
│   ├── HytaleServer.aot    # AOT cache for faster startup
│   ├── Assets.zip
│   └── Licenses/
├── data/                   # (generated) User data - persistent across runs
│   ├── config.json
│   ├── permissions.json
│   ├── whitelist.json
│   ├── bans.json
│   ├── machine-id          # Stable ID for credential encryption
│   ├── universe/           # World saves
│   ├── logs/               # Server logs
│   └── mods/               # Installed mods
└── backups/                # (generated) Manual backups
```

Server binaries and user data are kept separate—binaries are mounted read-only, user data is read-write. This allows updating server files without touching your worlds and config.

## Installing Mods

1. Download mods (`.zip` or `.jar`) from sources like [CurseForge](https://www.curseforge.com/hytale)
2. Place them in `data/mods/`
3. Restart the server: `./hytale.sh restart`

Note: The `mods/` directory is mounted as a volume, so you don't need to rebuild the image.
