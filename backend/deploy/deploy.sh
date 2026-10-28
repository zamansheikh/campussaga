#!/usr/bin/env bash
# Deploy the API from this Mac to the VPS (docs/DEPLOYMENT.md section 3.6):
# copy the backend, back up the database, keep the current image as
# campusapi:rollback, build, migrate, restart, then check health.
#
#   backend/deploy/deploy.sh            # default host below
#   CAMPUS_VPS=root@host backend/deploy/deploy.sh
#
# Roll back: ssh in, `docker tag campusapi:rollback campusapi:latest`,
# `docker compose up -d api` (and restore the backup if a migration ran).
set -euo pipefail
HOST="${CAMPUS_VPS:-root@187.77.145.156}"
cd "$(dirname "$0")/.."   # backend/

rsync -a --delete --exclude .git --exclude bin --exclude '*.test' \
  --exclude coverage.out --exclude .env ./ "$HOST:/opt/campussaga/backend/"
scp -q deploy/compose.yaml deploy/backup.sh "$HOST:/opt/campussaga/deploy/"

ssh "$HOST" 'set -e
cd /opt/campussaga/deploy
sh backup.sh
docker tag campusapi:latest campusapi:rollback 2>/dev/null || true
docker compose build api nsfw
docker compose run --rm api migrate
docker compose up -d nsfw api
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:7030/api/v1/health; then echo; echo deployed; exit 0; fi
  sleep 2
done
echo "health check failed: roll back (see the top of deploy.sh)"; exit 1'
