#!/usr/bin/env bash
# Nightly backup of the database (workflows, credentials, tables). Keeps 14 days.
# Copy the backups off the server too (another region or your own storage).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
f="backups/n8n-$(date +%Y%m%d-%H%M).sql.gz"
docker compose exec -T postgres pg_dump -U n8n n8n | gzip > "$f"
find backups -name 'n8n-*.sql.gz' -mtime +14 -delete
echo "backup written: $f"
