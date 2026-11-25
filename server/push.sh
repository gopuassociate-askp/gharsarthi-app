#!/usr/bin/env bash
# Phone notifications for SadaSneha (calls ring even when the app is closed). Run as root in /opt/sadasneha:
#   wget -O push.sh https://sadasneha.in/server/push.sh && bash push.sh
# Allows n8n's Code nodes to use encryption (crypto only), makes this server's push key once,
# restarts n8n, and shows the private key to paste into n8n (node "Push key").
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo "Run this in /opt/sadasneha (where .env is)"; exit 1; }
echo "== Updating the server settings =="
curl -fsSL -o docker-compose.yml https://sadasneha.in/server/docker-compose.yml
if ! grep -q '^VAPID_PRIVATE=' .env; then
  KEY=$(docker run --rm node:20-alpine node -e "const e=require('crypto').createECDH('prime256v1');e.generateKeys();process.stdout.write(e.getPrivateKey().toString('base64url'))")
  echo "VAPID_PRIVATE=$KEY" >> .env
fi
echo "== Restarting n8n (about 30 seconds) =="
docker compose up -d
sleep 20
docker compose ps --format '{{.Service}}: {{.Status}}'
echo
echo "== Done. Last step: copy the line below into n8n =="
echo "   n8n → workflow 'SadaSneha - push' → node 'Push key' → value   (it is a password: paste it only there)"
echo
grep '^VAPID_PRIVATE=' .env | cut -d= -f2
