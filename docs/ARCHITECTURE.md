# VarsityKotha — Architecture

> The product was renamed from "Campus Saga" to VarsityKotha (ভার্সিটি কথা) on
> 2026-10-28. The repo, Go module, app ID, domain, Firebase project, server
> directory (`/opt/varsitykotha`), cron file, compose project, containers,
> images and volumes use the new name. Still the old name: the Dart package
> `campussaga`, the `campus_*` packages, the `campusapi` binary and the
> database (`campus`).

Goal: ship each release properly with a small team, without painting
ourselves into a corner. Every choice below can be replaced later without
rewriting the app.

---

## 1. Database and backend decision

**Decision: PostgreSQL + our own Go API, running on our own VPS.**
(Setup and hardening: [DEPLOYMENT.md](DEPLOYMENT.md).)

| Database | Verdict | Why |
|---|---|---|
| **PostgreSQL** | ✅ Chosen | Relational data (users → universities → issues → votes → comments), SQL for rankings and scorecards, open source, runs anywhere |
| Firebase Firestore | ❌ | NoSQL makes counts, rankings and "issues solved per university per month" painful and costly; full vendor lock-in |
| MongoDB | ❌ | No real benefit for this data; weaker for joins and reporting |
| MySQL | ⚠️ Possible | Fine, but weaker JSON and no pgvector/PostGIS ecosystem |

| Backend | Verdict | Why |
|---|---|---|
| **Own Go API** | ✅ Chosen | The team already builds Go backends (same conventions as `gamebackend`); the logic is normal, testable Go code; one small binary (~50–100 MB RAM), light on our shared VPS |
| Supabase (self-hosted) | Considered | Fast start, but logic lives in SQL policies and functions, and the stack needs ~4 GB RAM |
| NestJS | Considered | Fine, but heavier at runtime, and Go is the team's current backend stack |

**Why this is future-proof**

- Postgres is the industry standard. Any host (our VPS, AWS RDS, Neon, a dedicated server) runs it.
- Every schema change is a **numbered SQL migration file in git**, applied by the API binary (`campusapi migrate`).
- The app never talks to the backend from screens. It goes through a **repository layer** (section 4), so the backend can change without rewriting the app.
- The API is a plain HTTP + JSON contract with stable error codes. A web dashboard or another client can use the same endpoints.
- Postgres grows with us:
  - `pg_trgm` → "similar issues" duplicate check and search (works with Bangla text)
  - `pgvector` → smarter duplicate detection and recommendations later
  - `PostGIS` → campus map / issue location later

---

## 2. System overview

```
┌────────────────────┐   ┌──────────────────────┐
│  Flutter mobile    │   │ Authority web (R4)   │
│  (Android, iOS)    │   │ Flutter Web          │
└─────────┬──────────┘   └──────────┬───────────┘
          │  HTTPS + JWT (Bearer)   │
          ▼                         ▼
┌─────────────────────────────────────────────────┐
│  nginx on the VPS (TLS, api.<domain>)           │
└───────────────┬─────────────────────────────────┘
                ▼  127.0.0.1
┌─────────────────────────────────────────────────┐
│  campusapi (Go)               /api/v1           │
│                                                 │
│  platform: config · db · httpx · apperr ·       │
│            auth (JWT, sessions) · ratelimit ·   │
│            mail (SMTP)                          │
│  modules:  universities · accounts · appconfig  │
│            classgroups (R1+: changes, issues…)  │
│  workers:  goroutines for push, moderation,     │
│            nightly scorecards                   │
└───────────────┬─────────────────────────────────┘
                ▼
          PostgreSQL 18
                │
      FCM (push) · Cloudflare R2 (images, S3 API) · SMTP (Resend)
```

### Rules for talking to the backend

1. **Every request goes through the Go API.** The database is never reachable from the internet; only the API connects to it.
2. **Handlers return response DTOs, never database rows.** A field that isn't in a response struct can't leak, even if a query selects it.
3. **Commands in, DTOs out.** Writes are explicit endpoints (`POST /issues`, `POST /issues/{id}/vote`, …). Validation, rate limits and permission checks happen in the handler/service, not in the app.
4. **No endpoint takes another user's id** for private data. "Me" endpoints (`/me`, `/me/issues`) read the user from the token.
5. **Side effects** (send push, clean image, call moderation API) run in the Go process after the database transaction commits, never from the app.

