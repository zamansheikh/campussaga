# Campus Saga — Running on Our VPS

We self-host Supabase (official Docker Compose setup) on our own VPS.
Same features as Supabase Cloud: Postgres, Auth, REST, Realtime, Storage, Edge Functions, Studio.

**Self-hosting means we own security, backups and uptime.** A leak of who
posted what would destroy student trust, so the checklists here are not
optional.

---

## 1. Server requirements

| | Minimum | Comfortable (prod + staging on one box) |
|---|---|---|
| RAM | 4 GB | 8 GB+ |
| CPU | 2 vCPU | 4 vCPU |
| Disk | 40 GB SSD | 80 GB+ NVMe |
| OS | Ubuntu 24.04 LTS | same |
| Location | Close to students (Singapore / Mumbai, or a Bangladesh provider) for low latency | |

Also needed:
- a domain (e.g. `campussaga.app`), managed in **Cloudflare DNS**
- an email sending service for OTP codes: **Resend, Amazon SES or Brevo**. Mail sent straight from a VPS lands in spam.
- object storage for images and backups: **Cloudflare R2** (free egress) or Backblaze B2

---

## 2. Layout on the server

```
Internet
   │  443 only
   ▼
Cloudflare (DNS, DDoS protection, caching for images)
   │
   ▼
┌──────────────────────── VPS ────────────────────────┐
│  Caddy (TLS, reverse proxy)                         │
│    api.<domain>  ─▶ 127.0.0.1:8000 (Kong)           │
│      allowed: /auth/v1 /rest/v1 /storage/v1         │
│               /realtime/v1 /functions/v1            │
│      everything else (Studio) ─▶ blocked            │
│                                                     │
│  Supabase stack (Docker Compose, /opt/supabase)     │
│    kong · auth · rest · realtime · storage ·        │
│    edge-runtime · imgproxy · meta · studio ·        │
│    supavisor · db (Postgres) · analytics            │
│    → all ports bound to 127.0.0.1 only              │
│                                                     │
│  backup job (cron) ──▶ encrypted dump ──▶ R2/B2     │
└─────────────────────────────────────────────────────┘
        ▲
        │ Tailscale / SSH tunnel (admins only)
     Studio + direct Postgres access
```

**Studio (the admin dashboard) is never public.** Reach it through Tailscale or
`ssh -L 8000:127.0.0.1:8000 vps`, then open `http://localhost:8000`.

---

## 3. Setup steps

### 3.1 Harden the server (day 1, before anything else)

- [ ] Create a non-root user with sudo; SSH **key only**; `PermitRootLogin no`, `PasswordAuthentication no`
- [ ] `ufw`: allow 22 (or Tailscale only), 80, 443; deny everything else
- [ ] Also set the same rules in the **VPS provider's firewall** (see the Docker note below)
- [ ] `fail2ban` for SSH
- [ ] `unattended-upgrades` for security patches
- [ ] Install Tailscale; once it works, close port 22 to the public internet
- [ ] Set timezone to UTC and enable NTP

> ⚠️ **Docker bypasses `ufw`.** A container port published as `8000:8000`
> is open to the whole internet even if `ufw` blocks it. Every port in our
> compose override is bound to `127.0.0.1:` (see 3.3), and the provider
> firewall is the second safety net.

### 3.2 Install Supabase

```bash
# Docker Engine + compose plugin (official Docker apt repo)
git clone --depth 1 https://github.com/supabase/supabase /tmp/supabase
sudo mkdir -p /opt/supabase && sudo cp -r /tmp/supabase/docker/* /opt/supabase/
cd /opt/supabase && cp .env.example .env
```

### 3.3 Configure `.env` and the compose override

Replace **every** default secret. Follow the official self-hosting guide to
generate the JWT secret and the `ANON_KEY` / `SERVICE_ROLE_KEY` signed with it.

| Setting | Value |
|---|---|
| `POSTGRES_PASSWORD` | long random (`openssl rand -base64 48`) |
| `JWT_SECRET` + `ANON_KEY` + `SERVICE_ROLE_KEY` | new, generated together |
| `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` | not the defaults |
| `SECRET_KEY_BASE`, `VAULT_ENC_KEY`, `LOGFLARE_*` tokens | new random values |
| `SITE_URL`, `API_EXTERNAL_URL`, `SUPABASE_PUBLIC_URL` | `https://api.<domain>` |
| `SMTP_*` | Resend/SES/Brevo credentials, sender `no-reply@<domain>` |
| `ENABLE_EMAIL_AUTOCONFIRM` | `false` |
| `DISABLE_SIGNUP` | `false` (sign-up is limited to university domains in our own hook / RPC) |
| Storage backend | S3-compatible → Cloudflare R2 bucket, so images don't fill the VPS disk |

