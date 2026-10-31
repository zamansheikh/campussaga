# Growth: invites, badges, profiles and prize campaigns

Help VarsityKotha spread from student to student. Rewards go to bringing
**real, active students**, never to installs, ratings or reviews.

- **Invites:** every student has a personal invite link. An invite counts
  ("qualified") only when the friend is verified at their university and
  active on 3 different days within 14 days of joining.
- **Badges** for roles and activity, shown on the profile. A student picks
  one badge to show next to their name.
- **Student profiles** that other students can open.
- **Prize campaigns** run from the admin panel. Winners are the top
  inviters, decided by rank, never by a draw; the team reviews the
  standings before announcing.

Rules we keep:
- **Never reward app ratings or reviews.** Google Play forbids it.
- **No lucky draws.** Prizes go by rank only.
- Every campaign has official rules: free to enter, who can take part, how
  winners are chosen, and "Google is not a sponsor".
- Anonymous content stays anonymous. Nothing here links a person to an
  anonymous post, and badges earned from anonymous activity are
  **private**: only the owner sees them, and they can't be the featured badge.
- Profile photos keep today's rule: only people who share a class group with
  the student (and admins) see the photo. Everyone else sees initials.

## 1. Data (migration `00740_growth.sql`)

```
users
  + referral_code text unique null    -- 8 chars [a-z0-9], made on first use
  + featured_badge text null          -- a badge key the student holds
  + leaderboard_hidden bool not null default false

user_active_days                      -- for qualification; 30 days kept
  user_id → users cascade, day date (Asia/Dhaka), pk (user_id, day)
  Written at most once a day per user, from the auth middleware (keep a
  small in-memory "seen today" set so it's not a write per request).

referrals
  referred_id uuid pk → users cascade,   -- a student is referred at most once
  referrer_id → users cascade,
  source text CHECK in ('link','join'),  -- personal link, or a class invite they shared
  created_at, qualified_at null,
  disqualified_at null, disqualified_by null → users set null, reason text ≤ 300,
  same_device bool not null default false

user_badges                            -- recomputed (see §3)
  user_id → users cascade, badge text, tier smallint (1 bronze, 2 silver, 3 gold; 0 no tiers),
  private bool, earned_at, pk (user_id, badge)

campaigns
  id, title_en, title_bn, body_en, body_bn, rules_en, rules_bn (≤ 8000),
  starts_at, ends_at, settles_at,      -- settles_at = ends_at + 7 days by default
  university_ids uuid[] null,          -- null: all universities
  prizes jsonb   -- [{rankFrom, rankTo, titleEn, titleBn}]
  status text CHECK in ('draft','live','ended','announced'),
  created_by → users set null, created_at, updated_at

campaign_disqualified                  -- a participant removed from a campaign
  campaign_id → campaigns cascade, user_id → users cascade, reason, by, at, pk (campaign_id, user_id)

campaign_winners
  campaign_id → campaigns cascade, user_id → users cascade, rank int, prize_en, prize_bn,
  announced_at, claimed_at null, delivered_at null, pk (campaign_id, user_id)

campaign_claims                        -- only winners; deleted 90 days after delivery
  campaign_id, user_id, pk (campaign_id, user_id), full_name ≤ 80,
  phone ≤ 20, address ≤ 300, note ≤ 300, created_at
```

## 2. Invites

- **Link:** `https://varsitykotha.com/r/{code}`.
  - The web page sends phones to Play with the install referrer
    `utm_source=invite&ref={code}`.
  - The app already reads the install referrer for class invites
    (`join=…`). Keep that working, and also read `ref`.
  - App Links add `/r/`.
- **Class invites count too.** When a student shares a class invite link, the
  app adds their code: `/join/{CODE}?ref={code}`. Play then gets
  `join=CODE&ref=code`. An invite that comes through a class invite is
  recorded with `source='join'`.
- **Claim:**
  - The app sends `POST /me/referral {code}` after sign-in.
  - Rules: only within 7 days of the account's creation; only once; not the
    student's own code; the referrer must be a student (not banned).
  - Errors: `REFERRAL_TOO_LATE`, `ALREADY_REFERRED`, `REFERRAL_SELF`,
    `REFERRAL_NOT_FOUND`. All are 4xx, and the app ignores them silently.