### API conventions

- Prefix `/api/v1`. JSON in and out.
- Response envelope (same shape as `gamebackend`):

  ```json
  {"success": true,  "data": {...}, "error": null, "meta": {"timestamp": "..."}}
  {"success": false, "data": null,  "error": {"code": "CODE_INVALID", "message": "...", "details": {"remainingAttempts": 4}}, "meta": {...}}
  ```

- Error `code` values are the **wire contract**: the app maps them to `campus_core` `Failure` types (`NetworkFailure`, `RateLimitedFailure`, `ValidationFailure` …). Never rename a shipped code.
- Every response carries an `X-Trace-Id` header for support and logs.

### R0 endpoints

| Method + path | Access | What |
|---|---|---|
| `GET /health` | public | Liveness + database check |
| `GET /universities` | public | Active universities with their email domains (the app checks an email before sending a code) |
| `GET /config` | public | `minSupportedBuild`, `features` (feature flags) |
| `POST /auth/code` `{email}` | public | 202 and sends a 6-digit code. 403 `UNIVERSITY_EMAIL_REQUIRED` for non-university email; 429 when resent within 60 s or more than 5 per hour |
| `POST /auth/google` `{idToken, name?}` | public | Google sign-in: a Firebase ID token from the app. A university Google account is verified at once; any other account (Gmail) signs in **not verified** and picks its university. `name` is the Google account name the phone saw; it fills an empty profile name when the token has none (some accounts share neither) |
| `POST /auth/verify` `{email, code}` | public | Access + refresh tokens and the profile. Codes expire in 10 minutes, max 5 wrong attempts |
| `POST /auth/refresh` | public (refresh token) | New token pair; the old refresh token stops working |
| `POST /auth/logout` | student | Ends this session |
| `POST /auth/logout-all` | student | Ends every session (all devices) |
| `GET /me` | student | Own profile + university |
| `PATCH /me` | student | `displayName`, `department`, `batch` only (empty string clears); unknown fields such as `role` are rejected with 400 |
| `GET /me/department-suggestions?q=` | student | Departments other students at the same university entered (most used first, case-insensitive); names only |
| `DELETE /me` | student | Deletes the account and everything it owns |

### R1 endpoints: class groups (`classgroups` module)

| Endpoint | Who | What |
|---|---|---|
| `GET /groups` | student | My groups, each with its full routine (`slots`) |
| `POST /groups` `{department, batch, section, semester}` | student | Create; the caller becomes CR. 10 per day per student |
| `GET /groups/preview?code=` | student | What a code leads to (title, counts) before joining |
| `POST /groups/join` `{code}` | student | Join; joining again is harmless |
| `PUT /groups/{id}` · `DELETE /groups/{id}` | CR | Edit details · delete for everyone |
| `POST /groups/{id}/leave` | member | Leave; the last member deletes the group; the only CR can't leave while others remain (`CR_CANNOT_LEAVE`) |
| `POST /groups/{id}/slots` · `PUT`/`DELETE /groups/{id}/slots/{slot}` | CR | Add · edit · remove a weekly class (`start`/`end` as `"HH:MM"`) |
| `POST /groups/{id}/changes` `{kind, slotId?, date, start?, end?, room?, courseCode?…, note?}` | CR | One date only: `cancelled` / `moved` (new time, room `""` = unchanged) a weekly class, or an `extra` class. Dates today…+180 days (Bangladesh time), must match the class's weekday. A new change for a class on a date replaces the old one. Max 200 pending |
| `DELETE /groups/{id}/changes/{change}` | CR | Undo a change |

| `POST /groups/{id}/announcements` `{body, pinned}` | CR | Post a message (≤1000 chars, line breaks kept); pinning unpins the previous one. 30 a day per CR |
| `PATCH /groups/{id}/announcements/{a}` `{pinned}` · `DELETE …` | CR | Pin / unpin · delete for everyone |

