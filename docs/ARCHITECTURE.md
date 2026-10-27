# Campus Saga — Architecture

Goal: ship the MVP fast with a small team, without painting ourselves into a
corner. Every choice below can be replaced later without rewriting the app.

---

## 1. Database decision

**Decision: PostgreSQL, using Supabase self-hosted on our own VPS.**
(Setup and hardening: [DEPLOYMENT.md](DEPLOYMENT.md).)

| Hosting option | Verdict |
|---|---|
| **Self-hosted Supabase on our VPS** | ✅ Chosen: no monthly bill, data stays on our server, same features and code as Supabase Cloud |
| Supabase Cloud | Backup plan: same code, just change the URL and keys. Use it if running the server becomes too much work |
| Plain Postgres + own API (Serverpod / NestJS) | Later, only if we outgrow Supabase; the repository layer makes this a swap of `campus_data` |

| Option | Verdict | Why |
|---|---|---|
| **PostgreSQL (Supabase)** | ✅ Chosen | Relational data (users → universities → issues → votes → comments), strong access rules (Row Level Security), SQL for rankings and scorecards, open source and portable |
| Firebase Firestore | ❌ | NoSQL makes counts, rankings and "issues solved per university per month" painful and costly; security rules can't hide one field (author) on a document; full vendor lock-in |
| MongoDB | ❌ | No real benefit for this data; weaker for joins and reporting |
| MySQL | ⚠️ Possible | Fine, but no RLS, weaker JSON, no pgvector/PostGIS ecosystem |
| Own server + Postgres (NestJS) | ⏳ Later | Maximum control, but months of extra work now. Our design keeps this door open |

**Why this is future-proof**

- Postgres is the industry standard. Any host (Supabase, AWS RDS, Neon, your own server) runs it.
- Supabase is open source; we self-host it on our VPS and can move to Supabase Cloud (or another server) by restoring the **same database dump**.
- Everything is in **SQL migration files in git**, not clicked together in a dashboard.
- The app never talks to Supabase from screens. It goes through a **repository layer** (section 4), so swapping Supabase for our own API later means rewriting one folder, not the whole app.
- Postgres grows with us:
  - `pg_trgm` → "similar issues" duplicate check and search (works with Bangla text)
  - `pgvector` → smarter duplicate detection and recommendations later
  - `PostGIS` → campus map / issue location later
  - `pg_cron` → nightly scorecard calculation
  - `pgmq` (Supabase Queues) → background jobs like notifications

---

## 2. System overview

```
┌────────────────────┐   ┌──────────────────────┐
│  Flutter mobile    │   │ Authority web (v1.5) │
│  (Android, iOS)    │   │ Flutter Web          │
└─────────┬──────────┘   └──────────┬───────────┘
          │  HTTPS + JWT            │
          ▼                         ▼
┌─────────────────────────────────────────────────┐
│                    Supabase                     │
│                                                 │
│  Auth (email OTP, Google)                       │
│  REST (PostgREST) ── reads: public views only   │
│  RPC (SQL functions) ── all writes / commands   │
│  Edge Functions (TypeScript) ── side effects:   │
│    image cleaning, moderation, push, emails     │
│  Storage ── quarantine bucket → public bucket   │
│  Realtime ── live status / comment updates      │
│                                                 │
│  PostgreSQL                                     │
│   ├─ schema public   (exposed: views, RPCs)     │
│   └─ schema private  (NOT exposed: identities,  │
│                       authorship, audit log)    │
└───────────────┬─────────────────────────────────┘
                ▼
      FCM (push) · Moderation API · Email provider
```

### Three rules for talking to the backend

1. **Reads** go through views in the `public` schema. Views never contain identity columns.
2. **Writes** go through RPC functions (`create_issue`, `vote_issue`, `change_status` …). Clients never `insert` into tables directly. Validation, rate limits and permission checks live in one place: the database function.
3. **Side effects** (send push, clean image, call moderation API) go through Edge Functions, triggered by queues or database webhooks, never from the app.

