# Feedback: bug reports and feature requests

Students send a bug report, a feature request or other feedback from the
app, optionally with screenshots. The team sees it in the admin panel, sets
a status and replies. The student gets a push and can answer back, so each
piece of feedback is a short conversation.

## 1. Data (migration `00730_feedback.sql`)

```
feedback
  id uuid pk, user_id → users set null, university_id null → universities,
  kind text CHECK in ('bug','idea','other'),
  message text CHECK 10..2000 chars,
  status text CHECK in ('new','seen','planned','in_progress','done','wont_do') default 'new',
  app_version text ≤ 20, build int, platform text ≤ 20,
  device text ≤ 80, os text ≤ 40, locale text ≤ 10,
  created_at, updated_at, last_message_at,
  user_unread int default 0,    -- team messages the student hasn't opened
  team_unread int default 0     -- student messages the team hasn't opened

feedback_images
  feedback_id → feedback cascade, position smallint (0..2), key/upload ref.
  Reuse the Campus image upload pipeline (POST /uploads, the nudity check,
  thumbs); at most 3.

feedback_messages
  id, feedback_id → feedback cascade, author_id null → users set null,
  from_team bool, body text 1..2000, created_at
```

## 2. API (prefix `/api/v1`)

### Students
| Method | Path | Notes |
|---|---|---|
| POST | `/feedback` | `{kind, message, images?: [uploadId ≤3], appVersion, build, platform, device, os, locale}` → `201 Feedback`. At most 10 a day per student (`429 FEEDBACK_LIMIT`). |
| GET | `/me/feedback` | `{items: [Feedback]}`, newest activity first. |
| GET | `/feedback/{id}` | `{feedback: Feedback, messages: [Message]}` (own only, else `404 FEEDBACK_NOT_FOUND`). Opening it sets `user_unread` to 0. |
| POST | `/feedback/{id}/messages` | `{body}` → Message. Raises `team_unread`. A `done` or `wont_do` item stays closed, but the team still sees the reply. |

`Feedback = {id, kind, message, status, images: [{url, thumbUrl}], createdAt, lastMessageAt, unread}`.
`Message = {id, fromTeam, body, createdAt}`. For students, team messages
show no staff name, only "VarsityKotha team".

The push when the team replies or changes the status:
- type `feedback_reply`, data `{feedbackId}`;
- EN "VarsityKotha team replied" / BN "ভার্সিটি কথা টিম উত্তর দিয়েছে";
- the body is the first 120 characters of the reply, or the new status in
  words.

### Admin
| Method | Path | Notes |
|---|---|---|
| GET | `/admin/feedback` | Paged. `?status=` (`open` = new, seen, planned, in_progress; `closed` = done, wont_do; or a single status), `?kind=`, `?q=` (message text, user email). Item: Feedback plus `{user: {id,name,email,university}, teamUnread, device, os, appVersion, build, platform}`. |
| GET | `/admin/feedback/{id}` | Item plus `messages` (team messages carry `author: {id,name}`). Opening it sets `team_unread` to 0, and a `new` item becomes `seen`. |
| POST | `/admin/feedback/{id}/messages` | `{body}` replies as the team, raises `user_unread` and pushes. Audit `feedback.reply`. |
| PATCH | `/admin/feedback/{id}` | `{status}` pushes the student. Audit `feedback.status`. |

`/admin/inbox` adds `feedbackNew` (items that are `new` or have
`team_unread > 0`). `/admin/stats` adds `feedback: {new, open,
last7Days}`.

## 3. App
- **Profile → "Help & feedback":**
  - **"Send feedback"** form:
    - kind as `ChoiceChip`s (Bug / Idea / Other);
    - message;
    - up to 3 screenshots, using the same picker as Campus posts;
    - a quiet line showing what's attached automatically (app version,
      device, Android version);
    - Send.
  - **"My feedback"** list:
    - status as a `CsPill` (New, Seen, Planned, In progress, Done, Won't do);
    - an unread dot.
  - **Thread screen:**
    - the original message and images;
    - the messages ("VarsityKotha team" on the team side);
    - a reply box.
- **Push:** `feedback_reply` opens the thread.
- **Strings:** English and Bangla.

## 4. Admin panel
- **"Feedback" nav item**, with a count of new or unread items.
- **List:**
  - Open / Closed / All tabs;
  - kind filter;
  - search;
  - rows show kind badge, status, an excerpt, the student, university, app
    version, time, and an unread dot.
- **Detail:**
  - the message, images (click to enlarge), and device and app info;
  - the conversation;
  - a reply box;
  - a status selector.
- **"Needs attention":** a Feedback section with the count, linking to the list.
- **Dashboard:** a small Feedback card.
- **Audit log:** labels for `feedback.reply` and `feedback.status`.

## 5. As implemented (backend notes)
- Image `url` / `thumbUrl` are paths relative to the API prefix
  (`/feedback/{id}/images/{imageId}` and `?size=thumb`); the panel uses
  `/admin/feedback/{id}/images/{imageId}`. Both need the bearer token.
- Screenshots are uploaded with `POST /uploads` (so Campus Voice must be on
  for students, and the nudity check runs); flagged ones are kept for the
  team to see.
- `POST /feedback/{id}/messages` returns 201 `Message`; the admin reply
  returns 201 with an `author: {id,name}` block. Admin items also carry
  `locale`. `PATCH /admin/feedback/{id}` returns the admin item.
- The admin list `?status=` also accepts `all`; the default is `all`.
- Opening a thread (`GET /feedback/{id}`) clears `unread`; opening or
  replying in the panel clears `teamUnread` and turns `new` into `seen`.
- The push body for a status change is `Status: Planned` / `অবস্থা: পরিকল্পনায় আছে`.