**Step 5** (migration 00440): `PUT /groups/{id}/hidden {courses}` hides courses a member doesn't take (retake students; only their routine and reminders change); `POST /groups/{id}/new-semester {semester}` clears the weekly routine and its changes (CR; members, code and announcements stay; members are notified); `GET /groups/{id}/members`, `PUT|DELETE /groups/{id}/members/{user}` let CRs see names (never emails), make up to 3 CRs, step down (never the last) and remove members; a trigger makes the longest member CR if the last CR disappears (account deleted). Personal classes: `GET|POST /me/classes`, `PUT|DELETE /me/classes/{id}` (max 50, owner only); the app shows them in Today, Routine and reminders as a private "Personal" group.

**Pushes** (`push` module, migration 00430): the app registers its FCM token with `POST /me/devices {token, platform, language}`; the token belongs to that sign-in session, so signing out or a revoked session stops pushes. After a CR posts an announcement or adds/undoes a change, every other member's phone gets a notification in its language (EN/BN, Bengali digits), sent in the background after commit; tokens Firebase reports as gone are deleted. Without `FCM_CREDENTIALS_FILE` the server only logs them. iPhones also need the APNs key (docs/DEPLOYMENT.md).

`GET /groups` includes each group's `changes` from yesterday on, and its `announcements`: the pinned one plus the newest 20 of the last 30 days. The app keeps "seen" times per group on the phone for the "New" badge. Editing a weekly class to another weekday, or deleting it, removes its changes.

Codes are looked up 30 times per hour per student and 120 per IP (24⁶ ≈ 191 million codes). A code of another university, or a group you're not in, answers `GROUP_NOT_FOUND`; a member editing answers `NOT_GROUP_CR`. Limits: 10 groups per student, 300 members per group, 100 classes per routine. The app keeps the last `GET /groups` on the phone (per account) so Today and Routine work offline.

### Verified and not-verified students (migration 00460)

Some universities give students no email. Signing in with **any Google
account** that isn't a university address creates a **not verified**
student: no university yet (`PUT /me/university` picks one from the list;
only while not verified), shown as "Not verified" on their profile and in
the CR's member list. They can verify later: `POST /me/verify/code {email}`
sends a code to a university email (same limits as sign-in codes), and
`POST /me/verify {email, code}` stores it as `university_email`, sets
`verified_at` and the university. Whoever controls that university email
gets the same account when signing in with it. Email-code sign-in still
needs a university email. The session check reads the student's current
university and verified flag from the database on every request, so a
choice or verification applies at once. Groups need a university
(`UNIVERSITY_REQUIRED`). Campus Voice (R2) will require verified students.

### Authentication

- **Sign-in = university email + 6-digit code.** Codes are stored only as an HMAC hash (`CODE_HMAC_SECRET`), never in plain text.
- **Accounts are created only after a correct code or a verified university Google account**, so every account is a verified student of a known university. One email = one account, whichever way the student signs in.
- **Google sign-in:** the app signs in with Google through Firebase Auth (Android: the phone's own account picker via `google_sign_in_android` / Credential Manager, then `signInWithCredential`; iOS: `signInWithProvider`, a secure browser sheet, since the google_sign_in iOS SDK conflicts with Firebase iOS 13) and sends the Firebase ID token to `POST /auth/google`. The Go API verifies it itself (RS256, Google's published keys, audience = `FIREBASE_PROJECT_ID`, issuer, expiry, provider `google.com`, verified email); no Firebase admin key is needed. The app then signs out of Firebase: our own session is the only one that counts.
- **University matching:** by email domain, including subdomains (`cse.du.ac.bd` → `du.ac.bd`); the longest matching domain wins. Domains live in a `university_domains` table (each domain unique; shared suffixes and free mail are refused by the database). The full list of Bangladeshi universities and their domains is in [UNIVERSITIES.md](UNIVERSITIES.md), generated from `backend/data/universities_bd.json` (`make universities`).
- **Access token:** JWT (HS256, `JWT_SECRET`), valid 15 minutes. Claims: `sub` (user id), `sid` (session id), `uni` (university id), `role`.
- **Refresh token:** 32 random bytes, stored hashed in the `sessions` table, valid 60 days, **rotated on every use**. Reusing an old refresh token is treated as theft and revokes the whole session.
- Tokens are kept on the phone in secure storage (Keychain / Android Keystore).
- **Every signed-in request checks the session is still active**, so sign out, sign out everywhere and account deletion take effect immediately, not when the access token expires.
- The app must send **one refresh at a time**: replaying an already-rotated refresh token ends the session.

