#!/usr/bin/env bash
# SadaSneha server in one step, on a fresh Ubuntu server, as root:
#   curl -fsSL https://sadasneha.in/server/install.sh | sudo bash
# Updates Ubuntu, downloads the server kit to /opt/sadasneha, creates .env with fresh
# passwords, sets the domain and n8n version, and starts n8n with HTTPS once DNS points here.
set -euo pipefail
DOMAIN="${DOMAIN:-app.sadasneha.in}"
N8N_VERSION="${N8N_VERSION:-2.48.5}"
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a
echo "== 1/4 Updating Ubuntu (a few minutes) =="
apt-get update -y && apt-get -y -o Dpkg::Options::=--force-confold upgrade
echo "== 2/4 Downloading the SadaSneha server kit =="
mkdir -p /opt/sadasneha && cd /opt/sadasneha
for f in docker-compose.yml Caddyfile setup-server.sh backup.sh env.example; do curl -fsSLO "https://sadasneha.in/server/$f"; done
echo "== 3/4 Installing Docker, firewall, backups; creating .env =="
bash setup-server.sh || true
sed -i "s/^DOMAIN=.*/DOMAIN=${DOMAIN}/; s/^N8N_VERSION=.*/N8N_VERSION=${N8N_VERSION}/" .env
grep -q '^N8N_VERSION=' .env || echo "N8N_VERSION=${N8N_VERSION}" >> .env
echo "== 4/4 Waiting for ${DOMAIN} to point to this server =="
ME=$(curl -fsS https://checkip.amazonaws.com || true)
for i in $(seq 1 30); do
  IP=$(getent hosts "$DOMAIN" | awk '{print $1}' | head -1 || true)
  [ -n "$IP" ] && [ "$IP" = "$ME" ] && break
  echo "  ${DOMAIN} -> ${IP:-nothing yet} (this server is ${ME}); checking again in 20 s…"; sleep 20
done
bash setup-server.sh
echo
echo "== Done. Open https://${DOMAIN} in a minute to create the owner account. =="
echo "IMPORTANT: copy this line into your password manager (never share it):"
grep '^N8N_ENCRYPTION_KEY=' .env
