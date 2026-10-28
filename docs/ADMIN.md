# VarsityKotha — admin panel and web (varsitykotha.com)

One Next.js app (`apps/web`) serves the whole domain:

| Path | What |
|---|---|
| `/` | Landing page (EN/BN) |
| `/privacy`, `/delete-account` | Public policy pages (linked from the app and Play Store) |
| `/admin/...` | Superadmin panel (sign-in required, role `admin`) |

nginx on the Tecsior VPS: `varsitykotha.com` → the web container
(127.0.0.1:7031); `/api/` on the same host → the Go API (127.0.0.1:7030),
so the browser never needs CORS. `www.varsitykotha.com` and the old
`campus.silifton.com` redirect to `https://varsitykotha.com` (path kept).
vhosts: [backend/deploy/nginx/](../backend/deploy/nginx/).

## Admin sign-in

- An admin is a user with `role = 'admin'` (set by hand in SQL for the first
  one; afterwards from the panel).
- Sign-in is an emailed 6-digit code, allowed for **admin accounts only**,
  whatever the email domain (Gmail included).
- The Next.js server calls the Go API; the access and refresh tokens live in
  **httpOnly, Secure, SameSite=Lax cookies** on varsitykotha.com. Browser
  JavaScript never sees them. Next.js refreshes the access token with
  `POST /auth/refresh` when it expires.
- Every admin request is checked against the database (role and session),
  so demoting or blocking an admin works at once.

## API (Go, prefix `/api/v1`)

Responses use the usual envelope: `{"success": true, "data": …}` or
`{"success": false, "error": {"code", "message", "details"}}`.
All `/admin/*` routes except the two auth ones need
`Authorization: Bearer <access token>` of an admin; others get
`403 NOT_ADMIN`. Lists are paged: `?page=1&pageSize=25` (max 100) and answer
`{"items": [...], "total": n, "page": 1, "pageSize": 25}`.

### Auth

| Method | Path | Body | Answer |
|---|---|---|---|
| POST | `/admin/auth/code` | `{email}` | `202 {expiresInSeconds, resendAfterSeconds}`. Always 202 for a well-formed email: the code is only sent when the email is an admin's |
| POST | `/admin/auth/verify` | `{email, code}` | `200 {tokens, user}` (same shapes as `/auth/verify`); `403 NOT_ADMIN` when the account isn't an admin |
| POST | `/auth/refresh` | `{refreshToken}` | existing |
| POST | `/auth/logout` | – | existing |

### Dashboard

`GET /admin/stats`

```json
{
  "users": {"total": 0, "verified": 0, "notVerified": 0, "admins": 0, "blocked": 0, "newLast7Days": 0},
  "groups": {"total": 0, "memberships": 0, "slots": 0, "announcements": 0},
  "devices": {"android": 0, "ios": 0},
  "universities": {"active": 0, "total": 0},
  "signupsByDay": [{"date": "2026-10-28", "count": 0}],
  "topUniversities": [{"id": "uuid", "name": "…", "users": 0}]
}
```

`signupsByDay` covers the last 30 days (Asia/Dhaka dates, oldest first,
zero days included). `topUniversities` is the top 10 by users.

### Users

`AdminUser`:

```json
{
  "id": "uuid", "email": "a@b.c", "displayName": "…|null",
  "department": "…|null", "batch": "…|null",
  "role": "student|admin", "verified": true, "verifiedAt": "time|null",
  "universityEmail": "…|null",
  "university": {"id": "uuid", "slug": "diu", "name": "…"} ,
  "blockedAt": "time|null", "createdAt": "time", "lastActiveAt": "time|null",
  "groups": 0
}
```

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/users` | `?q=` (email or name), `?universityId=`, `?status=verified|notVerified|blocked|admin`; newest first |
| GET | `/admin/users/{id}` | `AdminUser` plus `"memberships": [{"groupId", "title", "role": "cr|member"}]`, `"devices": [{"platform", "createdAt"}]`, `"activeSessions": 0` |
| PATCH | `/admin/users/{id}` | any of `{role, universityId, verified, blocked, displayName}` → `AdminUser`. `verified: true` = verified by hand (needs a university). `blocked: true` ends all their sessions and stops sign-in (`ACCOUNT_BLOCKED`). An admin can't block, demote or delete themselves (`CANNOT_CHANGE_SELF`) |
| DELETE | `/admin/users/{id}` | deletes the account like "Delete account" in the app (CR role passes on) → 204 |

### Universities

`AdminUniversity`: `{id, slug, name, nameBn, city, kind: "public|private|null", website, active, domains: [], users, groups}`

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/universities` | `?q=`, `?active=true|false`; by name; not paged (≈200) |
| POST | `/admin/universities` | `{slug, name, nameBn?, city?, kind?, website?, domains: []}` → `AdminUniversity` (201). `SLUG_TAKEN`, `DOMAIN_TAKEN`, `DOMAIN_NOT_ALLOWED` (free-mail or shared suffix) |
| PATCH | `/admin/universities/{id}` | any of `{name, nameBn, city, kind, website, active}` |
| PUT | `/admin/universities/{id}/domains` | `{domains: []}` replaces the list |

### Class groups

`AdminGroup`: `{id, title, department, batch, section, semester, joinCode, university: {id, slug, name}, members, crs: [{id, name, email}], slots, createdAt}`

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/groups` | `?q=` (department, batch, join code), `?universityId=`; newest first |
| GET | `/admin/groups/{id}` | `AdminGroup` plus `"memberList": [{"userId", "name", "email", "role", "verified", "joinedAt"}]` |
| PUT | `/admin/groups/{id}/members/{userId}` | `{role: "cr|member"}` (a group always keeps one CR: `LAST_CR`) |
| DELETE | `/admin/groups/{id}/members/{userId}` | remove a member (the last CR's role passes on) |
| DELETE | `/admin/groups/{id}` | delete the group and its routine |

### App settings

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/config` | `{"items": [{"key": "minSupportedBuild", "value": <json>, "updatedAt"}]}` |
| PUT | `/admin/config/{key}` | `{value: <json>}`; key is camelCase. `features` must be an object of booleans, `minSupportedBuild` an integer ≥ 1 |

### Push

`POST /admin/push`

```json
{"target": "user|all", "userId": "uuid (target=user)",
 "title": "…", "body": "…", "titleBn": "…?", "bodyBn": "…?"}
```

→ `{"users": n, "devices": n}` (queued; delivery is logged). `all` sends to
every user with a device. Bangla text falls back to English.

### Audit log

`GET /admin/audit` → paged `{id, actor: {id, email, name}, action, targetType, targetId, meta, createdAt}`, newest first.
Every admin change writes one row (`user.update`, `user.delete`,
`university.create`, `university.update`, `university.domains`,
`group.member.role`, `group.member.remove`, `group.delete`, `config.update`,
`push.send`, `admin.sign_in`).