### Error codes (wire contract)

| HTTP | Code | When | App does |
|---|---|---|---|
| 400 | `VALIDATION_FAILED` | A field is invalid (`details.fields`) | Show the field error |
| 400 | `BAD_REQUEST` | Bad JSON or unknown field | Bug: report |
| 403 | `UNIVERSITY_EMAIL_REQUIRED` | Email is not from a supported university | Ask for the university email |
| 429 | `CODE_RESEND_TOO_SOON` | New code asked within 60 s (`details.retryAfterSeconds`) | Show countdown |
| 429 | `CODE_LIMIT_REACHED` | More than 5 codes in an hour | Show "try later" |
| 502 | `EMAIL_SEND_FAILED` | Email provider failed | "Try again" (no wait needed) |
| 400 | `CODE_INVALID` | Wrong code (`details.remainingAttempts`) | Show attempts left |
| 400 | `CODE_EXPIRED` | Code expired, used, or never sent | Offer a new code |
| 429 | `CODE_TOO_MANY_ATTEMPTS` | 5 wrong codes | Offer a new code |
| 401 | `UNAUTHORIZED` / `TOKEN_INVALID` | No or bad access token | Sign in |
| 401 | `GOOGLE_TOKEN_INVALID` | Firebase token rejected | "Google sign-in didn't work" |
| 503 | `GOOGLE_SIGN_IN_UNAVAILABLE` | Server has no `FIREBASE_PROJECT_ID` | Offer email code |
| 401 | `TOKEN_EXPIRED` | Access token expired | Refresh, then retry |
| 401 | `REFRESH_INVALID` / `SESSION_ENDED` | Signed out, deleted, or session revoked | Sign in |
| 429 | `TOO_MANY_REQUESTS` | Per-IP limit on sign-in endpoints | Show countdown |
| 500 | `INTERNAL_ERROR` | Bug (details only in server logs, by `X-Trace-Id`) | Generic error |

In the app, `campus_data`'s `ApiClient` turns these into `campus_core` failures: 401 → `UnauthenticatedFailure`, 429 → `RateLimitedFailure`, `VALIDATION_FAILED` → `ValidationFailure`, other business codes → `RejectedFailure`. Each failure carries `code`.

---

## 3. Anonymity built into the design

Identity is **physically separated** from content. Hiding a field in the UI is not enough.

```
issues          (id, university_id, public_author_id NULL when anonymous, …)
issue_authors   (issue_id, user_id)   ← no endpoint ever returns this table
```

- `POST /issues` writes the content to `issues` and the real author to `issue_authors` in one transaction.
- Response DTOs for issues have **no author id field** for anonymous posts. The only "who" information is `public_author_id` / display name, and only when the author chose to post with their name.
- "My posts" (`GET /me/issues`) looks up the caller's own rows in `issue_authors` from the token, and returns only their posts.
- Same pattern for comments (`comment_authors`) and reports (`report_authors`). Votes: a user only ever sees whether *they* voted; counts are kept in `issues.me_too_count`.
- Moderators ban through `POST /moderation/issues/{id}/ban-author`, which acts on the hidden user **without returning who they are**. Revealing identity is a separate, logged, two-admin procedure.
- Every moderator/admin action is written to an `audit_log` table that no endpoint exposes.
- **End-to-end tests** (`internal/app`) call the real HTTP API as a student, an authority and a moderator and prove that none of them can learn who wrote an anonymous post. These tests run in CI on every change.

---

## 4. Flutter app architecture

### Monorepo layout (Dart pub workspace + Go backend)

```
campussaga/
├─ apps/
│  ├─ mobile/                 # the student app
│  └─ web/                    # varsitykotha.com: public pages + superadmin panel (Next.js, docs/ADMIN.md)
├─ packages/
│  ├─ campus_ui/              # design system: tokens, theme, components
│  ├─ campus_core/            # domain models, repository interfaces, errors
│  ├─ campus_data/            # HTTP implementations of the repositories (talks to the Go API)
│  └─ campus_l10n/            # Bangla + English strings
├─ backend/                   # Go API (see section 5)
├─ docs/
└─ pubspec.yaml               # Dart workspace root
```

