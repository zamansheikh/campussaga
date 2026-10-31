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

## Build 6 features in the admin panel

What the admin panel needs for Campus social, blood donation, campus visits
and live buses. All routes are admin-only like the rest of `/admin/*`, and
every change writes an audit row.

### Dashboard (`GET /admin/stats`, new keys)

```json
{
  "campus": {"postsLast7Days": {"issue": 0, "post": 0, "question": 0, "poll": 0},
             "commentsLast7Days": 0, "reactionsLast7Days": 0},
  "blood": {"donors": 0, "available": 0, "openRequests": 0,
            "requestsLast7Days": 0, "responsesLast7Days": 0},
  "bus": {"liveNow": 0, "sharesLast7Days": 0, "tripsShared": 0, "ratingsLast30Days": 0}
}
```

- `campus.postsLast7Days`: items created in the last 7 days, by kind.
- `blood.donors`: donor profiles; `available` of them can donate now.
- `bus.liveNow`: open sharing sessions with a point in the last 2 minutes.
  `sharesLast7Days` counts sessions started. `tripsShared` is the sum of
  `bus_share_stats.trips`, which survives the 24-hour purge.

Existing keys are unchanged; the dashboard shows the new ones as three new
sections.

### Blood requests

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/blood/requests` | Paged. `?status=open\|fulfilled\|closed\|all` (default `open`), `?universityId=`, `?q=` (hospital, area, contact name or phone, requester email). Newest first. |
| POST | `/admin/blood/requests/{id}/close` | `{reason?: string ≤ 300}` closes an open request (status `closed`, `closed_at` now) → the item. `409 BLOOD_REQUEST_NOT_OPEN` if it isn't open. Audit `blood.close` with `{reason}`. |

Item:
```json
{"id": "uuid", "university": {"id": "uuid", "name": "…"},
 "bloodGroup": "A+", "units": 2, "hospital": "…", "area": "…",
 "neededBy": "RFC3339", "urgent": true,
 "contactName": "…", "contactPhone": "…", "note": "…",
 "status": "open|fulfilled|closed", "notified": 12, "responses": 1,
 "requester": {"id": "uuid", "name": "…", "email": "…"} | null,
 "createdAt": "RFC3339", "closedAt": "RFC3339" | null}
```

### Live buses on a route

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/transport/routes/{id}/activity` | `{live: {runs: [Run]}, insights: {trips: [TripInsight]}, sharesLast7Days, ratingsLast30Days}`. `Run` and `TripInsight` have the same shape as `/transport/routes/{id}/live` and `/insights` (docs/BUS_LIVE.md); there is no `mine`, and no user ids. |
| POST | `/admin/transport/routes/{id}/live/end` | Ends every open sharing session on the route (a fake or stuck bus) → `{ended: n}`. The sharers' next ping answers `{ended: true, reason: "admin"}`, which the app treats as stopped. Audit `transport.live.end` with `{ended}`. Needs migration `00700_bus_live_admin_end.sql` to add `admin` to the `end_reason` check. |

### Moderation
The moderation issue view adds `campusOnly` (boolean). The page shows
"Campus only" next to the kind when it's true.

### Admin panel pages
- **Dashboard:** three new sections, Campus, Blood donation and Live buses,
  with the numbers above.
- **Blood donation** (`/admin/blood`, new item in the side nav):
  - Status tabs (Open, Fulfilled, Closed, All), a university filter and a search box.
  - A table with: group (red badge), units, hospital and area, needed by,
    urgent, university, requester (links to the user), contact, notified,
    responses, created.
  - Close request asks for a confirmation and an optional reason.
- **Bus route** (`/admin/transport/[id]`):
  - **Live now:** each run's direction and departure, riders, next stop,
    how late, and when it was last updated, with an "End all sharing"
    button that asks first.
  - **What riders say:** per trip, votes, on time, late, didn't come,
    crowded, measured delay and measured runs.
- **Settings:** names and hints for the new switches:
  - `bloodDonation`: Blood donation. "Donor sign-up, blood requests and
    'blood needed' notifications. Off hides it in the app."
  - `visitCampus`: Visit other campuses. "Students read and react to
    other universities' Campus posts. Off hides it in the app."
  - `busLive`: Live buses. "Students share the bus they're on; live map,
    arrival times, 'bus near' alerts and trip ratings. Off hides it in
    the app."
- **Audit log:** readable labels for `blood.close` and `transport.live.end`.
