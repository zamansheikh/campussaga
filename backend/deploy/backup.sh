#!/bin/sh
# Nightly database dump on the VPS (cron: /etc/cron.d/campussaga), kept 14
# days in /opt/campussaga/deploy/backups. Off-site copies (age + rclone to
# R2, docs/DEPLOYMENT.md section 4) are still to be set up.
set -eu
cd /opt/campussaga/deploy
mkdir -p backups
chmod 700 backups
f="backups/campus-$(date +%F-%H%M).dump"
docker compose exec -T postgres pg_dump -U campus -Fc campus > "$f.tmp"
mv "$f.tmp" "$f"
chmod 600 "$f"
find backups -name 'campus-*.dump' -mtime +14 -delete
echo "backup: $f ($(du -h "$f" | cut -f1))"