Why packages: the mobile app and the web dashboard share the same design
system, models and data layer. Changing the backend means changing only
`campus_data`.

### Layers inside each feature

```
apps/mobile/lib/
  app/                 # bootstrap, router, DI (get_it), env config, settings cubit
  features/
    auth/
      presentation/
        bloc/          # auth_bloc.dart, auth_event.dart, auth_state.dart
        pages/         # screens
        widgets/       # feature-only widgets
      application/     # use-cases that combine repositories (optional)
    today/             # R1: home screen, next class
    class_groups/      # R1: create / join / manage, announcements
    routine/           # R1: weekly routine, changes, personal slots
    reminders/         # R1: local notification scheduling
    feed/              # R2 onwards
    issue/
    comments/
    notifications/
    profile/
    university/
    verification/
```

Dependency direction, always one way:

```
presentation ─▶ application ─▶ campus_core (interfaces, models)
                                     ▲
                    campus_data ─────┘ (implements interfaces)
```

- Screens never make HTTP calls. Only `campus_data` imports `package:http`.
- **State management: Bloc** (`flutter_bloc`), the same as our other Flutter apps.
  - **Bloc** (events → states) for flows with several steps: sign-in (request code → enter code → resend timer → locked), routine sync, posting an issue.
  - **Cubit** for simple state changed by direct calls: settings, filters, toggles.
  - States extend `Equatable`; every bloc has `bloc_test` tests.
  - Blocs get repositories through their constructor; `get_it` (`app/di.dart`) holds long-lived services such as `ApiClient` and the repositories. Blocs themselves are created by `BlocProvider` where a screen needs them.
  - A `BlocObserver` logs every transition in debug builds (added with the first real bloc).
- Models are immutable (`freezed`) with JSON mapping (`json_serializable`).
- Errors are typed (`NetworkFailure`, `RateLimitedFailure`, `ForbiddenFailure` …), mapped from the API's error codes, so the UI can show friendly messages.

### Core packages

| Need | Package |
|---|---|
| State | `flutter_bloc`, `equatable`; tests with `bloc_test` |
| Dependency injection | `get_it` |
| Routing / deep links | `go_router` |
| Backend calls | `http` (only inside `campus_data`) |
| Models | `freezed`, `json_serializable` |
| Secure token storage | `flutter_secure_storage` |
| Settings (theme, language) | `shared_preferences` (`SharedPreferencesWithCache`, read before the first frame) |
| App version / store link | `package_info_plus`, `url_launcher`; the minimum build and store links come from `GET /config` |
| Images | `image_picker`, `flutter_image_compress`, `cached_network_image` |
| Offline storage (R1) | `drift` (SQLite): routine, changes, announcements |
| Class reminders | `flutter_local_notifications` + `timezone` |
| QR join codes | `qr_flutter` (show), `mobile_scanner` (scan) |
| Push | `firebase_messaging` |
| Localization | `flutter_localizations` + ARB files |
| Crash reports | Firebase Crashlytics (release builds only; no user id or profile data attached). Flutter, async and bloc errors are all reported |
| Component catalog | `widgetbook` |

---

## 5. Go backend structure

Same conventions as our `gamebackend` service.

```
backend/                          module github.com/zamansheikh/varsitykotha/backend
├─ cmd/campusapi/                 main: `campusapi serve` | `campusapi migrate`
├─ internal/
│  ├─ platform/
│  │  ├─ config/                  env → Config (dev defaults; secrets required in production)
│  │  ├─ db/                      pgx/v5 pool, InTx (tx travels in ctx), AfterCommit hooks
│  │  ├─ httpx/                   envelope, typed handlers, binding + validation, middleware
│  │  ├─ apperr/                  the one client-facing error type (status, code, message)
│  │  ├─ auth/                    JWT access tokens, session/refresh tokens, guards
│  │  ├─ ratelimit/               in-process fixed-window limiter
│  │  └─ mail/                    SMTP sender (logs the code in development without SMTP)
│  ├─ modules/
│  │  ├─ universities/            handler · service · store/ (sqlc) · queries.sql
│  │  ├─ accounts/                sign-in codes, sessions, profile, delete account
│  │  ├─ classgroups/             class groups, join codes, weekly routine (My Class)
│  │  └─ appconfig/               min build, feature flags
│  ├─ app/                        wiring (router + modules) and end-to-end tests
│  └─ testkit/                    fresh Postgres DB per test, cloned from a migrated template
├─ migrations/                    goose SQL files, embedded in the binary
├─ Makefile · docker-compose.yml · Dockerfile
```

