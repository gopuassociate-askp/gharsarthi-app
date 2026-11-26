#!/usr/bin/env bash
# Nightly backup of the database (workflows, credentials, tables). Keeps 14 days.
# Copy the backups off the server too (another region or your own storage).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
f="backups/n8n-$(date +%Y%m%d-%H%M).sql.gz"
docker compose exec -T postgres pg_dump -U n8n n8n | gzip > "$f"
find backups -name 'n8n-*.sql.gz' -mtime +14 -delete
# family chat files: one copy a week (Sundays), the last two kept
if [ "$(date +%u)" = "7" ]; then
  docker compose exec -T n8n tar -cf - -C /home/node/.n8n-files . > "backups/chatfiles-$(date +%Y%m%d).tar" || true
  ls -1t backups/chatfiles-*.tar 2>/dev/null | tail -n +3 | xargs -r rm -f
fi
echo "backup written: $f"
