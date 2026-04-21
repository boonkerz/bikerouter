#!/bin/bash
set -e

SERVER="${1:-204.168.254.31}"
REMOTE_PATH="/opt/wegwiesel"

cd "$(dirname "$0")/.."

echo "Building Flutter web..."
cd app
flutter build web --release
cd ..

echo "Uploading web build to $SERVER..."
rsync -avz --delete app/build/web/ root@$SERVER:$REMOTE_PATH/app/

echo "Updating server config..."
scp docker-compose.prod.yml root@$SERVER:$REMOTE_PATH/docker-compose.prod.yml
scp Caddyfile root@$SERVER:$REMOTE_PATH/Caddyfile
scp Dockerfile.brouter root@$SERVER:$REMOTE_PATH/Dockerfile.brouter

echo "Syncing feedback service..."
rsync -avz --delete \
  --exclude='*.db' --exclude='*.db-*' \
  feedback/ root@$SERVER:$REMOTE_PATH/feedback/

echo "Rebuilding feedback container..."
ssh root@$SERVER "cd $REMOTE_PATH && docker compose -f docker-compose.prod.yml up -d --build feedback"

echo "Reloading Caddy..."
ssh root@$SERVER "cd $REMOTE_PATH && docker compose -f docker-compose.prod.yml up -d caddy && docker compose -f docker-compose.prod.yml exec -T caddy caddy reload --config /etc/caddy/Caddyfile"

echo "Done! https://wegwiesel.app"