| Concern | Library |
|---|---|
| Router | `go-chi/chi/v5` |
| Database | `jackc/pgx/v5` (pool) + `sqlc` (typed queries per module) |
| Migrations | `pressly/goose/v3` (embedded) |
| Validation | `go-playground/validator/v10` |
| Tokens | `golang-jwt/jwt/v5` |
| Logging | `log/slog` (JSON in production) |
| Tests | `stretchr/testify`, `go test -race` |

**Rules**

- Modules never import each other. `internal/app` wires them together.
- Each module's queries live in `store/queries.sql`; `make sqlc` regenerates the Go code.
- Migrations are numbered by area: `00001_platform`, `00100_universities`, `00200_accounts`, `00300_app_config`; later areas take the next hundred. **Never edit a migration that has shipped; add a new one.**
- Every test gets its own fresh database (`testkit`), so tests run in parallel and never share state.

---

## 6. Data model

Exact columns are in `backend/migrations/`. Overview:

```sql
-- R0 Foundation
universities        id, slug, name, name_bn, city, timezone (default 'Asia/Dhaka'),
                    week_start, is_active
university_domains  domain (unique), university_id
users               id, email (unique), university_id, role, display_name,
                    department, batch, verified_at, created_at
sign_in_codes       email, university_id, code_hash (HMAC), attempts, sends, window_start,
                    last_sent_at, expires_at
sessions            id, user_id, refresh_hash, expires_at, revoked_at,
                    user_agent, created_at, last_used_at
app_config          key, value jsonb   -- min_supported_build, feature flags
audit_log           id, actor_id, action, target_type, target_id, meta, created_at
device_tokens       user_id, token, platform, updated_at   -- R1 (push)

-- R1 My Class (built: migration 00400)
class_groups        id, university_id, department, batch, section, semester
                    ('Fall 2026'), join_code (6 letters, no I/O), created_by,
                    created_at, updated_at
class_group_members group_id, user_id, role ('cr'|'member'), joined_at
routine_slots       id, group_id, course_code, course_title, teacher, room,
                    weekday (ISO 1–7), starts_min, ends_min (minutes after
                    midnight), kind ('theory'|'lab')
routine_changes     id, group_id, slot_id NULL (extra), date, kind
                    ('cancelled'|'moved'|'extra'), course fields (extra),
                    room, starts_min, ends_min, note, created_by
                    -- migration 00410; one per (slot_id, date)
announcements       id, group_id, body, pinned (one per group), created_by,
                    created_at  -- migration 00420
device_tokens       token, user_id, session_id, platform, language
                    -- migration 00430 (push)
class_member_hidden_courses  group_id, user_id, course_key  -- 00440
personal_slots      id, user_id, title, details, place, weekday,
                    starts_min, ends_min  -- 00440, owner only
-- R1 My Class (planned)
                    join code reset
routine_changes     id, group_id, slot_id NULL, date, type ('cancelled'|
                    'rescheduled'|'room_changed'|'extra'), new_start, new_end,
                    new_room, note, created_by, created_at
announcements       id, group_id, body, pinned, created_by, created_at
member_course_prefs user_id, course_id, hidden, reminder_minutes, muted
personal_slots      id, user_id, title, weekday, start_time, end_time, place
                    -- only the owner, ever

-- R2 Campus Voice
issues              id, university_id, public_author_id NULL, title, body,
                    category, status, location_label, me_too_count,
                    comment_count, created_at, updated_at, removed_at
issue_images        id, issue_id, storage_key (R2), width, height
issue_votes         issue_id, user_id, created_at   PK(issue_id, user_id)
comments            id, issue_id, anon_handle, public_author_id NULL, body,
                    is_official, created_at, removed_at
status_updates      id, issue_id, actor_role, from_status, to_status, note, created_at
reports             id, target_type, target_id, reason, state, created_at
authorities         id, university_id, user_id, title, verified_at
notifications       id, user_id, type, payload jsonb, read_at, created_at

-- Authorship (no endpoint ever returns these tables)
issue_authors       issue_id, user_id
comment_authors     comment_id, user_id
report_authors      report_id, user_id
```

