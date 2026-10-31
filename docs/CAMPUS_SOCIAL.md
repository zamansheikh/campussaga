# Campus: from issues to campus social (R2.5): build spec

Campus Voice was an issue tracker. Students also want a place to talk:
share news and photos, ask the campus a question, run a poll. This spec
adds three post kinds next to issues, emoji reactions, replies and likes
on comments, and share links. It extends docs/CAMPUS_VOICE.md: every
rule there (anonymity, moderation, photo check, bans, feature flag,
university scope) applies to the new kinds unless this file says
otherwise.

Decided with the owner (2026-10-31): kinds **Post, Ask, Poll** (issues
stay); **emoji reactions** (tap = ❤️, hold = pick ❤️ 😂 😮 😢 👏); issues
keep **Me too**.

---

## 1. Post kinds

| Kind | What it is | Title | Body | Extras |
|---|---|---|---|---|
| `issue` | A campus problem (unchanged) | 8–120, required | 20–3000 | status timeline, official replies, Me too, similar issues, reopen |
| `post` | Share anything: text and/or photos | none (`""`) | 0–3000; text **or** at least one photo | reactions |
| `question` | Ask the campus; comments are answers | none | 8–3000 (the question) | reactions |
| `poll` | A question with 2–4 options | none | 4–300 (the question) | 2–4 options (1–80 chars, unique, case-insensitive), closes after 1, 3 or 7 days (default 3); reactions |

All kinds: up to 4 photos (same upload flow and photo check), optional
place label (≤ 80), anonymous by default or with my name, a **category**.

### Categories (topics)

Issue categories stay as they are: `academic, hostel, transport,
facilities, safety, administration, food, it, other`.

Post, question and poll categories: every issue category **except
`safety`**, plus `general, event, lost_found, buy_sell, fun`. Default
`general`. Safety (private) stays issue-only.

BN: general সাধারণ · event ইভেন্ট · lost_found হারানো-পাওয়া ·
buy_sell কেনাবেচা · fun মজা.

---

## 2. Data model: migration `00640_campus_social.sql`

```sql
-- +goose Up
ALTER TABLE issues ADD COLUMN kind text NOT NULL DEFAULT 'issue'
  CHECK (kind IN ('issue','post','question','poll'));
ALTER TABLE issues ADD COLUMN poll_closes_at timestamptz;   -- polls only

ALTER TABLE issues DROP CONSTRAINT issues_title_check;
ALTER TABLE issues DROP CONSTRAINT issues_body_check;
ALTER TABLE issues DROP CONSTRAINT issues_category_check;
ALTER TABLE issues ADD CONSTRAINT issues_text_check CHECK (
  CASE WHEN kind = 'issue'
       THEN char_length(title) BETWEEN 8 AND 120 AND char_length(body) BETWEEN 20 AND 3000
       ELSE title = '' AND char_length(body) <= 3000 END);
ALTER TABLE issues ADD CONSTRAINT issues_category_check CHECK (category IN (
  'academic','hostel','transport','facilities','safety','administration','food','it','other',
  'general','event','lost_found','buy_sell','fun'));
ALTER TABLE issues ADD CONSTRAINT issues_kind_category_check CHECK (
  CASE WHEN kind = 'issue'
       THEN category IN ('academic','hostel','transport','facilities','safety','administration','food','it','other')
       ELSE category <> 'safety' END);
ALTER TABLE issues ADD CONSTRAINT issues_poll_check CHECK ((kind = 'poll') = (poll_closes_at IS NOT NULL));
CREATE INDEX issues_kind_feed_idx ON issues (university_id, kind, visibility, private, created_at DESC, id DESC);

-- A reaction per person per post; issues use 'me_too' only.
ALTER TABLE issue_votes ADD COLUMN reaction text NOT NULL DEFAULT 'me_too'
  CHECK (reaction IN ('me_too','like','haha','wow','sad','clap'));

CREATE TABLE poll_options (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id   uuid NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
  position   smallint NOT NULL CHECK (position BETWEEN 0 AND 3),
  label      text NOT NULL CHECK (char_length(label) BETWEEN 1 AND 80),
  vote_count int  NOT NULL DEFAULT 0,
  UNIQUE (issue_id, position)
);
CREATE TABLE poll_votes (          -- counts only ever leave the server
  issue_id   uuid NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  option_id  uuid NOT NULL REFERENCES poll_options (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (issue_id, user_id)
);

-- One level of replies; likes on comments.
ALTER TABLE comments ADD COLUMN parent_id uuid REFERENCES comments (id) ON DELETE CASCADE;
ALTER TABLE comments ADD COLUMN like_count int NOT NULL DEFAULT 0;
CREATE INDEX comments_parent_idx ON comments (parent_id) WHERE parent_id IS NOT NULL;
CREATE TABLE comment_likes (
  comment_id uuid NOT NULL REFERENCES comments (id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (comment_id, user_id)
);
```

