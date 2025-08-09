#!/bin/bash
set -euo pipefail

## Node exporter install script. Quick install:
# curl -fsSL https://raw.githubusercontent.com/lowkasen/common-scripts/refs/heads/main/grafana/install-node-exporter.sh | bash < /dev/tty

# Check if Node Exporter is already installed
if command -v node_exporter &>/dev/null; then
  echo "Node Exporter is already installed."
  sudo systemctl status node_exporter
  exit 0
fi

# Prompt for hostname
read -p "Enter the hostname to set for this machine: " NEW_HOSTNAME

# Replace the placeholder in the script
echo "Current hostname: $(hostname). Setting hostname to $NEW_HOSTNAME."
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# System user for node_exporter
if ! id "node_exporter" &>/dev/null; then
  sudo useradd -rs /bin/false node_exporter
fi

# Download Node Exporter
curl -LO https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.9.1.linux-amd64.tar.gz

# Extract and install
tar xvf node_exporter-1.9.1.linux-amd64.tar.gz
cd node_exporter-1.9.1.linux-amd64
sudo cp node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter --collector.processes

[Install]
WantedBy=default.target
EOF

# Reload systemd to recognize the new service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verify installation
if systemctl status node_exporter | grep -q "active (running)"; then
  echo "Node Exporter installed and running successfully."
else
  echo "Node Exporter installation failed."
fi

## Networking security
# Open up port 9100 to the remote prometheus server
# Or leave it for a local prometheus server to scrape localhost:9100