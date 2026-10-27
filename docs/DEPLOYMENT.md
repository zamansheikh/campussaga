# Campus Saga — Running on Our VPS

Campus Saga runs as two Docker containers on our own VPS: the Go API
(`campusapi`) and its PostgreSQL 18 database. nginx on the host handles HTTPS.

**Self-hosting means we own security, backups and uptime.** A leak of who
posted what would destroy student trust, so the checklists here are not
optional.

---

## 1. The server

We use our existing shared VPS (Ubuntu 24.04). It already runs other
products, so Campus Saga must fit its conventions and **never interrupt
other services**:

| Convention on the box | What it means for us |
|---|---|
| nginx on the host fronts every site | We add one vhost for `api.<domain>`; no own reverse proxy container |
| Containers bind to `127.0.0.1` only | Our API listens on `127.0.0.1:7030` (**check the port is free first**: `ss -ltnp \| grep 7030`) |
| Apps live under `/opt/<name>` | Everything in `/opt/campussaga` |
| vhosts: `/etc/nginx/sites-available/fx-<domain>.conf`, symlinked into `sites-enabled` | Same for ours |
| Certificates via `certbot --webroot -w /var/www/html` | Same for ours |
| `ufw` allows 22, 80, 443 only | Postgres and the API are never exposed publicly |

**Footprint:** the Go API uses about 50–100 MB of RAM, Postgres a few hundred
MB. That matters on a shared box.

Also needed:
- a domain with DNS in **Cloudflare**, and an `api.<domain>` record pointing to the VPS
- **Resend** for sign-in code emails (SMTP). The sender domain must be verified in Resend; mail sent straight from a VPS lands in spam
- object storage for images (R1+) and backups: **Cloudflare R2** (free egress) or Backblaze B2

---

## 2. Layout

```
Internet
   │  443
   ▼
Cloudflare (DNS, optional proxy / DDoS protection)
   │
   ▼
┌──────────────────────── VPS ────────────────────────┐
│  nginx (TLS)   api.<domain> ─▶ 127.0.0.1:7030       │
│                                                     │
│  /opt/campussaga/deploy  (docker compose project    │
│                           "campussaga")             │
│    api       campusapi serve   127.0.0.1:7030       │
│    postgres  postgres:18       internal network only│
│                                                     │
│  backup job (cron) ──▶ encrypted dump ──▶ R2 / B2   │
└─────────────────────────────────────────────────────┘
```

```
/opt/campussaga/
├─ backend/              # copy of the repo's backend/ (rsync)
└─ deploy/
   ├─ compose.yaml       # api + postgres
   ├─ .env               # secrets, chmod 600, never in git
   └─ backups/           # local copy of the latest dumps
```

---

## 3. Setup steps

### 3.1 First-time setup

- [ ] Confirm `127.0.0.1:7030` is free and pick another port if not
- [ ] `mkdir -p /opt/campussaga/deploy && chmod 700 /opt/campussaga/deploy`
- [ ] Copy the backend: `rsync -a --delete --exclude .git backend/ <vps>:/opt/campussaga/backend/`
- [ ] Create `deploy/.env` (section 3.2) and `deploy/compose.yaml` (section 3.3)

### 3.2 Secrets: `/opt/campussaga/deploy/.env`

Template: [backend/deploy/env.example](../backend/deploy/env.example).

`chmod 600`, owned by root. One copy in the password manager. Never in git.

| Variable | Value |
|---|---|
| `APP_ENV` | `production` |
| `POSTGRES_PASSWORD` | long random (`openssl rand -base64 36`) |
| `DATABASE_URL` | `postgres://campus:<POSTGRES_PASSWORD>@postgres:5432/campus?sslmode=disable` |
| `JWT_SECRET` | 64 random bytes (`openssl rand -base64 64`); signs access tokens |
| `CODE_HMAC_SECRET` | 64 random bytes; hashes sign-in codes |
| `FIREBASE_PROJECT_ID` | `bitlaabuzz` (enables Google sign-in; not a secret) |
| `SMTP_HOST` / `SMTP_PORT` | `smtp.resend.com` / `587` |
| `SMTP_USERNAME` | `resend` |
| `SMTP_PASSWORD` | the Resend API key |
| `MAIL_FROM` | e.g. `Campus Saga <no-reply@<domain>>` (domain verified in Resend) |

Changing `JWT_SECRET` signs everyone out. Changing `CODE_HMAC_SECRET` only
invalidates codes that are waiting to be used.

### 3.3 `compose.yaml`

In the repo: [backend/deploy/compose.yaml](../backend/deploy/compose.yaml). Copy it to `/opt/campussaga/deploy/`.

```yaml
name: campussaga
services:
  postgres:
    image: postgres:18-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: campus
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: campus
    volumes: [pgdata:/var/lib/postgresql]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U campus"]
      interval: 5s
      retries: 20
    # no ports: reachable only from the api container

  api:
    build: ../backend
    image: campusapi:latest
    restart: unless-stopped
    env_file: .env
    depends_on:
      postgres: {condition: service_healthy}
    ports: ["127.0.0.1:7030:8090"]

volumes:
  pgdata:
```

### 3.4 nginx + HTTPS