`me_too_count` becomes **the total number of reactions** on any kind (for
issues it is still the Me too count). `vote_count` and `like_count` are
kept by the service in the same transaction, like the other counters.
Poll votes, reactions and comment likes are anonymous in the same way as
votes (CAMPUS_VOICE.md §2.1): no endpoint returns who.

---

## 3. Wire contract changes

### 3.1 Shapes

`IssueCard` gains (all present on every card, every kind):

```jsonc
{
  "kind": "post",                       // issue | post | question | poll
  "reactions": {"like": 12, "haha": 3}, // count per reaction, zero ones left out; issues: {"me_too": n}
  "myReaction": "haha",                 // the caller's own, or null
  "images": [{"id": "uuid", "width": 1280, "height": 960}],  // all photos (≤ 4), in order
  "previewCut": false,                  // true when "preview" is shorter than the body
  "poll": null                          // polls: see below
}
```

- `preview` is the first **160** characters for issues (as before) and the
  first **500** for the other kinds (`…` appended when cut; `previewCut`
  says so).
- `meTooCount` = total reactions; `voted` = the caller reacted (any
  reaction). Old apps keep working.
- `title` is `""` for post, question and poll.
- `status` is `"open"` for the new kinds and never changes.

`poll`:

```jsonc
{
  "options": [{"id": "uuid", "label": "Yes", "votes": 41}],  // in order; votes null while hidden
  "totalVotes": 63,
  "myVote": "uuid|null",
  "closesAt": "time",
  "closed": false
}
```

Option `votes` are **null** until the caller has voted, unless the poll is
the caller's own or is closed. `totalVotes` is always shown.

`Issue` (detail) = card + the same fields as before.

`Comment` gains:

```jsonc
{
  "parentId": "uuid|null",   // set on replies
  "likeCount": 4,
  "liked": false
}
```

### 3.2 Endpoints

| Method | Path | Change |
|---|---|---|
| GET | `/issues` | New `kinds`: comma list of kinds, or `all`. **Absent = `issue` only** (apps before this release see only issues). `sort=solved` returns issues only, whatever `kinds` says. `category` accepts the new categories. Trending covers every requested kind (non-issues are always `open`, so they qualify for 30 days) |
| GET | `/me/issues` | Same `kinds` param, same default |
| POST | `/issues` | Body gains `kind` (default `issue`), `pollOptions: [string]` (polls, 2–4), `pollDays: 1\|3\|7` (polls, default 3). `category` is required for issues and defaults to `general` for the others. Rules from §1, errors `VALIDATION_FAILED` with the field. Limits: route limit raised to **25 a day** for all kinds together; inside it, still **5 issues a day** (counted for the caller in the service; `TOO_MANY_REQUESTS` as before) |
| PATCH | `/issues/{id}` | Non-issues: `title` must stay `""` (ignored if sent empty), body rules of the kind. Poll options can't be edited |
| PUT | `/issues/{id}/vote` | Optional JSON body `{"reaction": "like\|haha\|wow\|sad\|clap"}`. Issues: always `me_too` (any `reaction` sent is ignored); `CANNOT_VOTE_OWN` stays for issues only, you can react to your own post. Others: default `like`; a second PUT with another reaction **changes** it (count unchanged). Empty body must work (old apps). Answer `{meTooCount, voted, reactions, myReaction}` |
| DELETE | `/issues/{id}/vote` | Removes the caller's reaction. Same answer |
| POST | `/issues/{id}/poll-vote` | `{"optionId": "uuid"}` → the card's `poll` object. One vote per person, can't be changed. `POLL_CLOSED` 409 (closed or not a poll), `ALREADY_VOTED` 409, unknown option → `VALIDATION_FAILED` (`optionId`). Banned → `VOICE_BANNED`. Uses the vote rate limit |
| POST | `/issues/{id}/comments` | Body gains `parentId` (optional). The parent must be a **visible** comment of the same issue, else `COMMENT_NOT_FOUND`. Replying to a reply attaches to that reply's parent (one level) |
| PUT / DELETE | `/issues/{id}/comments/{c}/like` | `{likeCount, liked}`. Visible comments only (`COMMENT_NOT_FOUND`). Liking your own comment is allowed. Vote rate limit; bans apply |
| POST | `/issues/{id}/status`, `/issues/{id}/official-replies`, `/issues/{id}/reopen` | Issues only: other kinds → 409 `NOT_AN_ISSUE`. `can.changeStatus`, `can.officialReply`, `can.reopen` are false for them |
| GET | `/issues/similar` | Issues only (unchanged) |

New error codes: `POLL_CLOSED` 409, `ALREADY_VOTED` 409, `NOT_AN_ISSUE` 409.

### 3.3 Pushes