This "commands in, views out" design is what lets us replace Supabase later.
An own API would expose the same commands and the same view shapes.

---

## 3. Anonymity built into the database

Identity is **physically separated** from content. Hiding a column in the UI is not enough.

```
private.issue_authors   (issue_id, user_id)      ← never exposed via API
public.issues           (id, …, public_author_id NULL when anonymous)
public.issues_feed      VIEW: issues + author name only when not anonymous
```

- The `private` schema is not exposed through the REST API at all.
- `create_issue()` (security definer function) writes the content to `public.issues` and the real author to `private.issue_authors` in one transaction.
- "My posts" works through `my_issues()`, which looks up `auth.uid()` in the private table and returns only the caller's own posts.
- Same pattern for comments (`private.comment_authors`) and votes (a user can only read their own vote rows; counts are kept in `issues.me_too_count` by a trigger).
- Moderators ban through `ban_author_of(issue_id)`, which acts on the hidden user **without returning who they are**. Revealing identity is a separate, logged, two-admin procedure.
- Automated tests (pgTAP) prove that a normal user, an authority and a moderator **cannot** read `private.*`. These tests run in CI on every change.

---

## 4. Flutter app architecture

### Monorepo layout (Dart pub workspaces)

```
campussaga/
├─ apps/
│  ├─ mobile/                 # the student app
│  └─ admin_web/              # authority + moderator dashboard (v1.5)
├─ packages/
│  ├─ campus_ui/              # design system: tokens, theme, components
│  ├─ campus_core/            # domain models, repository interfaces, errors
│  ├─ campus_data/            # Supabase implementations of the repositories
│  └─ campus_l10n/            # Bangla + English strings
├─ supabase/
│  ├─ migrations/             # every schema change, in order
│  ├─ functions/              # Edge Functions (TypeScript)
│  ├─ tests/                  # pgTAP tests for RLS + RPCs
│  └─ seed.sql                # test universities, users, issues
├─ docs/
└─ pubspec.yaml               # workspace root
```

Why packages: the mobile app and the web dashboard share the same design
system, models and data layer. Replacing the backend means replacing only
`campus_data`.

### Layers inside each feature

```
apps/mobile/lib/
  app/                 # bootstrap, router, DI (providers), env config
  features/
    auth/
      presentation/    # screens, widgets, controllers (Riverpod Notifiers)
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

- Screens never import `supabase_flutter`. A lint rule (`import_lint` or a custom check in CI) enforces this.
- Models are immutable (`freezed`) with JSON mapping (`json_serializable`).
- Errors are typed (`Failure.network`, `Failure.rateLimited`, `Failure.forbidden` …) so the UI can show friendly messages.

### Core packages

| Need | Package |
|---|---|
| State + DI | `flutter_riverpod` (+ `riverpod_generator`) |
| Routing / deep links | `go_router` |
| Backend | `supabase_flutter` (only inside `campus_data`) |
| Models | `freezed`, `json_serializable` |
| Secure token storage | `flutter_secure_storage` |
| Images | `image_picker`, `flutter_image_compress`, `cached_network_image` |
| Offline storage (R1) | `drift` (SQLite): routine, changes, announcements |
| Class reminders | `flutter_local_notifications` + `timezone` |
| QR join codes | `qr_flutter` (show), `mobile_scanner` (scan) |
| Push | `firebase_messaging` |
| Localization | `flutter_localizations` + ARB files |
| Crash reports | `sentry_flutter` or Firebase Crashlytics |
| Component catalog | `widgetbook` |

---

## 5. Data model

```sql
-- R0 Foundation
universities        id, slug, name, name_bn, email_domains text[], logo_url, city,
                    timezone (default 'Asia/Dhaka')
profiles            id (= auth.users.id), university_id, display_name, role,
                    department, batch, reputation, created_at
student_verifications id, user_id, method ('email'|'id_card'|'sso'),
                    university_id, status, verified_at