- **Same phone:** if the new student's push tokens or Firebase installation
  ID match one of the referrer's devices, the invite is `same_device=true`.
  It never qualifies, and the admin sees it.
- **Qualification:**
  - An invite qualifies when the friend is verified and has 3 distinct
    active days within 14 days of `created_at`.
  - It's checked when the friend becomes verified, and by an hourly sweep.
  - After 14 days without qualifying it stays unqualified for good.
- **Push to the referrer** when an invite qualifies:
  - type `referral_joined`;
  - EN "{name} joined VarsityKotha with your link";
  - BN "{name} তোমার লিংক দিয়ে ভার্সিটি কথায় যোগ দিয়েছে".

## 3. Badges

Keys, with the tier thresholds bronze / silver / gold. "Private" means only
the owner sees it.

| key | earned for | tiers |
|---|---|---|
| `verified` | verified student | none |
| `founding` | account created before 2027-04-01 | none |
| `cr` | CR of a class group now | none |
| `campus_admin` | campus admin now | none |
| `bus_rep` | transport rep now | none |
| `official` | staff (authority or moderator) now | none |
| `blood_donor` | registered blood donor | none |
| `life_saver` | donations marked in the app | 1 / 3 / 5 |
| `bus_buddy` | live bus trips shared (`bus_share_stats.trips`) | 1 / 10 / 30 |
| `section_builder` | CR of a group with N members | 20 / 40 / 60 |
| `connector` | qualified invites | 5 / 25 / 100 |
| `bug_hunter` | own bug reports marked done | 1 / 3 / 10 |
| `helper` | likes on comments and answers | 10 / 50 / 200 (**private**) |
| `campus_voice` | own issues marked solved | 1 / 3 / 10 (**private**) |

- **Computing:** a `recompute(userID)` function updates `user_badges`. It runs:
  - on `GET /me/badges`;
  - after the events that change a badge, where that's easy (verified,
    became CR, invite qualified, bug report done, blood donation marked);
  - in an hourly sweep over users active in the last day.
- **Role badges** disappear when the role ends. Activity badges stay at
  their best tier.
- **New badge or higher tier:** push `badge_earned`:
  - EN "New badge: {name}" / BN "নতুন ব্যাজ: {name}";
  - data `{badge, tier}`;
  - not for `verified` or `founding` given at signup.
- **The featured badge** must be one the student holds and not private. If
  they lose it, it stops showing (no error).

## 4. Profiles
`GET /users/{id}/profile`, for any signed-in student; blocked users get 404:

```
{id, name, verified, university: {id, name, slug}, department, batch,
 joinedAt (month precision), photoVersion|null, googlePhotoUrl|null,
 featuredBadge: {key, tier}|null, badges: [{key, tier, earnedAt}],
 roles: ["cr","campus_admin","bus_rep","official"],
 invitesJoined: n, posts: [IssueCard…]}
```

- `photoVersion` and `googlePhotoUrl` are null unless the viewer may see
  the photo (same rule as `GET /users/{id}/photo`).
- `badges` are the public ones only. The owner gets their private ones too.
- `posts` are the student's **named** Campus posts (never anonymous ones), the
  latest 20, visible to this viewer (campus-only posts only for the same
  university).
- **No email, ever.**

Everywhere a named author is shown, the author object gains
`id` and `featuredBadge`. The UI makes a name tappable only when `id` is
there. Places:
- Campus post and comment author: `Author {name, verified, id?, featuredBadge?}`.
  Only for named content; anonymous stays `null`.
- Class group members: `featuredBadge`.

## 5. API (prefix `/api/v1`)