**Future-proof choices in the schema**

- `university_id` on every row → multi-university from day one; queries are always scoped by the caller's university from the token.
- Verification is separate from login → we can add ID card review, university SSO or alumni status later without touching sign-in.
- Status, category and role are enums or lookup tables, and the app treats unknown values gracefully (shows "Other"), so the backend can add a value without breaking old app versions.
- Soft delete (`removed_at`) instead of hard delete → moderation history and appeals.
- UUID primary keys everywhere (no guessable IDs like `/issues/42`).
- Keyset (cursor) pagination: `created_at < $cursor`, never `OFFSET`.

### Class group rules

- Only verified students of the same university can join a group (by invite code).
- Members read the group's courses, slots, changes and announcements. **Only CR/co-CR write** them, through explicit endpoints (`POST /groups/{id}/changes`, `POST /groups/{id}/announcements` …). The service checks the caller's role in that group on every write.
- Member lists are returned only to CRs; members see a count.
- Group membership is **never joined with issue data** in any response, so an anonymous issue can't be narrowed down to a section.
- Rate limits on announcements and joins (stops spam and code guessing). Invite codes can be reset by the CR.

---

## 7. Routine and reminders design

**Offline first.** The phone keeps a copy of the student's groups and slots
(today: the last `GET /groups` as JSON in shared preferences, per account;
SQLite with `drift` once changes and announcements make it larger). Today
and Routine read the local copy first, so they open instantly offline.

**Sync.** On app open, on resume and after every edit: fetch `GET /groups`.
Later: rows changed since `last_synced_at`, and on push notification.

**Effective routine for a date** = weekly slots valid on that date
− hidden courses − cancelled changes ± rescheduled/room changes + extra
classes + personal slots − university holidays (R3).
This is one pure Dart function in `campus_core`, fully unit-tested, used by
both the Today screen and the reminder scheduler.

**Reminders are local notifications, scheduled on the phone** (built:
`flutter_local_notifications`, `features/reminders`, planning in
`campus_core` `planReminders`). No server needed, and they work offline.

