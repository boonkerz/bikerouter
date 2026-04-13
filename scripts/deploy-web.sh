#!/bin/bash
set -e

SERVER="${1:-bikerouter.thomas-peterson.de}"
REMOTE_PATH="/opt/bikerouter"

cd "$(dirname "$0")/.."

echo "Building Flutter web..."
cd app
flutter build web --release
cd ..

echo "Uploading to $SERVER..."
rsync -avz --delete app/build/web/ root@$SERVER:$REMOTE_PATH/web/

echo "Restarting Caddy..."
ssh root@$SERVER "cd $REMOTE_PATH && docker compose -f docker-compose.prod.yml restart caddy"

echo "Done! https://$SERVER"
