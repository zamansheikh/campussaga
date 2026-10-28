# varsitykotha.com (apps/web)

One Next.js app for the whole domain:

| Path | What |
|---|---|
| `/` | Landing page |
| `/privacy`, `/delete-account` | Public policy pages, English + Bangla (`/privacy.html` and `/delete-account.html` redirect here: the app and the Play Store link to them) |
| `/admin/...` | Superadmin panel (see [docs/ADMIN.md](../../docs/ADMIN.md)) |

Stack: Next.js 16 (App Router, standalone output), React 19, TypeScript,
Tailwind CSS v4, shadcn/ui (Radix), lucide icons, recharts, sonner, zod.
Versions are pinned in `package.json`; use npm.

## How the admin panel talks to the API

The browser only talks to this Next.js server. Pages (Server Components) and
Server Actions call the Go API at `API_URL` with the admin's access token.

- Sign-in: email → 6-digit code (`POST /admin/auth/code`, `/admin/auth/verify`).
  Only admin accounts get a code.
- Tokens live in **httpOnly** cookies on path `/admin` (`Secure` in
  production, `SameSite=Lax`). Browser JavaScript never sees them.
- `src/proxy.ts` runs before every `/admin` request. It sends signed-out
  visitors to `/admin/login`. It also refreshes the access token a minute
  before it expires.
- The API revokes a session when an old refresh token is reused, so
  simultaneous refreshes share one call (`refreshOnce` in
  `src/lib/admin/tokens.ts`). This needs **a single server process**. To run
  several replicas, move that coordination into shared storage first.
- Every admin change goes through a Server Action (`actions.ts` next to each
  page). The Go API checks the admin role on every request and writes the
  audit log.

## Run locally

```sh
# 1. The Go API on :8090 (backend/: make run), with your account set to
#    role 'admin' in the local database. In development the API logs sign-in
#    codes instead of emailing them: grep "DEV ONLY" in its log.
# 2. This app:
cd apps/web
cp .env.example .env.local   # optional; defaults point at the local API
npm install
npm run dev                  # http://localhost:3000, admin at /admin
```

Checks: `npm run lint`, `npm run typecheck`, `npm run build`.

## Environment

| Variable | Default | Notes |
|---|---|---|
| `API_URL` | `http://127.0.0.1:8090/api/v1` | Go API base URL as seen from the Next.js server. In the Docker compose network: `http://api:8090/api/v1` |
| `SITE_URL` | `https://varsitykotha.com` | Used for metadata (Open Graph, sitemap). Static pages read it at build time |
| `PORT` | `7031` in the Docker image | |

No secrets: the app holds no keys; admin sessions come from the Go API.

## Docker

```sh
docker build -t campussaga-web apps/web       # needs internet (npm ci, fonts)
docker run -p 127.0.0.1:7031:7031 -e API_URL=http://api:8090/api/v1 campussaga-web
```

The image runs `node server.js` as the non-root `node` user, listens on
7031 and has a health check on `/robots.txt`.

Behind nginx, pass `Host`, `X-Forwarded-Proto` and `X-Forwarded-For`:
Server Actions compare the `Origin` header with the host, and redirects use
the host.