- **Rolling window**: the next 14 days, at most 60 (iOS keeps 64 pending per app). One-shot notifications, not weekly repeats, so a single cancelled class can be skipped later.
- Re-planned on: app open and resume, any routine change, reminder setting change, language change. Android re-creates them after a reboot (`RECEIVE_BOOT_COMPLETED` + the plugin's boot receiver). The plan is only re-sent when it changed.
- Choices on the phone: on/off, 5/10/15/30 minutes before (default 10), per-course off. The same course at the same time in two groups reminds once.
- Android 12+: exact alarms use `SCHEDULE_EXACT_ALARM`; the reminders screen offers "Remind on time" when it isn't allowed, otherwise reminders are inexact (a few minutes late). Check Play policy before release (`USE_EXACT_ALARM` is for alarm and calendar apps).
- Permission is asked from a card on Today once the student has classes ("Never miss a class"), never at first launch. Blocked notifications are explained with a "Try again".
- Notification text follows the app language (Bengali digits in Bangla).
- Signing out empties the routine, which removes every pending reminder.
- Some brands (Xiaomi, Realme, Oppo, Vivo) kill background apps: show a one-time guide to turn off battery optimization.
- All times stored as local wall-clock time + the university's timezone (`Asia/Dhaka`), never converted to UTC for weekly slots.

**Change alerts.** When a CR cancels or moves a class, the API writes
`routine_changes` (built). The app applies changes in `classesOn` (core):
cancelled classes stay visible crossed out, moved ones use the new time and
room, extra ones are added; reminders skip cancelled classes and follow
moved ones. Today, members see changes on their next refresh (app open or
resume). Planned: after the transaction commits, a worker sends an FCM push
to members → the app syncs and re-schedules reminders.

---

## 8. Issue lifecycle (R2)

```
          ┌─────────┐ authority ┌──────────────┐ authority ┌─────────────┐
 post ──▶ │  OPEN   │ ────────▶ │ ACKNOWLEDGED │ ────────▶ │ IN PROGRESS │
          └────┬────┘           └──────┬───────┘           └──────┬──────┘
               │ moderator             │ authority (reason)       │ authority
               ▼                       ▼                          ▼
          ┌─────────┐            ┌──────────┐               ┌──────────┐
          │ REMOVED │            │ REJECTED │               │  SOLVED  │
          └─────────┘            └──────────┘               └────┬─────┘
                                                                 │ author / voters
                                                                 ▼ "not really fixed"
                                                             back to OPEN
```

Every transition is one endpoint (`POST /issues/{id}/status`) whose service
checks the role, writes `status_updates`, and queues notifications for all
voters after commit.

---

## 9. Background jobs

Background work runs as goroutine workers inside the Go process, started by
`campusapi serve`. If jobs ever need to survive restarts or retries at scale,
add a `jobs` table (Postgres `FOR UPDATE SKIP LOCKED`) — no extra service.

| Trigger | Job |
|---|---|
| Image uploaded | Strip EXIF, resize, NSFW check → store in Cloudflare R2 (S3 API) |
| CR changes a class or posts an announcement | After commit → FCM push to group members → app syncs and re-schedules reminders |
| New issue or comment | Text moderation (slurs, phone numbers, names) → auto-approve or hold |
| Status change / official reply | After commit → push to voters and followers (FCM) |
| Nightly ticker | Recalculate university scorecards into a `university_stats` table |
| Daily ticker | Delete expired sign-in codes and sessions; delete ID card photos older than 7 days |

---

## 10. Environments and delivery

| Environment | What |
|---|---|
| **local** | `make deps-up` (Postgres + Mailpit in Docker) + `make run` (API on :8090) + Flutter with `--dart-define-from-file=env/local.json` |
| **staging** | Second compose project on the VPS at `staging-api.<domain>` with its own database; internal testers via Play Console internal track |
| **production** | Go API + Postgres in Docker on the VPS at `api.<domain>`, behind nginx; Play Store |

- App config only through `--dart-define-from-file` (`API_BASE_URL`); no secrets in the app.
- Server secrets (`JWT_SECRET`, `CODE_HMAC_SECRET`, SMTP password, database password) live only in the server's `.env` file.
- CI (GitHub Actions) on every pull request:
  1. Flutter: `dart format --set-exit-if-changed`, `flutter analyze`, unit + widget + golden tests, build APK
  2. Go: `gofmt`, `go vet`, `go test -race` against a Postgres service container (includes the security e2e tests)
- Database changes only through new migration files, reviewed in the pull request, applied to staging first (`campusapi migrate`).
- **Forced update**: the app reads `min_supported_build` from `GET /config` on start, so we can retire old app versions when the API changes.
- **Feature flags** in `app_config` to turn features on per university.

---

## 11. Scaling path (do nothing until the numbers say so)

| Stage | Users | Action |
|---|---|---|
| Launch | < 10k | One API container + Postgres on the shared VPS, images on Cloudflare R2, off-site backups |
| Growing | 10k–200k | Indexes from the slow-query log; Cloudflare in front for caching and DDoS protection; move Postgres to its own server or a managed Postgres |
| Large | 200k+ | Several API instances behind nginx (move rate limits to Redis), read replica, heavy search in Typesense/Meilisearch |
| Exit plan | any | Restore the same Postgres dump anywhere; the API is one container; the app changes only its `API_BASE_URL` |

---

## 12. Setup checklist

```bash
cd backend
make deps-up        # Postgres 18 (:55632) + Mailpit (SMTP :55625, UI http://localhost:58025)
make run            # API on :8090, applies migrations first in development
make seed           # dev universities: demo.ac.bd, sit.edu.bd
make test           # go test -race, fresh database per test

cd .. && flutter pub get && ./tool/test_all.sh   # app + packages
```