| Type | To | EN title / body | BN title |
|---|---|---|---|
| `issue_comment` (existing) | the author of the post | issue: "New comment on your issue"; post/poll: "New comment on your post"; question: "New answer to your question" / the issue title or the first 80 chars of the body | "তোমার ইস্যুতে নতুন মন্তব্য" / "তোমার পোস্টে নতুন মন্তব্য" / "তোমার প্রশ্নের নতুন উত্তর" |
| `issue_reply` (new) | the author of the parent comment (not when they wrote the reply, not officials' own) ; max 1 per parent per 15 min | "New reply to your comment" / first 80 chars of the reply | "তোমার মন্তব্যে নতুন উত্তর" |

Reactions, likes and poll votes send nothing. `data: {type, issueId}` as
before (the app opens `/campus/issues/{id}` for any `issue_*` type).

Any push that quotes a post uses the title for issues and the body (first
80 chars) for the other kinds.

### 3.4 Moderation and admin

- `QueueItem.issue` and `/moderation/issues/{id}` carry the new card fields
  (`kind`, `poll`, `images`). The panel shows a kind badge, the body when
  the title is empty, and poll options with counts.
- The auto text check runs on the poll options too (`checkText(title, body,
  place, options...)`).
- Reports, hide/remove/restore, ban-author: unchanged for every kind.

### 3.5 Share links

`https://varsitykotha.com/c/{issueId}` opens the post in the app (Android
App Link, path prefix `/c/`). On the web the page shows only "This post
is on VarsityKotha" with Open in app / Get it on Google Play: **no post
content** (posts are private to a university). The app shares
"{first 100 chars} — {link}".

---

## 4. App

- **Feed** (Campus tab): app bar *Campus* with search and My posts. A
  "What's happening at {university}?" prompt on top (avatar + quick
  buttons Photo · Ask · Poll · Issue). Tabs **For you** (trending, all
  kinds) · **Latest** (new, all kinds) · **Ask** (questions, new) ·
  **Issues** (issues, with Open / Solved). Topic chips under the tabs.
  FAB "+" opens the composer.
- **Post card** (one component for every kind): header with avatar
  (anonymous: an emoji face on a colour, derived from the post id, so the
  same anonymous author looks the same on that post and in its comments),
  name or "Anonymous", time, topic and place, menu; issue title +
  status chip for issues; text with "See more"; photos (1 large, 2 side
  by side, 3–4 grid); poll; then a summary row (top 3 reaction emojis +
  count · N comments) and an **action bar of three equal buttons**:
  React (or Me too) · Comment (Answer for questions) · Share.
- **Detail**: the same header, full text, photos, poll, the same summary
  row and action bar, then for issues the status timeline and official
  actions; then comments as threads: avatar, name/handle, text, "Like ·
  Reply · time", replies indented with "View N replies". The comment box
  shows "Replying to …" with a cancel button.
- **Composer**: one screen. Kind chips (Post · Ask · Poll · Issue),
  "Posting as Anonymous ▾" switch, big text field, photos row, topic
  chips, place; poll options (2–4) and duration; issue keeps title,
  category, place and similar issues.
- Reactions: tap the React button = ❤️ (tap again removes); long-press
  opens the picker (❤️ 😂 😮 😢 👏) with a small haptic. Optimistic, rolled
  back on error.
- Copy: "Me too" stays for issues; "like" is fine for posts now (this
  replaces the DESIGN_SYSTEM.md §7 rule for non-issues).

---

## 5. Changes during build (2026-10-31)

API (commit `feat(api): campus posts, polls, reactions and replies`):

1. Poll option `votes` are also shown to moderators and admins (the panel
   needs the counts).
2. `reaction: "me_too"` sent for a non-issue is read as `like`; any other
   value outside `like|haha|wow|sad|clap` is `VALIDATION_FAILED`.
3. Create: a non-empty `title` on a non-issue, or `pollOptions` / `pollDays`
   on a non-poll, is `VALIDATION_FAILED`. PATCH: an empty `title` on a
   non-issue is ignored; `pollOptions` is an unknown field (400).
4. `issue_reply` goes to the author of the exact comment replied to (the
   stored `parentId` is the top comment of the thread); none for official
   replies; a post author who gets `issue_reply` doesn't also get
   `issue_comment` for it.
5. A vote on a closed poll or on something that isn't a poll:
   `POLL_CLOSED`. Liking a comment on a removed post: `ISSUE_CLOSED`.
6. Admin dashboard counts (open, solved, issues in the last 7 days) count
   `kind = 'issue'` only.

App:

1. The tab for questions is **Q&A** (BN প্রশ্নোত্তর); "Ask" is the composer
   kind.
2. The opened post's bell (Follow) moved to the app bar, so every post has
   the same three buttons (React · Comment · Share).
3. Anonymous faces: an animal on a soft colour, picked from the post id for
   its author (also on their comments, marked Author) and from the handle
   for commenters. They say nothing about the person.

