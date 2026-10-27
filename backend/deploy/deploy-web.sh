#!/usr/bin/env bash
# Deploy campus.silifton.com (apps/web, Next.js) from this Mac to the VPS:
# copy the app, keep the current image as campusweb:rollback, build, restart,
# then check the site answers through the container.
#
#   backend/deploy/deploy-web.sh
#   CAMPUS_VPS=root@host backend/deploy/deploy-web.sh
#
# Roll back: ssh in, `docker tag campusweb:rollback campusweb:latest`,
# `docker compose up -d web`.
set -euo pipefail
HOST="${CAMPUS_VPS:-root@187.77.145.156}"
cd "$(dirname "$0")/../.."   # repo root

rsync -a --delete --exclude node_modules --exclude .next --exclude '.env*' \
  apps/web/ "$HOST:/opt/campussaga/web/"
scp -q backend/deploy/compose.yaml "$HOST:/opt/campussaga/deploy/"

ssh "$HOST" 'set -e
cd /opt/campussaga/deploy
docker tag campusweb:latest campusweb:rollback 2>/dev/null || true
docker compose build web
docker compose up -d web
for i in $(seq 1 30); do
  if curl -fsS -o /dev/null http://127.0.0.1:7031/; then echo deployed; exit 0; fi
  sleep 2
done
echo "web check failed: roll back (see the top of deploy-web.sh)"; exit 1'
