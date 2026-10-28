#!/bin/sh
# Nightly database dump on the VPS (cron: /etc/cron.d/varsitykotha), kept 14
# days in /opt/varsitykotha/deploy/backups. Off-site copies (age + rclone to
# R2, docs/DEPLOYMENT.md section 4) are still to be set up.
set -eu
cd /opt/varsitykotha/deploy
mkdir -p backups
chmod 700 backups
f="backups/campus-$(date +%F-%H%M).dump"
docker compose exec -T postgres pg_dump -U campus -Fc campus > "$f.tmp"
mv "$f.tmp" "$f"
chmod 600 "$f"
find backups -name 'campus-*.dump' -mtime +14 -delete
echo "backup: $f ($(du -h "$f" | cut -f1))"

# Campus Voice photos (the varsitykotha_media volume, read-only, through a
# throwaway container: the API image has no shell), same 14 days.
if docker volume inspect varsitykotha_media >/dev/null 2>&1; then
  m="backups/media-$(date +%F-%H%M).tar.gz"
  docker run --rm -v varsitykotha_media:/media:ro alpine:3.22 tar -C /media -czf - . > "$m.tmp"
  mv "$m.tmp" "$m"
  chmod 600 "$m"
  echo "backup: $m ($(du -h "$m" | cut -f1))"
fi
find backups -name 'media-*.tar.gz' -mtime +14 -delete