app_config          key, value jsonb   -- min app version, feature flags
device_tokens       user_id, token, platform, updated_at

-- R1 My Class
class_groups        id, university_id, department, program, batch, section,
                    semester_label ('Spring 2027'), invite_code, status
                    ('active'|'archived'), created_at
group_members       group_id, user_id, role ('cr'|'co_cr'|'member'), joined_at
courses             id, group_id, code ('CSE 301'), title, teacher_name, color
routine_slots       id, group_id, course_id, weekday (1–7), start_time, end_time,
                    room, kind ('theory'|'lab'|'tutorial'), valid_from, valid_to
routine_changes     id, group_id, slot_id NULL, date, type ('cancelled'|
                    'rescheduled'|'room_changed'|'extra'), new_start, new_end,
                    new_room, note, created_by, created_at
announcements       id, group_id, body, pinned, created_by, created_at
member_course_prefs user_id, course_id, hidden, reminder_minutes, muted
personal_slots      id, user_id, title, weekday, start_time, end_time, place
                    -- RLS: only the owner, ever

-- R2 Campus Voice
issues              id, university_id, public_author_id NULL, title, body,
                    category, status, location_label, me_too_count,
                    comment_count, created_at, updated_at, removed_at
issue_images        id, issue_id, storage_path, width, height
issue_votes         issue_id, user_id, created_at   PK(issue_id, user_id)
comments            id, issue_id, anon_handle, public_author_id NULL, body,
                    is_official, created_at, removed_at
status_updates      id, issue_id, actor_role, from_status, to_status, note, created_at
reports             id, target_type, target_id, reason, state, created_at
authorities         id, university_id, user_id, title, verified_at
notifications       id, user_id, type, payload jsonb, read_at, created_at