### Students
| Method | Path | Notes |
|---|---|---|
| GET | `/me/referrals` | `{code, link, invited, joined, pending: [{name, verified, activeDays, createdAt}], recent: [{name, qualifiedAt}]}` |
| POST | `/me/referral` | `{code, source: "link"\|"join"}` → 204 (errors above) |
| GET | `/referral/{code}` | **No sign-in.** `{name, university: {name}}` for the web invite page, or 404. Rate-limited per IP. |
| GET | `/me/badges` | `{badges: [{key, tier, private, earnedAt}], featured, all: [{key, tiers: [thresholds], private}]}`. `all` lets the app show locked badges and how to earn them. |
| PUT | `/me/featured-badge` | `{key\|null}` → `{featured}`. Errors `BADGE_NOT_HELD`, `BADGE_PRIVATE`. |
| PATCH | `/me` | Also takes `leaderboardHidden`. `GET /me` adds `leaderboardHidden`, `featuredBadge` and `referralCode`. |
| GET | `/users/{id}/profile` | See §4. |
| GET | `/campaigns` | Campaigns visible to me (my university is included, or the campaign is for all), live or announced in the last 30 days: `[{id, title, body, startsAt, endsAt, settlesAt, status, prizes: [{rankFrom, rankTo, title}], myScore, myRank, rulesUrl}]`. Title, body and prizes come in the student's language (`Accept-Language` or the `lang` query). |
| GET | `/campaigns/{id}` | The campaign plus `myScore`, `myRank`, `iWon: {rank, prize, claimed}\|null`. |
| GET | `/campaigns/{id}/leaderboard` | `?scope=all\|university`. Returns `{rows: [{rank, name, university, featuredBadge, score, me}], me: row\|null, updatedAt}` with the top 50. A hidden student shows as `"A student at {university short name}"`. |
| POST | `/campaigns/{id}/claim` | Winners only: `{fullName, phone, address, note?}` → 204. Errors `NOT_A_WINNER`, `ALREADY_CLAIMED`. |

**Score:** the participant's qualified invites with `created_at` in
`[starts_at, ends_at]` and `qualified_at ≤ settles_at`. Not counted:
disqualified invites, disqualified participants, and invites with
`same_device`. Only verified students who are not admins take part.

Ranks are ordered by score, then by whoever reached that score earlier.

### Admin
| Method | Path | Notes |
|---|---|---|
| GET / POST | `/admin/campaigns` | List; create (status `draft`). |
| GET / PATCH | `/admin/campaigns/{id}` | Edit while `draft`. PATCH `{status:"live"}` publishes. Once live, only `ends_at`, `settles_at`, rules and prizes can change. |
| GET | `/admin/campaigns/{id}/standings` | Top 100: `[{rank, user: {id,name,email,university}, score, hidden, invites: [{referred: {id,name,university}, source, createdAt, verifiedVia, activeDays, qualifiedAt, sameDevice, disqualified}], flags: ["same_device", "burst" (≥10 invites in 1 hour), "new_account" (referrer under 7 days old)]}]` |
| POST | `/admin/referrals/{referredId}/disqualify` | `{reason}` |
| POST | `/admin/referrals/{referredId}/restore` | Undoes a disqualify. |
| POST / DELETE | `/admin/campaigns/{id}/participants/{userId}/disqualify` | `{reason}`; DELETE undoes it. |
| POST | `/admin/campaigns/{id}/announce` | Allowed after `settles_at`. `{winners: [{userId, rank}]}`; prizes are taken from the ranks. Sets `announced` and pushes `campaign_won` to winners (EN "You won: {prize}!" / BN "তুমি জিতেছ: {prize}!"). |
| GET | `/admin/campaigns/{id}/winners` | Winners, with claim details (full name, phone, address). |
| POST | `/admin/campaigns/{id}/winners/{userId}/delivered` | Marks a prize delivered. |
| GET | `/admin/referrals` | Paged, `?q=&flag=`. Every invite, with its flags. |

Every admin write is audited (`campaign.*`, `referral.*`).

`/admin/stats` adds `growth: {invitesLast7Days, qualifiedLast7Days, liveCampaigns}`.

