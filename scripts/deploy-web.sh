#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "Building Flutter web..."
cd app
flutter build web --release
cd ..

echo "Restarting Caddy to pick up new files..."
docker compose -f docker-compose.prod.yml restart caddy

echo "Done! Web app deployed to https://bikerouter.thomas-peterson.de"
