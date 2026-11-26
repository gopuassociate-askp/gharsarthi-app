#!/usr/bin/env bash
# Storage for family chat photos, voice notes and files (a permanent Docker volume). Run as root in /opt/sadasneha:
#   wget -O chat.sh https://sadasneha.in/server/chat.sh && bash chat.sh
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo "Run this in /opt/sadasneha (where .env is)"; exit 1; }
echo "== Updating the server settings =="
curl -fsSL -o docker-compose.yml https://sadasneha.in/server/docker-compose.yml
curl -fsSL -o backup.sh https://sadasneha.in/server/backup.sh && chmod +x backup.sh
echo "== Restarting n8n with the chat storage (about 30 seconds) =="
docker compose up -d
sleep 15
docker compose exec -T -u root n8n sh -c 'mkdir -p /home/node/.n8n-files && chown -R node:node /home/node/.n8n-files'
docker compose exec -T n8n sh -c 'touch /home/node/.n8n-files/.ok && echo "chat storage: ready"'
df -h / | tail -1 | awk '{print "disk: " $3 " used of " $2 " (" $5 ")"}'
