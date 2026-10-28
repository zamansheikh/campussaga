# Campus Voice (R2): build spec

Students raise campus issues (anonymous by default), others tap **Me too**,
the university's own staff reply officially and move the issue to
**Solved**. This document is the contract for three parallel tracks: Go API,
Flutter app, Next.js admin web. Change it only through the parent (doc
owner); implementers code against it and use fakes until the other side
exists.

Conventions are the existing ones: error envelope and codes
(ARCHITECTURE.md §2), `httpx` typed handlers and bindings, sqlc per module,
goose migrations, Bloc/go_router, `campus_ui` components, EN + BN ARB.

---

## 1. Scope

**In this release**

- Post an issue: category, title, details, up to 4 photos, an optional place
  label ("Library, 3rd floor"), anonymous by default (or with my name).
- "Similar issues" shown before posting.
- Feed of my university: Trending / New / Solved, category filter, search.
- Me too (vote) and Follow; counts only, never who.
- Comments with per-issue anonymous handles ("Student 7KQF"); the issue's
  author is marked "Author".
- Status timeline: Open → Acknowledged → In progress → Solved / Rejected;
  author can reopen a solved issue.
- Authority accounts (set by an admin) post **official replies** and change
  status, from the app.
- Report issues and comments; text auto-check; moderation queue in the web
  admin panel; hide / remove with reason; ban an author **without learning
  who they are**.
- Safety category: private to the author, moderators and that university's
  authorities; never in the feed.
- Pushes: status changes, official replies, new comments (to the author),
  moderation outcomes (to the author).
- "How anonymity works" screen.
- Audit log of every staff action.

**Out (later)**: in-app notification inbox (pushes + "My issues" only),
appeals, identity reveal endpoint (only the manual two-admin procedure in
§2.6), university scorecards, authority web dashboard (R4), comments with
photos, editing comments, AI moderation services, campus map.

**App screens**: Campus feed (tab) · Issue detail · Raise issue (3 steps) ·
My issues · How anonymity works · Authority: change status sheet, official
reply composer.

**Web admin screens**: Moderation queue · Moderation item · Staff
(authorities and moderators) · dashboard card for Campus Voice.

---

## 2. Anonymity model

### 2.1 Storage

