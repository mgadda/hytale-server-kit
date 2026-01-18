# Hytale Linode Server

Terraform-based tooling for deploying a Hytale server on Linode infrastructure.

## Prerequisites

- **Terraform** >= 1.0 — Install from [terraform.io](https://www.terraform.io/downloads)
- **Linode account** — Sign up at [linode.com](https://www.linode.com/)
- **Linode API token** — Create at Cloud Manager > My Profile > API Tokens
- **SSH key pair** — For server access

## Quick Start

### 1. Configure Terraform

```bash
cd linode/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
linode_token   = "your-linode-api-token"
ssh_public_key = "ssh-ed25519 AAAA... your-key"
root_password  = "a-secure-root-password"

# Optional
region       = "us-west"      # Default: Los Angeles
server_label = "hytale-server"
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan    # Review changes
terraform apply   # Create resources
```

Note the server IP from the output.

### 3. Deploy Server Files

Copy server files from your Hytale installation:

```bash
cd ../scripts
./deploy.sh <server-ip>
```

Or manually specify the files location:
```bash
./deploy.sh <server-ip> /path/to/server/files
```

### 4. Authenticate

SSH to the server and run the initial auth:

```bash
ssh root@<server-ip>
sudo -u hytale java -jar /opt/hytale/HytaleServer.jar --assets /opt/hytale/Assets.zip
```

In the console:
```
/auth login device
```

Visit https://accounts.hytale.com/device and enter the code. Then:
```
/auth persistence set Encrypted
```

Press `Ctrl+C` to stop.

### 5. Start the Service

```bash
sudo systemctl start hytale
sudo systemctl status hytale
```

Connect from Hytale client: `<server-ip>:5520`

## Infrastructure

### Resources Created

| Resource | Description |
|----------|-------------|
| `linode_instance` | Ubuntu 24.04, 4GB RAM (g6-standard-1) |
| `linode_firewall` | UDP 5520 (Hytale), TCP 22 (SSH) |
| `linode_stackscript` | Automated server setup |

### Estimated Cost

~$12/month for a 4GB shared CPU Linode (g6-standard-1).

### Regions

Available Linode regions (set via `region` variable):

| Region | Location |
|--------|----------|
| `us-west` | Los Angeles (default) |
| `us-central` | Dallas |
| `us-east` | Newark |
| `eu-west` | London |
| `eu-central` | Frankfurt |
| `ap-south` | Singapore |

See [Linode regions](https://www.linode.com/docs/products/platform/get-started/guides/choose-a-data-center/) for full list.

## Server Management

### Service Commands

```bash
# Start/stop/restart
sudo systemctl start hytale
sudo systemctl stop hytale
sudo systemctl restart hytale

# Check status
sudo systemctl status hytale

# View logs
sudo journalctl -u hytale -f
```

### Server Console

To access the server console for commands:

```bash
# Stop the service first
sudo systemctl stop hytale

# Run interactively
sudo -u hytale java -jar /opt/hytale/HytaleServer.jar --assets /opt/hytale/Assets.zip

# Run commands, then Ctrl+C and restart service
sudo systemctl start hytale
```

### File Locations

| Path | Contents |
|------|----------|
| `/opt/hytale/` | Server installation |
| `/opt/hytale/HytaleServer.jar` | Server binary |
| `/opt/hytale/Assets.zip` | Game assets |
| `/opt/hytale/config.json` | Server configuration |
| `/opt/hytale/universe/` | World data |
| `/opt/hytale/logs/` | Server logs |

### Configuration

Edit `/opt/hytale/config.json`:

```json
{
  "ServerName": "My Hytale Server",
  "MOTD": "Welcome!",
  "Password": "optional-password",
  "MaxPlayers": 100,
  "Defaults": {
    "World": "default",
    "GameMode": "Adventure"
  }
}
```

Restart the service after changes.

## Updating

When Hytale releases an update:

1. Get new server files (from launcher or downloader)
2. Re-run the deploy script:
   ```bash
   ./deploy.sh <server-ip>
   ```
3. Start the service:
   ```bash
   ssh root@<server-ip> 'systemctl start hytale'
   ```

## Firewall

The Terraform config creates a firewall with:

- **Inbound UDP 5520** — Hytale game traffic (open to all)
- **Inbound TCP 22** — SSH (restricted to your IP)
- **All other inbound** — Blocked
- **All outbound** — Allowed

To update the SSH IP restriction, edit `firewall.tf`:
```hcl
inbound {
  label    = "ssh"
  action   = "ACCEPT"
  protocol = "TCP"
  ports    = "22"
  ipv4     = ["YOUR.IP.ADDRESS/32"]
}
```

Then: `terraform apply`

## Backups

### Linode Backups

Enable via Linode Cloud Manager or add to `main.tf`:
```hcl
resource "linode_instance" "hytale" {
  # ... existing config ...
  backups_enabled = true  # +$2/month
}
```

### Manual Backups

```bash
ssh root@<server-ip>
systemctl stop hytale
tar -czf /root/universe_backup_$(date +%Y%m%d).tar.gz -C /opt/hytale universe
systemctl start hytale
```

Download:
```bash
scp root@<server-ip>:/root/universe_backup_*.tar.gz ./
```

## Destroying

To tear down all infrastructure:

```bash
cd linode/terraform
terraform destroy
```

This permanently deletes the server and all data.

## Troubleshooting

### Server won't start

Check logs:
```bash
sudo journalctl -u hytale -n 50
```

Common issues:
- **Java not found**: Re-run setup script
- **Out of memory**: Upgrade Linode instance type
- **Auth expired**: Re-authenticate interactively

### Can't connect

1. Verify service is running: `systemctl status hytale`
2. Check firewall: `sudo ufw status` or Linode Cloud Manager
3. Verify port is listening: `ss -ulnp | grep 5520`
4. Test from server: `nc -u localhost 5520`

### SSH access denied

Verify your IP is allowed in `firewall.tf` and re-apply:
```bash
terraform apply
```

## File Structure

```
linode/
├── README.md               # This file
├── terraform/
│   ├── main.tf            # Linode instance + StackScript
│   ├── variables.tf       # Input variables
│   ├── firewall.tf        # Firewall rules
│   ├── outputs.tf         # Output values (IP, etc.)
│   ├── terraform.tfvars.example
│   └── terraform.tfvars   # Your config (gitignored)
├── scripts/
│   ├── setup.sh           # Server provisioning (runs on first boot)
│   └── deploy.sh          # Deploy server files
└── systemd/
    └── hytale.service     # Reference systemd unit
```