## 6. App
- **Profile (own):**
  - **"Invite friends" card:** "Invited 12 · 8 joined", a Share button (link
    plus a short EN/BN message) and a list of pending friends ("Rafi ·
    verified · 2 of 3 days").
  - **Badges:** earned ones with their tier; locked ones greyed, saying how
    to earn them; private ones marked "Only you see this"; tap one to show it
    by your name.
  - **"Show me on leaderboards"** switch.
- **Other students' profiles** (`/u/:id`):
  - card with initials or photo (per the photo rule), name, verified tick,
    university, department and batch, joined month;
  - roles and public badges;
  - their named Campus posts.
  - It opens from: a named post or comment author, class group members,
    leaderboard rows, and the campus admin student page.
- **Featured badge by the name:** a small badge icon next to names in class
  group members, named posts and comments, and leaderboards.
- **Campaigns:**
  - **Today:** a campaign card while one is live (title, top prize,
    countdown, my rank and score, "Invite friends").
  - **Campaign page:** prizes, "Bangladesh / My university" leaderboards
    with my row pinned, rules (opens the web rules page), how invites count
    ("A friend counts once they're verified and use the app on 3 days").
  - **Winner:** a "You won!" card with the claim form (full name, phone,
    address, note). After sending: "We'll contact you".
- **Referral claim:**
  - Read `ref` from the install referrer and from `/r/{code}` App Links.
  - Save it, then claim after sign-in.
  - Class invite shares include `?ref=`.
- **Push types:**
  - `referral_joined` opens Invite friends;
  - `badge_earned` opens Badges;
  - `campaign_won` opens the campaign.
- **Strings:** English and Bangla.

## 7. Web
- **`/r/[code]`:**
  - "{Name} invited you to VarsityKotha", the app's one-line pitch, "Get it
    on Google Play" (Play link with
    `&referrer=utm_source%3Dinvite%26ref%3D{code}`) and "Open in the app".
  - Unknown code: a generic invite page.
- **`/campaigns/[id]`:** public rules page (EN and BN):
  - title, dates, prizes;
  - how to take part and how invites count;
  - who can take part (verified VarsityKotha students in Bangladesh;
    VarsityKotha team members excluded);
  - how winners are chosen (by rank, reviewed for fraud) and how prizes
    are delivered;
  - "This campaign is not sponsored by Google";
  - contact.
  - Needs a public `GET /campaigns/{id}/public` (no sign-in) with title,
    body, rules, dates and prizes in both languages.
- **Admin panel:**
  - **Campaigns:** list; create and edit (EN and BN fields, dates, the
    universities it covers, prize rows); Publish.
  - **Standings:** each participant with their invites and flags, plus
    disqualify (invite or participant), and Announce winners (picks the top
    ranks, editable).
  - **Winners:** claims and Mark delivered.
  - **Referrals list** with flags.
  - **Dashboard:** a Growth card.
  - **User page:** badges and invites.
- **Privacy policy:**
  - invites (who invited whom is kept and shown to both students and our
    admins);
  - leaderboards (name and university, can be hidden);
  - winners' contact details (only winners, deleted 90 days after
    delivery);
  - profiles (what others see; photo rule; anonymous posts never shown).

## As implemented (API, migration `00740_growth.sql`)

Paths, fields and error codes are as in §5. Where the spec left a choice:

- **Language of campaign text:** `?lang=en|bn`, else the first `bn`/`en` tag of
  `Accept-Language`, else `en`. A missing Bangla text falls back to English.
  Applies to `/campaigns`, `/campaigns/{id}`, `/campaigns/{id}/leaderboard`.
  Pushes go out in both languages and each phone gets its registered one.
- **Active days:** written from the session check (`CheckSession`), once per
  student and Dhaka day per process (in-memory set), 30 days kept.
- **Qualification** (`Qualify`): verified (`verified_at` not later than
  `users.created_at + 14 days`) and 3 distinct Dhaka days in the 14 days from
  the friend's account creation (`created_at`, not the claim time). Checked
  when the friend's new active day is written, when they become verified
  (email verify, CR/vouch/campus-admin verify, admin verify by hand) and in
  the hourly sweep. Never after the window.
- **Same device:** there is no Firebase installation id; only push tokens.
  `device_token_users` keeps a sha256 of every token a student registered, even
  after the token moves to another account. Two accounts that ever shared a
  token are `same_device`; checked at claim, again before qualifying and in the
  sweep. A phone that never registers push can't be detected.
- **Claim errors:** `ALREADY_REFERRED` 409, `REFERRAL_TOO_LATE` 422,
  `REFERRAL_SELF` 422, `REFERRAL_NOT_FOUND` 404; checked in that order. The
  inviter must be role `student` and not blocked. `source` defaults to `link`.
- **`GET /me/referrals`:** `invited` = invites not disqualified, `joined` =
  qualified ones; `pending` = friends inside their 14 days, not on the same
  phone (`activeDays` capped at 3, max 50); `recent` = last 10 qualified.
- **`GET /referral/{code}`:** 404 `REFERRAL_NOT_FOUND` also when the inviter has
  no display name or is blocked; `university` is `null` if they have none.
