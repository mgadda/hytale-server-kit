#!/bin/bash
# Hytale Server Setup Script
# This runs as a Linode StackScript on first boot

set -euo pipefail

echo "=== Hytale Server Setup ==="

# Update system
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y wget apt-transport-https gpg

# Add Adoptium repository for Java 25
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg
echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/adoptium.list

# Install Java 25 Temurin
apt-get update
apt-get install -y temurin-25-jdk || {
    echo "Java 25 not available yet, installing latest available Temurin..."
    apt-get install -y temurin-21-jdk
}

# Create hytale system user
useradd --system --shell /usr/sbin/nologin --home-dir /opt/hytale --create-home hytale

# Create directory structure
mkdir -p /opt/hytale/{universe,logs}
chown -R hytale:hytale /opt/hytale
chmod 750 /opt/hytale

# Install systemd service
cat > /etc/systemd/system/hytale.service << 'EOF'
[Unit]
Description=Hytale Game Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=hytale
Group=hytale
WorkingDirectory=/opt/hytale

# Java options: 3GB heap (leaving 1GB for OS on 4GB instance)
ExecStart=/usr/bin/java -Xmx3G -Xms1G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar HytaleServer.jar --assets Assets.zip

# Restart configuration
Restart=on-failure
RestartSec=10
StartLimitIntervalSec=300
StartLimitBurst=5

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/hytale
PrivateTmp=true

# Resource limits
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload
systemctl enable hytale

# Open firewall (if ufw is enabled)
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 5520/udp comment "Hytale Server"
fi

echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Upload HytaleServer.jar and Assets.zip to /opt/hytale/"
echo "2. Run initial auth: sudo -u hytale java -jar /opt/hytale/HytaleServer.jar --assets /opt/hytale/Assets.zip"
echo "3. Start service: sudo systemctl start hytale"
