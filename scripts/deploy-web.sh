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

echo "Restarting Caddy..."
ssh root@$SERVER "cd $REMOTE_PATH && docker compose -f docker-compose.prod.yml restart caddy"

echo "Done! https://wegwiesel.app"
