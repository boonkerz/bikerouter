#!/bin/bash
set -e

echo "=== BikeRouter Server Setup ==="

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    apt-get update && apt-get install -y docker-compose-plugin
fi

# Clone repo or update
cd /opt
if [ -d bikerouter ]; then
    cd bikerouter
    git pull
else
    git clone https://github.com/YOUR_USERNAME/bikerouter.git
    cd bikerouter
fi

# Download segment data
echo "Downloading segment data (DACH region)..."
bash scripts/download-segments.sh

# Start services
echo "Starting BRouter + Caddy..."
docker compose -f docker-compose.prod.yml up -d --build

echo ""
echo "=== Done! ==="
echo "BRouter API: https://bikerouter.thomas-peterson.de/brouter"
echo ""
echo "Test: curl 'https://bikerouter.thomas-peterson.de/brouter?lonlats=11.5,48.1|11.6,48.2&profile=trekking&format=geojson'"