- **Badges:** the first computation for a student seeds silently, later new
  badges or higher tiers push `badge_earned` (`data: {type, badge, tier}`; tier
  is a string, `"0"` for badges without tiers). Role badges (`verified`,
  `founding`, `cr`, `campus_admin`, `bus_rep`, `official`, `blood_donor`)
  follow the role; the others keep their best tier. `helper` counts likes by
  others on the student's visible comments; `campus_voice` counts their solved
  issues: aggregate counts over the author tables, stored only as private rows
  that only the owner's endpoints read. A featured badge that is gone or private
  is cleared on the next recompute and never shown. `GET /me/badges` also
  recomputes; so does the owner's own profile. Hourly sweep: students active
  today or yesterday. `bug_hunter` and blood donation aren't hooked on their
  events; they show at the next `/me/badges` or sweep.
- **Profile:** `joinedAt` is the first day of the join month in UTC
  (`2026-10-01T00:00:00Z`). Badge items have an extra `private` flag (true only
  in the owner's own view). `roles` are read live. `posts` = the latest 20
  named posts, never anonymous or private (safety) ones: the viewer's own
  university sees posts and issues (campus-only included); other universities
  see only non-campus-only posts, only while `features.visitCampus` is on.
  A blocked or missing student is `404 USER_NOT_FOUND`.
- **Named authors:** `Author` is `{name, verified, id, featuredBadge}`; `id` and
  `featuredBadge` are `null` for a deleted account. Official replies are named
  content too and carry them. Anonymous content still has `author: null`. This
  replaces the old CAMPUS_VOICE rule that a named post never shows an id.
- **Class group members** (`GET /groups/{id}/members`) add `featuredBadge`.
- **Campaigns:** `/campaigns` also lists `ended` campaigns that aren't announced
  yet (so a student can follow rank until settling); announced ones stay 30 days
  after the announcement. `status` is derived: a live campaign past `ends_at` is
  `ended` (the sweep stores it too). Publishing needs a title, English rules, a
  prize and an `ends_at` in the future (`CAMPAIGN_INCOMPLETE`); a live campaign
  only takes `endsAt`, `settlesAt`, rules and prizes (`CAMPAIGN_LOCKED`);
  other errors: `CAMPAIGN_DATES`, `CAMPAIGN_PRIZES` (overlap), `CAMPAIGN_NOT_FOUND`.
  Editing `endsAt` keeps `settlesAt` unless it falls before the new end.
- **Leaderboard** rows add `userId` (null for a hidden student, so it can't be
  opened). Only students with a score appear. The `university` is the full
  university name (there is no short name); a hidden student reads
  `A student at {university}` (Bangla: `{university}-এর একজন শিক্ষার্থী`) and
  shows no badge. `me` is the caller's own row (real name), also when outside
  the top 50; `null` without a score. Participants: verified, role not
  `admin`/`moderator`, not blocked, not disqualified; rank by score, then by the
  latest counted `qualified_at`, then user id.
- **Admin:** `GET /admin/campaigns` is paged (`?status=draft|live|ended|announced|all`);
  `standings`, `winners` and `/admin/campaigns` return what §5 shows (arrays for
  standings and winners). Standings list disqualified participants after the
  ranked ones (`rank: null`, `disqualified: true`) so they can be restored.
  Flags: `same_device`; `burst` (some 1-hour window holds 10+ of the inviter's
  invites); `new_account` (the inviter's first invite came less than 7 days
  after their own sign-up). `announce` takes the winners from the standings
  (participants only, unique users and ranks, each rank must have a prize) and
  returns the winners list (`CAMPAIGN_WINNERS`, `CAMPAIGN_NOT_SETTLED`,
  `CAMPAIGN_NOT_ANNOUNCEABLE`). Disqualify/restore/delivered answer 204.
  Extra: `GET /admin/users/{id}/growth` (`referralCode`, `invitedBy`, `invited`,
  `badges`) for the user page; `/admin/stats.growth.liveCampaigns` counts live
  campaigns inside their dates.
- **Audit actions:** `campaign.create|update|publish|disqualify|restore|announce|delivered`,
  `referral.disqualify|restore`.
- **Sweeps:** hourly (`Sweep`): re-check pending invites, recompute badges,
  mark ended campaigns, delete active days older than 30 days and prize claims
  90 days after delivery.
