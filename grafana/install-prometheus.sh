#!/bin/bash
set -euo pipefail

## Prometheus install script. Quick install:
# curl -fsSL https://raw.githubusercontent.com/lowkasen/common-scripts/refs/heads/main/grafana/install-prometheus.sh | bash

PROMETHEUS_VERSION="3.5.0"
PROMETHEUS_FILENAME="prometheus-${PROMETHEUS_VERSION}.linux-amd64"
PROMETHEUS_TAR="${PROMETHEUS_FILENAME}.tar.gz"

# Check if Prometheus is already installed
if command -v prometheus &>/dev/null; then
  echo "Prometheus is already installed."
  sudo systemctl status prometheus
  exit 0
fi

# Set up Prereqs
if ! id "prometheus" &>/dev/null; then
  sudo useradd -rs /bin/false prometheus
fi
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Download and extract prometheus binary
curl -LO "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_TAR}"
tar xvf "${PROMETHEUS_TAR}"
cd "${PROMETHEUS_FILENAME}"

# Set binaries
sudo cp prometheus promtool /usr/local/bin/
# sudo cp -r consoles console_libraries /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Create prometheus.yaml file in /etc/prometheus/prometheus.yml
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
    - job_name: node
      static_configs:
        - targets:
            - 'localhost:9100'
EOF

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=default.target
EOF

# Start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Verify installation
if systemctl status prometheus | grep -q "active (running)"; then
  echo "Prometheus installed and running successfully."
else
  echo "Prometheus installation failed."
fi

## Networking security
# Open up port 9090 to the remote grafana server. For now its 52.74.126.100/32