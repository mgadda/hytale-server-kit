# Hytale Server Kit

Tools for running a Hytale dedicated server, either locally for development or on Linode for production.

## Overview

| Environment           | Use Case                           | Documentation                        |
| --------------------- | ---------------------------------- | ------------------------------------ |
| [**Local**](local/)   | Development, testing, LAN play     | [local/README.md](local/README.md)   |
| [**Linode**](linode/) | Production hosting, public servers | [linode/README.md](linode/README.md) |

## Quick Comparison

| Feature         | Local (Docker)            | Linode (Terraform)        |
| --------------- | ------------------------- | ------------------------- |
| Setup time      | Minutes                   | ~10 minutes               |
| Cost            | Free                      | ~$12/month                |
| Performance     | Depends on your machine   | Dedicated 4GB instance    |
| Internet access | Requires port forwarding  | Public IP included        |
| Best for        | Development, testing, LAN | Public servers, always-on |

## Prerequisites

Both environments require:

- **Hytale account** with server access
- **Server files** — Either from your Hytale launcher installation or via [hytale-downloader](https://downloader.hytale.com/)

### Getting Server Files

The server requires two files from your Hytale installation:

```
~/Library/Application Support/Hytale/install/release/package/game/latest/
├── Server/
│   ├── HytaleServer.jar    # Server binary
│   └── HytaleServer.aot    # AOT cache (faster startup)
└── Assets.zip              # Game assets
```

Both deployment methods include scripts to copy these automatically.

## Local Development

Docker-based setup for running on your own machine.

```bash
cd local
./build.sh        # Copy server files from launcher
./hytale.sh auth  # Authenticate (first time only)
./hytale.sh start # Start server
```

Connect: `localhost:5520`

See [local/README.md](local/README.md) for full documentation.

## Linode Production

Terraform-managed Ubuntu server on Linode infrastructure.

```bash
cd linode/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Linode API token and SSH key
terraform init
terraform apply
```

Then deploy server files:

```bash
cd linode/scripts
./deploy.sh <server-ip>
```

See [linode/README.md](linode/README.md) for full documentation.

## Server Authentication

Both environments require one-time authentication with your Hytale account:

1. Start the server interactively
2. Run `/auth login device` in the server console
3. Visit https://accounts.hytale.com/device and enter the code
4. Choose persistence method (`Encrypted` recommended)

Auth tokens persist across restarts once configured.

## Network Requirements

Hytale servers use **QUIC over UDP** on port **5520**.

- Local: Exposed automatically via Docker
- Linode: Firewall configured via Terraform
- Home network: Forward UDP 5520 on your router for internet access

## Directory Structure

```
hytale_server/
├── README.md           # This file
├── local/              # Docker-based local development
│   ├── README.md
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── build.sh        # Copy server files
│   ├── hytale.sh       # Management script
│   ├── server/         # Server binaries (generated)
│   └── data/           # User data (generated)
└── linode/             # Terraform-based Linode deployment
    ├── README.md
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── firewall.tf
    │   └── outputs.tf
    ├── scripts/
    │   ├── setup.sh    # Server provisioning
    │   └── deploy.sh   # File deployment
    └── systemd/
        └── hytale.service
```

## License

This tooling is provided as-is for personal use. Hytale and related assets are property of Hypixel Studios.
