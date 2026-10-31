# Visit other campuses (R2.7): build spec

Students look around other universities: a university's profile and what
its students are posting. Extends docs/CAMPUS_VOICE.md and
docs/CAMPUS_SOCIAL.md; their rules apply unless this file says otherwise.

Decided with the owner (2026-10-31): **every post, question and poll** of a
university is readable by students of all universities (read-only);
visitors may **react** (and report), nothing else. **Issues** (and so safety
reports) never leave their university. An author can keep a post inside
their university with **"Only my university"** (default off).

---

## 1. Rules

- A **visitor** is a signed-in student looking at content of a university
  that isn't theirs (moderators and admins keep their own rules).
- Visitors see a university's content when: `kind <> 'issue'`, `visibility =
  'visible'`, `NOT private`, `NOT campus_only`. Anything else answers
  `ISSUE_NOT_FOUND` as today.
- Visitors may: read cards, details and comments; **react** (PUT/DELETE
  vote); **report** posts and comments. Everything else (comment, reply,
  like a comment, poll vote, follow, edit…) answers **403
  `VISITOR_READ_ONLY`**.
- Polls: visitors see the results (option `votes` are shown to visitors,
  since they can't vote).
- Anonymity: unchanged. Handles stay per post; visitors' reactions are
  counts like everyone else's.
- Feature flag `features.visitCampus` (set true by the migration): when
  false, visitor reads answer `ISSUE_NOT_FOUND` / the university routes
  answer 403 `FEATURE_DISABLED` (staff unaffected), and the app hides the
  feature.
- Old apps: nothing changes for them (they never send another
  `universityId`).

---

## 2. Data model: `00680_campus_visits.sql`

```sql
-- +goose Up
ALTER TABLE issues ADD COLUMN campus_only boolean NOT NULL DEFAULT false;
UPDATE app_config SET value = jsonb_set(value, '{visitCampus}', 'true') WHERE key = 'features';
-- +goose Down
UPDATE app_config SET value = value - 'visitCampus' WHERE key = 'features';
ALTER TABLE issues DROP COLUMN campus_only;
```

Issues are always campus-only in effect (the queries check `kind <>
'issue'`); the column is for posts, questions and polls.

---

## 3. Wire contract

### 3.1 Changed shapes

`IssueCard` (and `Issue`) gains:

```jsonc
{
  "campusOnly": false,   // the author kept it inside their university (mine/staff/same university see it)
  "visitor": false       // true when the caller is visiting (another university's post)
}
```

For a visitor: `can` is all false; `mine`, `following` are false; poll
option `votes` are always present.

`POST /issues` body gains `campusOnly: bool` (default false; ignored for
issues). `PATCH` can't change it.

### 3.2 Feed of another university

`GET /issues?universityId=<uuid>` now also works for students: when it isn't
their university, visitor mode — `kinds` as before minus `issue` (so
`kinds=issue` answers an empty page), `private` and `sort=solved` give an
empty page, `q` and `category` work. Cards have `visitor: true`.

### 3.3 Universities to visit (module `universities` or `voice`, your call)

| Method | Path | Query | Answer |
|---|---|---|---|
| GET | `/campuses` | `q` (≤ 60), `cursor` | `{items: [CampusSummary], nextCursor}` (30): every active, non-demo university **except the caller's own**; most active first (`posts7d` desc, then `students` desc, then name); `q` matches name, name_bn, slug, city (ILIKE) |
| GET | `/campuses/{slug}` | | `CampusProfile` (any active non-demo university, including the caller's own; `mine: true` then); unknown → 404 `UNIVERSITY_NOT_FOUND` |

```jsonc
// CampusSummary
{"id": "uuid", "slug": "du", "name": "University of Dhaka", "nameBn": "ঢাকা বিশ্ববিদ্যালয়",
 "city": "Dhaka", "kind": "public", "students": 1240, "posts7d": 37}
// CampusProfile = CampusSummary +
{"website": "https://du.ac.bd", "classGroups": 86, "busRoutes": 12, "mine": false}
```

- `students`: users whose university is this one (not deleted).
- `posts7d`: posts, questions and polls (not issues), visible, not private,
  not campus-only, created in the last 7 days.
- `classGroups`: class groups of the university; `busRoutes`: its bus
  routes.

### 3.4 Visitor errors

`VISITOR_READ_ONLY` 403 on: `POST /issues/{id}/comments`, `PUT|DELETE
/issues/{id}/comments/{c}/like`, `POST /issues/{id}/poll-vote`, `PUT|DELETE
/issues/{id}/follow`, `PATCH|DELETE /issues/{id}`, `POST /issues/{id}/reopen`
(and the authority/moderation routes keep their own rules). Allowed:
`GET /issues/{id}`, `GET /issues/{id}/comments`, `PUT|DELETE
/issues/{id}/vote`, `POST /issues/{id}/report`, `POST
/issues/{id}/comments/{c}/report`.

Visitors' reactions send no push (as for everyone).

---

## 4. App

- Explore: "Visit other campuses" leaves *Coming soon* (shown while
  `features.visitCampus`).
- **Campuses** (`/campus/visit`): search + the most active universities
  (name, city, public/private, students, posts this week).
- **A campus** (`/campus/u/:slug`): header (name, Bangla name, city,
  public/private, website link), stats (students, class groups, bus
  routes, posts this week), tabs For you · Latest · Q&A, topic chips; the
  same post cards: React works; Comment opens the post (comments readable,
  no comment box, a "You're visiting {university}" note); Share works;
  polls show results.
- Composer: an **"Only my university"** switch for posts, questions and
  polls (off: "Students of all universities can see this").
- "How anonymity works": add that posts, questions and polls can be read
  by students of other universities; issues stay inside.