`docker-compose.override.yml`: bind published ports to localhost only:

```yaml
services:
  kong:
    ports: !override
      - "127.0.0.1:8000:8000"
  supavisor:
    ports: !override
      - "127.0.0.1:5432:5432"
      - "127.0.0.1:6543:6543"
```

**Where the secrets live:** only in `/opt/supabase/.env` on the server
(`chmod 600`, owned by root), plus one copy in a password manager.
Never in git, never in the Flutter app. The app only gets the **anon key**,
which is public by design. Access is protected by RLS.

### 3.4 Caddy (HTTPS + only public API paths)

```caddy
api.{$DOMAIN} {
    @api path /auth/v1/* /rest/v1/* /storage/v1/* /realtime/v1/* /functions/v1/*
    handle @api {
        reverse_proxy 127.0.0.1:8000
    }
    handle {
        respond 404
    }
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options nosniff
        Referrer-Policy no-referrer
    }
}
```

With Cloudflare in front, use **Full (strict)** SSL mode and, ideally, let only
Cloudflare IP ranges reach port 443.

### 3.5 Email deliverability

- [ ] SPF, DKIM and DMARC records for `<domain>` (the email provider shows them)
- [ ] Send a test OTP to Gmail, Outlook and a university address; check it isn't in spam
- [ ] Customize the OTP email templates (Bangla + English)

### 3.6 Apply our database

From the Mac, through Tailscale or an SSH tunnel to `127.0.0.1:5432`:

```bash
supabase db push --db-url "postgresql://postgres:<password>@localhost:5432/postgres"
supabase functions deploy ...   # or copy to /opt/supabase/volumes/functions and restart edge-runtime
```

The same migrations run locally, in CI, on staging, then on production. Never
change the production schema by hand in Studio.

---

## 4. Backups (the most important section)

| What | How | Keep |
|---|---|---|
| Database | Nightly `pg_dump -Fc` + roles (`pg_dumpall --roles-only`) from the `db` container, encrypted with `age`, uploaded with `rclone` | 7 daily, 4 weekly, 6 monthly |
| Images | Already on R2 (enable bucket versioning) | — |
| Config | `.env` + override + Caddyfile, encrypted, uploaded | latest 10 |
| Point-in-time recovery | Later: WAL-G streaming WAL to R2/B2 | 7 days |

Rules:
- Backups go to a **different provider/account** than the VPS. If the VPS account is lost, backups survive.
- The backup encryption key is in the password manager, not only on the server.
- **Monthly restore test**: restore last night's dump into local Docker, run the pgTAP tests, check row counts. An untested backup is not a backup.
- Before every Supabase upgrade or risky migration: take a manual backup.

---

## 5. Updates

- OS security patches: automatic (`unattended-upgrades`); reboot monthly.
- Supabase: pin image versions in compose. Once a month, pull the new compose file, try it on staging, read the changelog, then upgrade production at a low-traffic time (late night BD time).
- Postgres major versions: only with a tested backup and a restore rehearsal.

---

## 6. Monitoring and alerts

- [ ] **Uptime Kuma** (ideally on a different machine, or a free external checker) → checks `https://api.<domain>/auth/v1/health` every minute → Telegram alert
- [ ] Disk usage alert at 80% (Postgres stops when the disk is full)
- [ ] RAM/CPU: Netdata or `docker stats`; add swap (2–4 GB) as a safety net
- [ ] Backup job sends a "backup OK" ping (e.g. healthchecks.io); alert if it misses a night
- [ ] App errors: Sentry/Crashlytics on the Flutter side

---

## 7. Security checklist before launch

- [ ] All default secrets replaced; `.env` is `chmod 600`
- [ ] `nmap` the server from outside: only 80/443 open (22 closed if Tailscale)
- [ ] Studio and Postgres not reachable from the internet
- [ ] `https://api.<domain>/` returns 404; only API paths work
- [ ] pgTAP tests pass on production: no role can read `private.*`
- [ ] Logged in as a normal student in the app: cannot read another user's email, votes, or anonymous authorship
- [ ] Rate limits work (spam 50 posts → blocked)
- [ ] Backup restored successfully at least once
- [ ] Service role key exists only on the server and in the password manager

---

## 8. If the server dies (runbook)

1. Create a new VPS (or a Supabase Cloud project if speed matters most).
2. Run sections 3.1–3.4 (keep this doc up to date so it takes < 1 hour).
3. Restore the latest encrypted dump; restore `.env` with the **same JWT secret**, so existing app logins and keys keep working.
4. Point `api.<domain>` DNS to the new server (Cloudflare: change is instant).
5. Check health, run the pgTAP tests, post a status update to students.

Target: back online within 2 hours, losing at most 24 hours of data
(at most minutes once WAL-G is added).
