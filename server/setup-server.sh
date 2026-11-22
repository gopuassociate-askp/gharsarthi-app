#!/usr/bin/env bash
# One-time setup of a fresh Ubuntu 22.04/24.04 server for SadaSneha.
# Run as root:  bash setup-server.sh
set -euo pipefail
# Small servers (1 GB RAM): add 2 GB of swap once, so n8n and its database never run out of memory
if [ ! -f /swapfile ] && [ "$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)" -lt 1900 ]; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl -w vm.swappiness=10 >/dev/null; grep -q swappiness /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf
fi
apt-get update -y
apt-get install -y ca-certificates curl ufw
if ! command -v docker >/dev/null; then curl -fsSL https://get.docker.com | sh; fi
ufw allow OpenSSH && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable
cd "$(dirname "$0")"
if [ ! -f .env ]; then
  if [ -f .env.example ]; then cp .env.example .env; else cp env.example .env; fi
  sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 24)/" .env
  sed -i "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)/" .env
  echo "Created .env with fresh passwords. Now set DOMAIN in .env, then run: docker compose up -d"
  echo "Keep a copy of N8N_ENCRYPTION_KEY somewhere safe: without it saved credentials cannot be read."
else
  grep -q '^N8N_VERSION=.\+' .env || { echo "Set N8N_VERSION in .env first (see .env.example)"; exit 1; }
  grep -q '^DOMAIN=app.example.in' .env && { echo "Set DOMAIN in .env first"; exit 1; }
  docker compose up -d
fi
(crontab -l 2>/dev/null | grep -v backup.sh; echo "30 2 * * * $(pwd)/backup.sh >> /var/log/gs-backup.log 2>&1") | crontab -