- Content tables (`issues`, `comments`, `reports`) have **no user id** for
  anonymous content. Authorship lives in `issue_authors`, `comment_authors`,
  `report_authors`. No endpoint returns, joins into a response, filters by, or
  logs these tables, with exactly these server-side uses:
  - computing `mine`, `isIssueAuthor`, `canEdit`, `canDelete`, `canReopen`
    for the **caller only** (`WHERE user_id = <caller>`);
  - `GET /me/issues` (caller's own rows);
  - push recipients (author of an issue), resolved inside the service;
  - `ban-author` (resolves the user inside one transaction, writes
    `voice_bans`, returns nothing about them);
  - rate limits and bans checked for the caller at write time.
- Named posts set `issues.named_author_id` / `comments.named_author_id`; only
  then do responses carry `author: {name, verified}` (display name, never
  email or id).
- Votes and follows are `(issue_id, user_id)` rows; responses expose only
  counts and the caller's own `voted` / `following`.

### 2.2 Handles

`handle = base32(HMAC-SHA256(VOICE_HMAC_SECRET, issue_id ‖ user_id))[:4]`
(uppercase, no I/O/0/1). Computed at comment time and **stored** on the
comment row (so the secret can rotate). Same person, same issue → same
handle; different issues → unrelated handles. The app renders
"Student 7KQF" / "শিক্ষার্থী 7KQF"; the issue's author renders "Author" /
"লেখক" (`isIssueAuthor`, computed by comparing `comment_authors.user_id`
with `issue_authors.user_id` in SQL; the ids never leave the query).
`VOICE_HMAC_SECRET`: new required secret in production `.env`; dev default.

### 2.3 Who sees what

| | Student (same uni) | Author | Authority (same uni) | Moderator | Admin |
|---|---|---|---|---|---|
| Public issues + comments | ✓ | ✓ | ✓ | ✓ | ✓ (via moderation views) |
| Safety (private) issues | – | own | ✓ | ✓ | ✓ |
| Held / hidden content | – | own, with state | – | ✓ | ✓ |
| Removed content | – | own, with reason | – | ✓ | ✓ |
| Who wrote anonymous content | ✗ | ✗ (only "mine") | ✗ | ✗ | ✗ |
| Who voted / followed / reported | ✗ | ✗ | ✗ | ✗ | ✗ |
| Report reasons and counts | – | – | – | ✓ | ✓ |

Other universities' issues: not visible to students or authorities
(`ISSUE_NOT_FOUND`); moderators and admins see all.

The admin panel's user pages **never** show a user's issues, comments,
votes or reports. `audit_log.meta` for voice actions **never** contains an
author's user id, email or name (it records the target issue/comment id).

### 2.4 Correlation defences

- `createdAt` of anonymous issues and comments is **rounded down to 5
  minutes** in every response (named content: exact). `updatedAt` is not
  returned for anonymous content.
- No push to anyone when an issue is posted (no "new issue nearby" alerts).
- No department, batch, class group, verification state or device info is
  attached to anonymous content. Class group data is never joined with voice
  data.
- Photos: re-encoded server-side, so EXIF (GPS, device, time) is dropped;
  file names are never kept.
- Error answers that only the author can trigger (`CANNOT_VOTE_OWN`) reveal
  nothing to others.
- Server request logs: the access log must not log request bodies for
  `/issues*` (it doesn't today); the user id in log lines for voice writes is
  replaced by `"voice"` (the httpx logger field is dropped for these
  routes). Logs are wiped within 30 days (existing policy).

### 2.5 "How anonymity works" (copy to show in the app)

1. Your name, email and class are never shown on anonymous posts.
2. We store who wrote what separately and no screen, staff member or
   university official can see it in the app or panel.
3. Your handle ("Student 7KQF") is different on every issue.
4. Photos are cleaned: location and phone details are removed.
5. Times are shown roughly, not to the minute.
6. Breaking the rules (threats, naming people, spam) can get your posting
   blocked, without anyone seeing who you are.
7. What you write can still give you away: don't include your name, roll
   number or details only you would know. Anyone can screenshot a public post.
8. Safety reports are private: only moderators and your university's
   officials see them.

### 2.6 Identity reveal

No endpoint. Only for a legal order: two admins run a documented SQL query
together on the server, and both record it in `audit_log` by hand
(`voice.identity_reveal`, with the order reference). Document it in
DEPLOYMENT.md; not built.

---

## 3. Data model (migrations 00500–00530)

`00500_campus_voice.sql`

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE issues (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id    uuid        NOT NULL REFERENCES universities (id),
  category         text        NOT NULL CHECK (category IN ('academic','hostel','transport',
                     'facilities','safety','administration','food','it','other')),
  private          boolean     NOT NULL,            -- category = 'safety'
  title            text        NOT NULL CHECK (char_length(title) BETWEEN 8 AND 120),
  body             text        NOT NULL CHECK (char_length(body) BETWEEN 20 AND 3000),
  location_label   text        NOT NULL DEFAULT '' CHECK (char_length(location_label) <= 80),
  status           text        NOT NULL DEFAULT 'open' CHECK (status IN
                     ('open','acknowledged','in_progress','solved','rejected')),
  visibility       text        NOT NULL DEFAULT 'visible' CHECK (visibility IN
                     ('visible','held','hidden','removed')),
  hold_reason      text        NOT NULL DEFAULT '',  -- auto-check rule that held it
  removed_reason   text        NOT NULL DEFAULT '' CHECK (char_length(removed_reason) <= 300),
  deleted_by_author boolean    NOT NULL DEFAULT false,
  named_author_id  uuid        REFERENCES users (id) ON DELETE SET NULL,
  me_too_count     int         NOT NULL DEFAULT 0,
  comment_count    int         NOT NULL DEFAULT 0,  -- visible comments
  report_count     int         NOT NULL DEFAULT 0,  -- open reports
  status_changed_at timestamptz NOT NULL DEFAULT now(),
  solved_at        timestamptz,
  edited_at        timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CHECK (private = (category = 'safety'))
);
CREATE INDEX issues_feed_idx ON issues (university_id, visibility, private, created_at DESC, id DESC);
CREATE INDEX issues_status_idx ON issues (university_id, status, status_changed_at DESC);
CREATE INDEX issues_title_trgm ON issues USING gin (title gin_trgm_ops);
-- + set_updated_at trigger

CREATE TABLE issue_authors (
  issue_id uuid PRIMARY KEY REFERENCES issues (id) ON DELETE CASCADE,
  user_id  uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE
);
CREATE INDEX issue_authors_user_idx ON issue_authors (user_id);

CREATE TABLE issue_votes (
  issue_id uuid REFERENCES issues (id) ON DELETE CASCADE,
  user_id  uuid REFERENCES users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (issue_id, user_id)
);
CREATE TABLE issue_follows (same shape as issue_votes);

CREATE TABLE status_updates (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id    uuid NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
  actor_kind  text NOT NULL CHECK (actor_kind IN ('authority','moderator','author','system')),
  actor_title text NOT NULL DEFAULT '',   -- authority's public title, e.g. "Proctor Office"
  from_status text NOT NULL, to_status text NOT NULL,
  note        text NOT NULL DEFAULT '' CHECK (char_length(note) <= 500),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX status_updates_issue_idx ON status_updates (issue_id, created_at);
```

`00510_voice_comments.sql`

```sql
CREATE TABLE comments (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id        uuid NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
  kind            text NOT NULL DEFAULT 'student' CHECK (kind IN ('student','official')),
  handle          text NOT NULL DEFAULT '',          -- '' for official and named
  official_title  text NOT NULL DEFAULT '',          -- official replies
  named_author_id uuid REFERENCES users (id) ON DELETE SET NULL,
  body            text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
  visibility      text NOT NULL DEFAULT 'visible' CHECK (visibility IN ('visible','held','hidden','removed')),
  hold_reason     text NOT NULL DEFAULT '',
  removed_reason  text NOT NULL DEFAULT '',
  deleted_by_author boolean NOT NULL DEFAULT false,
  report_count    int  NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX comments_issue_idx ON comments (issue_id, created_at, id);

CREATE TABLE comment_authors (
  comment_id uuid PRIMARY KEY REFERENCES comments (id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE
);
CREATE INDEX comment_authors_user_idx ON comment_authors (user_id);
```

Official replies are written by an authority **with** their title and
name (`named_author_id` set, `official_title` = staff title): officials are
public by design.

`00520_voice_media_reports.sql`

```sql
CREATE TABLE uploads (            -- photos not yet attached (deleted after 24 h)
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  full_key text NOT NULL, thumb_key text NOT NULL,
  width int NOT NULL, height int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE issue_images (       -- attached: no user link
  id uuid PRIMARY KEY,            -- = the upload's id
  issue_id uuid NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 3),
  full_key text NOT NULL, thumb_key text NOT NULL,
  width int NOT NULL, height int NOT NULL,
  UNIQUE (issue_id, position)
);

CREATE TABLE reports (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type text NOT NULL CHECK (target_type IN ('issue','comment')),
  target_id   uuid NOT NULL,
  issue_id    uuid NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
  reason      text NOT NULL CHECK (reason IN ('spam','abuse','personal_info','false_info','inappropriate','other')),
  details     text NOT NULL DEFAULT '' CHECK (char_length(details) <= 300),
  state       text NOT NULL DEFAULT 'open' CHECK (state IN ('open','resolved','dismissed')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);
CREATE INDEX reports_open_idx ON reports (state, created_at) WHERE state = 'open';
CREATE TABLE report_authors (
  report_id uuid PRIMARY KEY REFERENCES reports (id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  target_id uuid NOT NULL,
  UNIQUE (user_id, target_id)     -- one report per person per item
);
```

`00530_voice_staff.sql`

```sql
CREATE TABLE staff (
  user_id       uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  kind          text NOT NULL CHECK (kind IN ('authority','moderator')),
  university_id uuid REFERENCES universities (id),   -- NULL: moderator of all
  title         text NOT NULL DEFAULT '' CHECK (char_length(title) <= 80),
  created_at    timestamptz NOT NULL DEFAULT now(),
  CHECK (kind = 'moderator' OR (university_id IS NOT NULL AND char_length(title) >= 2))
);
CREATE TABLE voice_bans (
  user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  until      timestamptz,          -- NULL = permanent
  reason     text NOT NULL DEFAULT '' CHECK (char_length(reason) <= 300),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

`users.role` stays the access gate (`authority`, `moderator`, `admin`
already exist in the enum). Adding/removing staff sets both `staff` and
`users.role` in one transaction. Counters (`me_too_count`,
`comment_count`, `report_count`) are maintained by the service in the same
transaction as the row change.

Account deletion: `issue_authors`/`comment_authors`/votes cascade; the issue
and comments stay, with no link to anyone; `named_author_id` becomes NULL
(shown as "Deleted account"). See open decision D5.

---

## 4. Wire contract

New Go module `internal/modules/voice` (issues, comments, votes, reports,
moderation, staff reads) and `internal/platform/media` (image store +
processing). Staff management lives in the existing `admin` module.

**Router**: add `r.Roles(roles ...string) chi.Router` to `httpx.Router`
(requireUser + role in list; the role is fresh from the DB via
CheckSession). Groups used below: **Student** (any signed-in user),
**Authority** = `Roles("authority")`, **Mod** = `Roles("moderator","admin")`,
**Admin** = `Admin()`.

**Feature flag**: every Student-group voice route answers
`403 FEATURE_DISABLED` while `app_config.features.campusVoice` is false,
unless the caller's role is authority/moderator/admin (staff can seed and
test). The app hides the tab when the flag is off.

**Scope**: Student and Authority routes only see issues of the caller's
university (`c.UniversityID`; `UNIVERSITY_REQUIRED` 409 when none). Others →
`ISSUE_NOT_FOUND` (never 403, so existence isn't revealed).

**Bans**: write routes for a banned caller → `403 VOICE_BANNED` with
`details: {until: time|null}`.

### 4.1 Shapes

```jsonc
// IssueCard (feed, similar, my issues)
{
  "id": "uuid", "category": "hostel", "private": false,
  "title": "…", "preview": "first 160 chars of body",
  "status": "open", "visibility": "visible",   // visibility only differs from "visible" for mine/staff
  "meTooCount": 12, "commentCount": 3, "imageCount": 2,
  "thumbnail": "imageId|null",
  "voted": false, "following": true, "mine": false,
  "author": null,                               // or {"name": "Rafi", "verified": true} when named
  "locationLabel": "",
  "createdAt": "time (rounded to 5 min if anonymous)",
  "statusChangedAt": "time"
}
// Issue (detail) = IssueCard + 
{
  "body": "…",
  "images": [{"id": "uuid", "width": 1280, "height": 960}],
  "timeline": [{"from": "open", "to": "acknowledged", "actorKind": "authority",
                "actorTitle": "Proctor Office", "note": "…", "createdAt": "time"}],
  "holdReason": "",          // mine/staff only (otherwise "")
  "removedReason": "",       // mine/staff only
  "reportCount": 0,          // staff only (0 otherwise)
  "can": {"edit": false, "delete": false, "reopen": false,
          "changeStatus": false, "officialReply": false, "moderate": false}
}
// Comment
{
  "id": "uuid", "kind": "student|official",
  "handle": "7KQF",                 // "" for official / named
  "isIssueAuthor": false,
  "mine": false,
  "author": null,                   // named: {"name","verified"}; official: {"name","verified":true}
  "officialTitle": "",              // official replies
  "body": "…",
  "visibility": "visible",          // mine/staff see held/hidden/removed
  "removedReason": "",
  "createdAt": "time (rounded if anonymous)"
}
// Upload
{"id": "uuid", "width": 1280, "height": 960}
// Page
{"items": [...], "nextCursor": "opaque|null"}
```

### 4.2 Student endpoints

| Method | Path | Body / query | Answer | Notes / errors |
|---|---|---|---|---|
| GET | `/issues` | `sort=trending\|new\|solved` (default trending), `category`, `q` (≤100), `cursor` | Page of IssueCard (20) | visible, not private. Trending = `(me_too + 2·comments + 1) / (hours_since_created + 2)^1.5`, last 30 days, not solved/rejected; cursor = opaque offset (max 10 pages). New = keyset on (created_at, id). Solved = status solved, keyset on solved_at |
| GET | `/issues/similar` | `q` (title, ≥8 chars) | `{items: IssueCard[≤5]}` | trigram similarity on title > 0.3, visible, not private, last 180 days |
| GET | `/issues/{id}` | | Issue | private/held/hidden/removed only for mine/staff |
| POST | `/issues` | `{category, title, body, locationLabel?, anonymous: bool (default true), imageIds: [≤4]}` | 201 Issue | 5/day/user. `UPLOAD_NOT_FOUND` (not caller's or attached). Auto-check (§6) may set `visibility: held` |
| PATCH | `/issues/{id}` | `{title?, body?, locationLabel?}` | Issue | author, within 60 min of posting, not removed: `EDIT_WINDOW_CLOSED`. Re-runs auto-check. Sets `edited_at` |
| DELETE | `/issues/{id}` | | 204 | author; soft (`visibility=removed`, `deleted_by_author=true`) |
| PUT / DELETE | `/issues/{id}/vote` | | `{meTooCount, voted}` | idempotent; voting follows. `CANNOT_VOTE_OWN`. 300/hour |
| PUT / DELETE | `/issues/{id}/follow` | | `{following}` | |
| POST | `/issues/{id}/reopen` | `{note (1–500)}` | Issue | author; status solved; within 30 days of `solved_at`: `REOPEN_NOT_ALLOWED`. Timeline `author` |
| GET | `/issues/{id}/comments` | `cursor` | Page of Comment (30, oldest first) | |
| POST | `/issues/{id}/comments` | `{body, anonymous: bool (default true)}` | 201 Comment | 60/day/user; commenting follows; auto-check; not on removed issues: `ISSUE_CLOSED` |
| DELETE | `/issues/{id}/comments/{c}` | | 204 | comment author; soft |
| POST | `/issues/{id}/report` | `{reason, details?}` | 204 | 20/day; `ALREADY_REPORTED`; 5 open reports from different people → issue `hidden` until reviewed |
| POST | `/issues/{id}/comments/{c}/report` | same | 204 | same; 5 → comment `hidden` |
| GET | `/me/issues` | `cursor` | Page of IssueCard | caller's own, all visibilities, newest first |
| POST | `/uploads` | multipart `image` | 201 Upload | ≤ 8 MB; jpeg/png/webp; 20/day. `IMAGE_INVALID`, `IMAGE_TOO_LARGE`. Route body limit 8 MB (the global 64 KB `MaxBody` must allow a per-route override) |
| GET | `/issues/images/{imageId}` | `size=thumb\|full` | image/jpeg | same visibility rules as its issue; `Cache-Control: private, max-age=86400`. Uploads not yet attached: only their uploader (`/uploads/{id}` same shape) |

### 4.3 Authority endpoints (role authority, own university only)

| Method | Path | Body | Answer | Notes |
|---|---|---|---|---|
| POST | `/issues/{id}/status` | `{to, note}` | Issue | allowed: open→acknowledged/in_progress/solved/rejected, acknowledged→in_progress/solved/rejected, in_progress→solved/rejected. `note` required for rejected (`NOTE_REQUIRED`). `STATUS_CHANGE_INVALID` otherwise. Timeline `authority` + staff title |
| POST | `/issues/{id}/official-replies` | `{body (1–2000)}` | 201 Comment (kind official) | |

Authorities also use all Student routes and see their university's private
(safety) issues: `GET /issues?private=true` (authority/mod only; students
→ ignored).

### 4.4 Moderation endpoints (moderator or admin)

| Method | Path | Body / query | Answer | Notes |
|---|---|---|---|---|
| GET | `/moderation/queue` | `kind=held\|reported\|hidden\|private`, `universityId?`, `cursor` | Page of QueueItem | moderators scoped to their university if `staff.university_id` set |
| GET | `/moderation/issues/{id}` | | Issue + `reports: [{reason, details, createdAt}]` + `comments` (all visibilities) | reports carry no reporter |
| POST | `/moderation/issues/{id}` | `{action: approve\|hide\|remove\|restore, reason?}` | Issue | remove needs `reason` (shown to the author). Resolves open reports |
| POST | `/moderation/comments/{id}` | same | Comment | |
| POST | `/moderation/issues/{id}/ban-author` | `{days: 7\|30\|null, reason}` | `{bannedUntil: time\|null}` | resolves author server-side; never returns or logs who |
| POST | `/moderation/comments/{id}/ban-author` | same | same | official comments: `CANNOT_BAN_OFFICIAL` |
| POST | `/moderation/reports/dismiss` | `{targetType, targetId}` | 204 | dismisses open reports on it, restores `hidden`→`visible` if it was auto-hidden |

`QueueItem`: `{targetType, issue: IssueCard, comment: Comment|null,
university: {id, slug, name}, reasons: {"spam": 2, "abuse": 1},
holdReason, createdAt}`.

### 4.5 Admin endpoints (existing `admin` module)

| Method | Path | Body | Answer |
|---|---|---|---|
| GET | `/admin/staff` | | `{items: [{user: {id, email, displayName}, kind, university: UniversityRef\|null, title, createdAt}]}` |
| POST | `/admin/staff` | `{userId, kind, universityId?, title?}` | Staff item. Sets `users.role` (`authority`/`moderator`). `CANNOT_CHANGE_SELF` for own account; admins can't be made staff (`ROLE_CONFLICT`) |
| DELETE | `/admin/staff/{userId}` | | 204, role back to `student` |
| GET | `/admin/stats` | | adds `"voice": {"open": n, "solved": n, "held": n, "reported": n, "issuesLast7Days": n}` |

`POST /admin/auth/code` and `/admin/auth/verify` also accept **moderators**
(the web panel shows them only Moderation). `Admin()` routes stay
admin-only.

### 4.6 Errors (new codes)

`FEATURE_DISABLED` 403 · `VOICE_BANNED` 403 · `ISSUE_NOT_FOUND` 404 ·
`COMMENT_NOT_FOUND` 404 · `UPLOAD_NOT_FOUND` 404 · `IMAGE_INVALID` 422 ·
`IMAGE_TOO_LARGE` 413 · `EDIT_WINDOW_CLOSED` 409 · `REOPEN_NOT_ALLOWED` 409 ·
`ISSUE_CLOSED` 409 · `CANNOT_VOTE_OWN` 409 · `ALREADY_REPORTED` 409 ·
`STATUS_CHANGE_INVALID` 409 · `NOTE_REQUIRED` 422 · `CANNOT_BAN_OFFICIAL`
409 · `ROLE_CONFLICT` 409 · plus existing `VALIDATION_FAILED`,
`UNIVERSITY_REQUIRED`, `TOO_MANY_REQUESTS`.

### 4.7 Pushes (after commit, existing push module, `data: {type, issueId}`)

| Type | To | EN title / body | BN title |
|---|---|---|---|
| `issue_status` | followers (author, voters, commenters, follows) except the actor | "Issue update: In progress" / issue title | "ইস্যু আপডেট: কাজ চলছে" |
| `issue_official` | followers | "Official reply from {title}" / issue title | "{title}-এর অফিসিয়াল উত্তর" |
| `issue_comment` | the issue's author (not if they wrote it); max 1 per issue per 15 min | "New comment on your issue" / issue title | "তোমার ইস্যুতে নতুন মন্তব্য" |
| `issue_moderated` | author | approved: "Your issue is now public"; removed: "Your issue was removed" / reason | "তোমার ইস্যু এখন সবাই দেখছে" / "তোমার ইস্যু সরানো হয়েছে" |

Status names BN: খোলা · দেখা হয়েছে · কাজ চলছে · সমাধান হয়েছে · বাতিল.
Categories BN: একাডেমিক · হল · পরিবহন · সুযোগ-সুবিধা · নিরাপত্তা · প্রশাসন ·
খাবার · আইটি / ওয়াই-ফাই · অন্যান্য.

### 4.8 Audit actions (audit_log, actor = staff user)

`issue.status`, `issue.official_reply`, `moderation.approve|hide|remove|
restore`, `moderation.ban`, `moderation.dismiss`, `staff.add`,
`staff.remove`. `target_type` issue/comment/user(staff only),
`meta` = `{action-specific fields}` — never an author id/email/name.

---

## 5. Roles

- **Authority**: a university official (e.g. "Proctor Office", "Hall
  Provost, Shaheed Minar Hall"). The person signs in to the app normally
  (university or Google account); an admin adds them on `/admin/staff` with
  their university and public title. In the app they see a badge and, on
  their university's issues, **Change status** and **Official reply**.
  Their official replies and status changes show their title and name.
- **Moderator**: Silifton staff (or trusted volunteers). Added on
  `/admin/staff`, optionally scoped to one university. Uses the web panel's
  Moderation pages; in the app they can read everything like an authority
  but can't change status or reply officially.
- **Admin**: everything, plus staff management. Admins moderate too.

---

## 6. Moderation and checks

**Auto text check** (`voice/filter.go`, pure function, unit-tested) on issue
title+body and comments, at post and edit:
- Bangladeshi phone numbers (`(?:\+?88)?01[3-9]\d{8}`, also with spaces /
  dashes, and Bangla digits), emails, URLs other than
  allow-listed university domains, roll/ID-like numbers (≥ 8 digits) →
  `held` with `holdReason: "personal_info"`.
- Word list (`voice/filter_words.txt`, EN + BN + Banglish, one per line,
  matched case-insensitively on word boundaries; maintained by us) → `held`,
  `holdReason: "language"`.
- Everything else → `visible`.
- Unverified students' issues and comments → `held`,
  `holdReason: "unverified"` (decision D1).
Held content is visible to its author marked "Under review"; a moderator
approves or removes it.

**Reports**: reasons `spam, abuse, personal_info, false_info,
inappropriate, other`; one per person per item; 5 distinct open reports →
`hidden` automatically until reviewed.

**States**: `visible` → `held` (auto) / `hidden` (reports or moderator) /
`removed` (moderator or author delete). `restore` returns to `visible`.
Removed content keeps its row for the record; authors see the reason.

**Ban**: `voice_bans` blocks posting, commenting, voting and reporting;
reading still works. Moderators choose 7 / 30 days or permanent.

**Images**: decoded with a size check first (`image.DecodeConfig`, ≤ 8000 ×
8000 px), auto-oriented, re-encoded JPEG (full: long edge ≤ 1280 px at q70;
thumb: ≤ 400 px at q65; ~110 KB + 12 KB for a detailed photo). Re-encoding drops all metadata. The original bytes are
never written to disk. No AI/NSFW service in this release (decision D11);
images can be reported like text.

---

## 7. Photos: storage

**Recommendation (default): local disk on the VPS**, a Docker volume mounted
into the API at `MEDIA_DIR` (`/data/media`), behind an interface
`media.Store { Put(key, bytes) / Open(key) / Delete(key) }`, served **only
through the API** (`GET /issues/images/{id}`) so private and held images
obey the same rules as their issue. Keys are random (`<uuid>-full.jpg`,
`<uuid>-thumb.jpg`). Included in the nightly backup (tar of the volume next
to the DB dump). 165 GB free on the VPS: years of headroom.

**Later option: Cloudflare R2** (credentials exist in the owner's key file;
not read here) implementing the same `Store` interface, still served through
the API (or signed URLs) — switch when traffic or backups make it worth it.

**Flow**: app picks a photo → compresses on the phone (≤ 1280 px JPEG, q80)
→ `POST /uploads` per photo (progress shown) → `POST /issues` with
`imageIds`. Unattached uploads and their files are deleted after 24 h by
the daily ticker. Deleting/removing an issue keeps images for moderation;
deleting the account keeps them with the (now authorless) issue.

New config: `MEDIA_DIR` (dev: `backend/tmp/media`), `VOICE_HMAC_SECRET`.
Compose: `volumes: [media:/data/media]` on the api service.

---

## 8. Admin web additions (apps/web)

- **Login**: moderators may sign in; `getAdmin()` accepts `admin` or
  `moderator`; the sidebar shows Moderation (+ Audit) for moderators,
  everything for admins. Pages a moderator can't use redirect to
  `/admin/moderation`.
- **/admin/moderation**: tabs Held · Reported · Hidden · Safety (private);
  filter by university; list of QueueItems (category, title, excerpt, reasons
  chips, age, university). Empty states.
- **/admin/moderation/issues/[id]**: full issue (images via a server route
  `/admin/media/[imageId]` that proxies `GET /issues/images/{id}` with the
  admin's token), timeline, reports (reason + details + date), all comments
  with their states and per-comment actions. Actions: Approve, Hide, Remove
  (reason, required, shown to the author), Restore, Ban author (7 / 30 /
  permanent + reason, typed confirmation), Dismiss reports. The page states
  plainly: "Authors are anonymous — no one can see who wrote this."
- **/admin/staff**: list; Add (find a user by email using
  `/admin/users?q=`, choose Authority or Moderator, university, public
  title); Remove (confirm).
- **Dashboard**: a Campus Voice card from `stats.voice`.
- **User detail**: unchanged — must not gain any voice data.

---

## 9. App (apps/mobile, packages/*)

- **Navigation**: a 4th tab **Campus** (icon `forum`), between Routine and
  Profile, shown only when `features.campusVoice` is true. Routes:
  `/campus`, `/campus/issues/:id`, `/campus/new` (full screen),
  `/campus/mine`, `/campus/anonymity`.
- **Feed**: segmented Trending · New · Solved; category chips; search
  field; pull to refresh; infinite scroll; FAB "Raise issue"; `CsIssueCard`.
- **Raise issue** (Bloc, 3 steps): 1 category grid (`CsCategoryPicker`;
  Safety explains "private: only moderators and university officials");
  2 title, details, place, photos (`image_picker`, ≤ 4, compressed on the
  phone, uploaded with progress); 3 review: similar issues (tap to open, or
  "Me too" there instead), anonymous toggle (`CsAnonToggle`, default on,
  link to "How anonymity works"), Post. Draft kept on the phone until posted.
- **Issue detail**: images (`CsImageGrid`, full-screen viewer), status chip
  + `CsStatusTimeline`, `CsMeTooButton` (optimistic), Follow, comments
  (handles, "Author", `CsOfficialReply`), comment box with the mask icon and
  anonymous toggle, menu: Report (reason sheet), Edit (60 min) / Delete
  (mine), Reopen (mine, solved). Held/removed states explained to the
  author ("Under review", "Removed: {reason}").
- **Authority** (role authority + same university): "Change status" sheet
  (next statuses only, note; required for Reject) and "Official reply".
- **My issues**: from the feed's app bar and Profile.
- **Push**: `type` starting with `issue_` opens `/campus/issues/{issueId}`.
- **Offline**: last feed page per sort and opened issues cached; posting and
  voting need a connection (clear message); drafts survive.
- **Images**: loaded with the auth header (`Authorization: Bearer`).
- **l10n**: all strings EN + BN (Bangla written, not translated word by
  word); handles "Student 7KQF" / "শিক্ষার্থী 7KQF".
- `campus_core`: `Issue`, `IssueCard`, `IssueComment`, `IssueStatus`,
  `IssueCategory` (unknown → other), `VoiceRepository` interface;
  `campus_data`: `ApiVoiceRepository`; `campus_ui`: the R2 components in
  DESIGN_SYSTEM.md §5.

---

## 10. Test plan

**Go e2e (`internal/app/voice_*_e2e_test.go`)** — the release gate:
1. *Anonymity sweep*: student A posts an anonymous issue with a comment,
   votes, follows, reports. As student B, an authority, a moderator and an
   admin, call **every** read endpoint (feed, similar, detail, comments,
   my issues, moderation queue + item, admin users list + A's detail, admin
   audit, admin stats) and assert the raw JSON contains neither A's user id,
   email, nor display name. Repeat after a ban-author and after A deletes
   the account.
2. Named post shows the name only (no id/email).
3. Handles: same person same issue = same handle; across issues differ;
   `isIssueAuthor` true only for the author's comments.
4. `createdAt` rounded to 5 minutes for anonymous, exact for named.
5. Private (safety) issues: not in feed or detail for other students or
   other universities' authorities; visible to own-university authority,
   moderators, author.
6. Status machine and roles; reopen window; edit window; counts.
7. Auto-check holds phone numbers (Latin and Bangla digits), emails, word
   list, unverified authors; approve/remove flows and pushes.
8. Reports: duplicate refused; 5 → hidden; dismiss restores.
9. Ban: banned writes refused with `VOICE_BANNED`; reading works; ban
   expires.
10. Images: EXIF with GPS in → no `Exif` marker in stored files; oversized
    and non-images refused; unattached cleanup; private image access rules.
11. Feature flag off → `FEATURE_DISABLED` for students, staff unaffected.
12. Audit meta never contains author ids (asserted in test 1).

**Unit**: filter rules (EN/BN/Banglish samples), handle derivation,
trending order, cursor encode/decode.
**App**: core models/JSON (unknown values), feed/post/detail widget tests
with fakes, optimistic vote rollback, Bangla rendering, screenshot harness.
**Web**: lint/type/build; headless run of moderation and staff flows
against the local API.

---

## 11. Open decisions (implementers proceed with the default)

| # | Decision | Default |
|---|---|---|
| D1 | Can not-verified (Gmail) students post? | Yes, but their issues and comments are **held for review**; reading, me too and reporting are free |
| D2 | Photo storage | Local disk volume on the VPS behind the API (R2 later, same interface) |
| D3 | Who can reopen a solved issue | Author only, within 30 days |
| D4 | Posting with my name | Allowed; anonymous is the default |
| D5 | Account deletion | Issues and comments stay without any link to the person; named ones show "Deleted account". Update the privacy policy |
| D6 | Who sees Safety reports | Author, moderators, that university's authorities |
| D7 | Auto-hide after reports | 5 open reports from different people |
| D8 | Launch gating | One global `campusVoice` flag, turned on after moderators and at least one authority exist |
| D9 | Where authorities work | In the app (R2); web dashboard in R4 |
| D10 | Moderators | Silifton staff, all universities, web panel |
| D11 | Image moderation | ~~No AI service~~ Decided 2026-10-28: an NSFW model on our own server (§14), plus reports and manual review |
| D12 | Limits | 5 issues/day, 60 comments/day, 300 votes/hour, 20 reports/day, 20 uploads/day, 4 photos/issue, 8 MB/photo |
| D13 | Edit window | 60 minutes for issues; comments can't be edited, only deleted |
| D14 | Push audience | Author + voters + commenters + explicit followers; nothing on new issues |

---

## 12. Work breakdown (3 parallel tracks)

| Track | Owns (only these paths) | Doesn't touch |
|---|---|---|
| **A · API** | `backend/migrations/00500–00530*`, `backend/internal/modules/voice/**`, `backend/internal/platform/media/**`, `backend/internal/platform/httpx/router.go` (`Roles`) and per-route body limit, `backend/internal/modules/admin/**` (staff, stats, auth accepting moderators), `backend/internal/modules/accounts/**` (only the admin-code role check), `backend/internal/app/**` (wiring + e2e), `backend/internal/platform/config/**`, `backend/deploy/compose.yaml` (media volume), `backend/deploy/env.example` | apps/, packages/ |
| **B · App** | `packages/campus_core/lib/src/voice/**`, `packages/campus_data/lib/src/voice/**`, `packages/campus_ui/lib/src/components/voice/**` (+ exports), `packages/campus_l10n/**` (new keys only), `apps/mobile/lib/features/voice/**`, `apps/mobile/lib/app/router.dart` + `app.dart` + `di.dart` (tab, routes, push routing), `apps/mobile/test/voice*`, `apps/mobile/pubspec.yaml` (`image_picker`) | backend/, apps/web |
| **C · Web** | `apps/web/src/app/admin/(panel)/moderation/**`, `.../staff/**`, `apps/web/src/app/admin/media/**`, `apps/web/src/lib/admin/**` (types, errors, role check), `apps/web/src/components/admin/**` (nav, new pieces), dashboard card in `apps/web/src/app/admin/(panel)/page.tsx` | backend/, apps/mobile, packages/ |

Each track builds against this contract with fakes/mocks first, then runs
against the local API when Track A lands each milestone.

**Milestones**

1. **M1 — core loop**: A: migrations 00500/00510, issues + feed + detail +
   vote/follow + comments + my issues, flag gating, anonymity sweep test
   (parts 1–4). B: models, repository, Campus tab, feed, detail, raise
   issue without photos, comments, me too. C: staff page, login for
   moderators, nav by role.
2. **M2 — safety**: A: 00520/00530, uploads + images, auto-check, reports,
   moderation endpoints, bans, private safety issues, staff endpoints,
   authority status + official replies; tests 5–12. B: photos, report sheet,
   held/removed states, authority actions, how-anonymity screen. C:
   moderation queue + item pages, media proxy, dashboard card.
3. **M3 — ship**: pushes, push routing, Bangla review, screenshots, privacy
   policy + "How anonymity works" copy review, deploy with the flag off,
   add moderators and one authority, turn the flag on for the beta.

---

## 13. Changes during build (Track A, 2026-10-28)

Small fixes found while building the API; the app and web follow these.

1. **Deleted named authors.** `issues.named` / `comments.named` columns were
   added. A named post whose account was deleted returns
   `"author": {"name": null, "verified": false}` (render "Deleted account");
   anonymous content still has `"author": null`.
2. **Official replies up to 2000 characters**: `comments.body` allows 2000
   for `kind = official`, 1000 for students (the §3 CHECK said 1000 for all).
3. **More hold reasons**: besides `personal_info`, `language` and
   `unverified`, `holdReason` can be `reports` (auto-hidden after 5 reports)
   or `moderator` (hidden by a moderator). `POST /moderation/reports/dismiss`
   brings back only items hidden by `reports`.
4. **Moderator/admin feed**: `GET /issues?universityId=<uuid>` lets moderators
   and admins pick the university (default: their own; a moderator scoped to
   one university gets `403 FORBIDDEN` for others).
5. **Role errors**: calling an Authority or Mod route without the role answers
   `403 FORBIDDEN` (e.g. a student on `/issues/{id}/status`, an authority on
   `/moderation/*`). Moderators signing in to the panel get `NOT_ADMIN` on
   admin-only routes, as before.
6. **Cursors**: an invalid or foreign cursor answers `400 BAD_CURSOR`.
7. **Moderation item**: `reports[]` entries are
   `{targetType, targetId, reason, details, state, createdAt}`; report and
   queue `createdAt` are rounded to 5 minutes like anonymous content.
8. **Photos**: `GET /uploads/{id}?size=thumb|full` (uploader only, before the
   issue is posted). Upload errors: `IMAGE_INVALID` (422), `IMAGE_TOO_LARGE`
   (413), `VALIDATION_FAILED` (no `image` part), `400` (not multipart).
9. **Sweep test (§10.1)**: the admin's own user pages necessarily show the
   person; the gate there is that `/admin/users*` never shows their voice
   activity (issue ids, titles, comment ids). Every voice, moderation, audit
   and stats read is checked for the author's id, email and name.
10. **Production config**: `VOICE_HMAC_SECRET` is **required** in production
    (the API refuses to start without a strong one) — add it to the server's
    `.env` before deploying this. `MEDIA_DIR=/data/media` with the new
    `media` volume (compose); the API image pre-creates `/data/media` owned
    by the nonroot user so a fresh volume is writable. `backup.sh` also tars
    the `varsitykotha_media` volume (via a throwaway alpine container).

## 14. Photo check (2026-10-28)

Every photo is scored by an NSFW image classifier **running on our own
server** before anyone can see it. Photos never leave our systems for this
(no third-party AI service).

**Model:** [AdamCodd/vit-base-nsfw-detector](https://huggingface.co/AdamCodd/vit-base-nsfw-detector)
(Apache-2.0), ViT-base/16 at 384 px fine-tuned on ~25,000 photos and drawings,
two classes (sfw, nsfw). Reported accuracy 96.5 %, AUC 0.995 on its
evaluation set; weaker on AI-generated images (86 %). It is deliberately
strict: "sexy" photos (much skin, cleavage) count as NSFW. We use its
uint8-quantized ONNX export (88 MB), pinned to revision `8587de9` and
checked by sha256 when the image is built.

**Service:** `backend/nsfw` (Python, onnxruntime + Pillow + NumPy, no
torch), compose service `nsfw` on the internal network only (no published
port), `mem_limit 600m`, non-root, model baked in (no network at runtime).
`POST /classify` (image bytes) → `{"sfw", "nsfw", "model"}`; `GET /health`.
It keeps and logs nothing about the photos. Measured locally (4 vCPU Docker
VM): ~205 ms per photo, ~240 MB memory.

**Flow** (`voice/photo_check.go`): after re-encoding, the API sends the
thumbnail (≤ 400 px) to the service, before anything is stored.

| Score (nsfw) | Result |
|---|---|
| ≥ `NSFW_REJECT` (0.98) | Refused: `422 PHOTO_NOT_ALLOWED`, not stored |
| ≥ `NSFW_HOLD` (0.70) | Stored, flagged; the issue it's posted with is **held** (`holdReason: photo_check`) until a moderator approves it |
| lower | Fine |
| service down / not configured, production | Stored, flagged, issue held (`photo_check_unavailable`): never let through unchecked |
| service down / not configured, development | Skipped (log line) |

Scores are kept on `uploads` / `issue_images` (`nsfw_score`, `flagged`,
migration 00540) and shown only to moderators: `GET
/moderation/issues/{id}` → `photoChecks: [{imageId, score, flagged}]`. The
admin panel blurs flagged photos ("Flagged by the photo check (score
0.82)") until the moderator chooses to look. Students never see scores.
Logs carry scores only, never photos or who sent them.

**Env:** `NSFW_URL` (compose sets `http://nsfw:8000` for the API),
`NSFW_REJECT` (default 0.98), `NSFW_HOLD` (default 0.70).

Text stays on the word list (§6), not AI.

