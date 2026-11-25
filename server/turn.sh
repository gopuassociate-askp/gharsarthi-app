#!/usr/bin/env bash
# TURN relay for SadaSneha video calls (coturn), on the same server as n8n. Run as root in /opt/sadasneha:
#   wget -O turn.sh https://sadasneha.in/server/turn.sh && bash turn.sh
# When two phones cannot reach each other directly (some mobile networks, office Wi-Fi), the call's
# video is relayed through this server instead. Nothing is recorded; the relay only passes packets on.
# Logins are short-lived passwords made by n8n from TURN_SECRET (coturn "use-auth-secret").
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo "Run this in /opt/sadasneha (where .env is)"; exit 1; }
grep -q '^TURN_SECRET=' .env || echo "TURN_SECRET=$(openssl rand -hex 24)" >> .env
SECRET=$(grep '^TURN_SECRET=' .env | cut -d= -f2)
REALM=$(grep '^DOMAIN=' .env | cut -d= -f2)
PUBLIC_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')
echo "== Opening the relay ports in the firewall =="
ufw allow 3478/udp && ufw allow 3478/tcp && ufw allow 49160:49200/udp
echo "== Starting the relay =="
docker rm -f sadasneha-turn >/dev/null 2>&1 || true
docker run -d --name sadasneha-turn --restart unless-stopped --network host coturn/coturn:4.6.3 \
  -n --listening-port=3478 --fingerprint --use-auth-secret --static-auth-secret="$SECRET" --realm="$REALM" \
  --external-ip="$PUBLIC_IP" --min-port=49160 --max-port=49200 --no-cli --no-tlsv1 --no-tlsv1_1 --no-multicast-peers \
  --denied-peer-ip=0.0.0.0-0.255.255.255 --denied-peer-ip=10.0.0.0-10.255.255.255 --denied-peer-ip=100.64.0.0-100.127.255.255 \
  --denied-peer-ip=127.0.0.0-127.255.255.255 --denied-peer-ip=169.254.0.0-169.254.255.255 --denied-peer-ip=172.16.0.0-172.31.255.255 \
  --denied-peer-ip=192.168.0.0-192.168.255.255 --user-quota=12 --total-quota=200 --log-file=stdout --simple-log
sleep 3
docker ps --filter name=sadasneha-turn --format '{{.Names}}: {{.Status}}'
echo
echo "== Done. Last step: copy the line below into n8n =="
echo "   n8n → workflow 'SadaSneha - video calls' → node 'TURN secret' → value"
echo "   (it is a password: paste it only there, never in chat)"
echo
echo "$SECRET"