`/etc/nginx/sites-available/fx-api.<domain>.conf`, symlinked into
`sites-enabled` (template: [backend/deploy/nginx.conf.example](../backend/deploy/nginx.conf.example)):

```nginx
server {
    listen 80;
    server_name api.<domain>;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://$host$request_uri; }
}

server {
    listen 443 ssl;
    http2 on;
    server_name api.<domain>;

    ssl_certificate     /etc/letsencrypt/live/api.<domain>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.<domain>/privkey.pem;

    client_max_body_size 10m;

    location / {
        proxy_pass http://127.0.0.1:7030;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
certbot certonly --webroot -w /var/www/html -d api.<domain>
nginx -t && systemctl reload nginx
```

Run `nginx -t` before every reload: a broken config would take down every
site on the box.

### 3.5 Email deliverability

- [ ] Sender domain verified in Resend (SPF/DKIM records added in Cloudflare)
- [ ] Send a test code to Gmail, Outlook and a university address; check it isn't in spam
- [ ] The code email is bilingual (Bangla + English) and says never to share the code

### 3.6 Deploy (first time and every update)

```bash
# from the Mac
rsync -a --delete --exclude .git backend/ <vps>:/opt/campussaga/backend/

# on the VPS
cd /opt/campussaga/deploy
docker compose build api
docker compose run --rm api migrate        # apply new migrations first
docker compose up -d api                   # start the new version
curl -fsS http://127.0.0.1:7030/api/v1/health
```

- Take a manual backup (section 4) before any release with a migration.
- Tag the previous image before building (`docker tag campusapi:latest campusapi:rollback`) so a rollback is one `docker compose up -d` away.
- Never change the production schema by hand. Every change is a migration in git.

---

## 4. Backups (the most important section)

| What | How | Keep |
|---|---|---|
| Database | Nightly `pg_dump -Fc` from the `postgres` container, encrypted with `age`, uploaded with `rclone` | 7 daily, 4 weekly, 6 monthly |
| Images (R1+) | Already on R2 (enable bucket versioning) | — |
| Config | `deploy/.env` + `compose.yaml` + nginx vhost, encrypted, uploaded | latest 10 |
| Point-in-time recovery | Later: WAL archiving (e.g. WAL-G) to R2/B2 | 7 days |

```bash
docker compose exec -T postgres pg_dump -U campus -Fc campus \
  | age -r <public-key> > backups/campus-$(date +%F).dump.age
rclone copy backups/ r2:campussaga-backups/
```

Rules:
- Backups go to a **different provider/account** than the VPS. If the VPS is lost, backups survive.
- The `age` private key is in the password manager, not on the server.
- **Monthly restore test**: restore last night's dump into a local Postgres, run `campusapi migrate` and the e2e tests against it, check row counts. An untested backup is not a backup.
- Before every release with a migration: take a manual backup.

---

## 5. Updates

- OS security patches are handled for the whole box; coordinate reboots with the other services on it.
- Postgres minor updates: pull the new `postgres:18-alpine` image and restart, after a backup.
- Postgres major versions: only with a tested backup and a restore rehearsal.
- Go and dependency updates go through the normal release flow (CI, staging, then production).

---

## 6. Monitoring and alerts

- [ ] Uptime check (Uptime Kuma or similar, ideally off the VPS) on `https://api.<domain>/api/v1/health` every minute → Telegram alert
- [ ] Disk usage alert at 80% (Postgres stops when the disk is full)
- [ ] Logs: `docker compose logs -f api` (JSON lines with `traceId`; the app shows the trace id in error reports)
- [ ] Backup job sends a "backup OK" ping (e.g. healthchecks.io); alert if it misses a night
- [ ] App errors: Sentry/Crashlytics on the Flutter side

---

## 7. Security checklist before launch

- [ ] `.env` is `chmod 600`; all secrets random and unique to this app
- [ ] From outside: only 22/80/443 open; port 7030 and Postgres not reachable
- [ ] `docker compose ps`: Postgres publishes no port; the API publishes only on `127.0.0.1`
- [ ] HTTPS works and HTTP redirects to HTTPS
- [ ] `go test -race ./...` green on the release commit, including the security e2e tests (no student can read another student's data or an anonymous author)
- [ ] Rate limits work: requesting codes repeatedly returns 429
- [ ] A non-university email gets 403 `UNIVERSITY_EMAIL_REQUIRED`
- [ ] Backup restored successfully at least once
- [ ] No secret in git: `git grep -i -e secret -e password` shows only placeholders

---

## 8. If the server dies (runbook)

1. Create a new VPS (Ubuntu 24.04, Docker, nginx, certbot).
2. Restore `/opt/campussaga/deploy` (`.env`, `compose.yaml`) and the nginx vhost from the encrypted config backup. Keep the **same `JWT_SECRET`** so existing app logins keep working.
3. Copy the backend, `docker compose up -d postgres`, restore the latest dump with `pg_restore`, then `docker compose up -d api`.
4. Issue the certificate, point the `api.<domain>` DNS record to the new server (Cloudflare: change is instant).
5. Check `/api/v1/health`, sign in from the app, post a status update to students.

Target: back online within 2 hours, losing at most 24 hours of data
(at most minutes once WAL archiving is added).