-- private schema (never exposed)
private.issue_authors     issue_id, user_id
private.comment_authors   comment_id, user_id
private.report_authors    report_id, user_id
private.audit_log         id, actor_id, action, target_type, target_id, meta, created_at
private.rate_limits       user_id, action, window_start, count
```

**Future-proof choices in the schema**

- `university_id` on every row → multi-university from day one; RLS scopes by it.
- `student_verifications` is separate from login → we can add ID card review, university SSO or alumni status later without touching auth.
- Status, category and role are Postgres enums or lookup tables, and the app treats unknown values gracefully (shows "Other"), so the backend can add a value without breaking old app versions.
- Soft delete (`removed_at`) instead of hard delete → moderation history and appeals.
- UUID primary keys everywhere (no guessable IDs like `/issues/42`).
- Keyset (cursor) pagination: `created_at < $cursor`, never `OFFSET`.

---

### Class group rules (RLS)

- Only verified students of the same university can join a group (by invite code).
- Members read the group's courses, slots, changes and announcements. **Only CR/co-CR write** them, through RPCs (`cancel_class`, `change_room`, `post_announcement` …).
- Member lists are readable only by CRs; members see a count.
- Group membership is **never joined with issue data** in any view, so an anonymous issue can't be narrowed down to a section.
- Rate limits on announcements and joins (stops spam and code guessing). Invite codes can be reset by the CR.

---

## 6. Routine and reminders design

**Offline first.** The phone keeps a copy of the student's groups, slots,
changes and announcements in SQLite (`drift`). The Today screen reads only the
local copy, so it opens instantly without internet.

**Sync.** On app open and on push notification: fetch rows changed since
`last_synced_at` (every table has `updated_at`). Realtime updates only while
a group screen is open.

**Effective routine for a date** = weekly slots valid on that date
− hidden courses − cancelled changes ± rescheduled/room changes + extra
classes + personal slots − university holidays (R3).
This is one pure Dart function in `campus_core`, fully unit-tested, used by
both the Today screen and the reminder scheduler.

**Reminders are local notifications, scheduled on the phone.** No server
needed, and they work offline.

- Keep a **rolling window**: schedule only the next 7 days (iOS allows max 64 pending notifications; it also limits work on Android).
- Re-schedule on: app open, sync with changes, push about a change, timezone change, phone reboot (`RECEIVE_BOOT_COMPLETED`).
- Android 12+: exact alarms need permission. Ask with a clear explanation and fall back to inexact alarms (± a few minutes) if denied. Check Play policy for `SCHEDULE_EXACT_ALARM` vs `USE_EXACT_ALARM` before release.
- Android 13+: ask for notification permission at the right moment (after joining the first group), not at first launch.
- Some brands (Xiaomi, Realme, Oppo, Vivo) kill background apps: show a one-time guide to turn off battery optimization.
- All times stored as local wall-clock time + the university's timezone (`Asia/Dhaka`), never converted to UTC for weekly slots.

**Change alerts.** When a CR cancels or moves a class, an RPC writes
`routine_changes` → a queue job sends FCM push to members → the app syncs and
re-schedules reminders. If the push is missed, the next app open fixes it.

---

## 7. Issue lifecycle (R2)

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

Every transition is one RPC (`change_issue_status`) that checks the role,
writes `status_updates`, and enqueues notifications for all voters.

---

## 8. Background jobs

| Trigger | Job |
|---|---|
| Image uploaded to `quarantine/` | Edge Function: strip EXIF, resize, NSFW check → move to `public-images/` |
| CR changes a class or posts an announcement | Queue → FCM push to group members → app syncs and re-schedules reminders |
| New issue or comment | Queue → text moderation (slurs, phone numbers, names) → auto-approve or hold |
| Status change / official reply | Queue → push to voters and followers (FCM) |
| Nightly (`pg_cron`) | Recalculate university scorecards into a `university_stats` table |
| Daily | Delete ID card photos older than 7 days; clean expired rate-limit rows |

---

## 9. Environments and delivery

| Environment | What |
|---|---|
| **local** | `supabase start` (Docker on the Mac) + Flutter with `--dart-define-from-file=env/local.json` |
| **staging** | Second Docker Compose stack on the VPS (if it has ≥ 8 GB RAM) at `staging-api.<domain>`, or a small second VPS; internal testers via Play Console internal track |
| **production** | Self-hosted Supabase on the VPS at `api.<domain>`; Play Store |

- Env config only through `--dart-define-from-file`; no secrets in the app. The Supabase anon key is public by design. The **service role key never leaves the server**.
- CI (GitHub Actions) on every pull request:
  1. `dart format --set-exit-if-changed` + `flutter analyze`
  2. unit + widget + golden tests
  3. `supabase db reset` + `supabase test db` (RLS / pgTAP tests)
  4. build APK
- Database changes only through migrations (`supabase migration new <name>`), reviewed in the pull request, applied to staging first.
- **Forced update**: the app reads `app_config.min_supported_version` on start, so we can retire old app versions when the API changes.
- **Feature flags** in `app_config` to turn features on per university.

---

## 10. Scaling path (do nothing until the numbers say so)

| Stage | Users | Action |
|---|---|---|
| Launch | < 10k | One VPS (4–8 GB RAM), images on Cloudflare R2, off-site backups |
| Growing | 10k+ | Bigger VPS, or move Postgres to its own server; Cloudflare in front for caching and DDoS protection |
| Growth | 10k–200k | Add indexes from slow-query log, Realtime only on detail screens, CDN for images |
| Large | 200k+ | Read replica, move heavy search to Typesense/Meilisearch, consider own API service in front of the same Postgres |
| Exit plan | any | Move to Supabase Cloud (restore the same dump) or own API + Postgres; app changes only `campus_data` |

---

## 11. Setup checklist

```bash
brew install supabase/tap/supabase          # Supabase CLI
supabase start                              # local stack in Docker (OrbStack)
supabase db reset                           # re-apply migrations + seed.sql
supabase test db                            # security tests in supabase/tests/
flutter pub get && ./tool/test_all.sh       # app + packages
```
