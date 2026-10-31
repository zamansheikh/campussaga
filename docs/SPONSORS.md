# Sponsors and ads (our own, run from the admin panel)

Brands reach students inside VarsityKotha without annoying them. No ad
networks: the team creates every ad in the admin panel, the app draws it with
its own components, and sponsors only ever get totals.

## 0. Rules we keep (quality bar)
1. **Looks like the app.** Same cards, type, radii and dark mode. A quiet
   "Sponsored" / "স্পন্সরড" label on every ad. No pop-ups, interstitials,
   autoplay video or sound.
2. **Few.** At most one ad per screen; per-student daily caps; "Hide this" (7
   days) on every ad.
3. **Never** on: class routine and its pages, reminders, blood *requests*,
   a live bus while sharing or following it, sign-in and onboarding,
   help/feedback, profile, anonymity settings, and **never as a push**.
4. **Relevant.** Each ad targets universities and/or cities (or everyone).
5. **Private.** Sponsors and reports get daily totals only. No user-level data
   leaves the server; per-user rows exist only for caps and are deleted after
   90 days.
6. **Smooth.** Nothing shows until its image is decoded; it fades in; a failed
   load shows nothing. Content above the user's scroll position never moves.
7. **Fair.** "Why am I seeing this?" says why (your university / city) and that
   the sponsor never sees who you are.

## 1. Placements

| key | where | how many | format |
|---|---|---|---|
| `deals` | **Student deals** page (Explore tile "Student deals"; also opens from links) | all live deals for me, ≤ 50 | **Deal**: logo, brand, offer title, short body, promo code with Copy, expiry, terms (expand), optional "Visit" |
| `today` | **Today**, after the routine/class block, before announcements | ≤ 1 per day | **Card**: image 2:1, "Sponsored · Brand", title, one-line body, one button |
| `campus` | **Campus feed** (the main feed only; not My posts, not a post's page) | after every 12th post, ≤ 2 per feed load, never the same one twice in a session | **Feed post**: looks like a post (brand logo as the avatar, name, "Sponsored"), image, text, button; no comments/likes/report |
| `line:bus`, `line:groups`, `line:cgpa`, `line:blood` | the bottom of the Bus routes list, Class groups list, CGPA page, Blood main page | ≤ 1 | **Line**: "Supported by [logo] Brand" in one quiet line, tappable. `line:blood` only for sponsors marked **health** (hospitals, NGOs), never on a blood request |
| `campaign` | a prize campaign: poster, rules page, share card | 1 per campaign | **Powered by**: "Powered by [logo] Brand" chip |

## 2. Data (migration `00780_sponsors.sql`)
```
sponsors
  id, name ≤ 80, category text CHECK in ('general','health') default 'general',
  logo_key, logo_version null,           -- square PNG/JPEG, re-encoded ≤ 512 px
  website ≤ 300 (https), contact_name ≤ 80, contact_phone ≤ 20,
  contact_email ≤ 120, notes ≤ 1000,
  archived_at null, created_by → users set null, created_at, updated_at

promos
  id, sponsor_id → sponsors cascade,
  kind text CHECK in ('deal','card','feed','line','campaign'),
  placement text                         -- 'deals' | 'today' | 'campus' | 'line:bus' |
                                         -- 'line:groups' | 'line:cgpa' | 'line:blood' | 'campaign'
  campaign_id → campaigns cascade null,  -- kind campaign only
  title_en ≤ 60, title_bn ≤ 60, body_en ≤ 140, body_bn ≤ 140,
  cta_en ≤ 20, cta_bn ≤ 20,              -- button text ("Get offer")
  image_key, image_version null,         -- 2:1, re-encoded ≤ 1600×800 (card, feed: required)
  link_kind text CHECK in ('none','web','app') default 'none',
  link text ≤ 500,                       -- web: https URL; app: an allowed route (§4)
  code ≤ 30 null, expires_at null,       -- deals
  terms_en ≤ 500, terms_bn ≤ 500,
  university_ids uuid[] null, cities text[] null,   -- null: everyone
  starts_at, ends_at,
  status text CHECK in ('draft','live','paused','ended') default 'draft',
  daily_cap smallint default 2,          -- times one student sees it a day (card, feed)
  total_views int null,                  -- stop after this many views (what was paid)
  priority smallint 1..10 default 5,
  created_by, created_at, updated_at

promo_days                               -- daily totals for reports, kept forever
  promo_id → promos cascade, day date (Asia/Dhaka),
  views int, viewers int, taps int, copies int, hides int, pk (promo_id, day)

promo_user_days                          -- for caps and unique viewers; 90 days
  promo_id, user_id → users cascade, day, views smallint, taps smallint,
  pk (promo_id, user_id, day)

promo_hides
  user_id → users cascade, promo_id → promos cascade, until timestamptz,
  pk (user_id, promo_id)
```
- Validation per kind: `card`/`feed` need an image and a title; `deal` needs a
  title (image optional, the logo is used); `line` needs nothing but the
  sponsor (text optional: "Supported by"); `campaign` needs `campaign_id` and
  uses the sponsor's name and logo. `line:blood` requires a `health` sponsor.
  `link` must be `https://…` for web, or an allowed app route.
- `live` needs `starts_at < ends_at`; the sweep sets `ended` after `ends_at`
  and stops a promo that reached `total_views` (status stays live, but it is
  not served; reports show "Delivered").
- Errors: `INVALID_PROMO` (400, with a field message), `PROMO_NOT_FOUND`,
  `SPONSOR_NOT_FOUND`, `INVALID_IMAGE`, `IMAGE_TOO_LARGE`,
  `HEALTH_SPONSOR_ONLY`.

## 3. Choosing what to show (server)
For a student and a placement, the eligible promos are: status `live`, now in
`[starts_at, ends_at]`, the student's university in `university_ids` (or null),
the university's city in `cities` (or null), `total_views` not reached, not
hidden by the student (`promo_hides.until > now`), and for `card`/`feed` the
student's views today < `daily_cap`.

- `deals`: all eligible, by priority desc, then `ends_at` asc.
- `today`: **one**, the same all day for a student: weighted by priority, with
  a stable pick from hash(user, day, placement) so it doesn't flicker between
  opens.
- `campus`: up to 3, ordered by the same stable weighted pick; the app inserts
  them after posts 12 and 24 (it never uses the third unless one is hidden).
- `line:*`: one, stable pick.
- `campaign`: on the campaign JSON (§5), not here.
- Only verified-or-not signed-in students get ads; staff/admins see them too
  (so the team sees what students see), but their events aren't counted.

## 4. API (prefix `/api/v1`)

### Students
| Method | Path | Notes |
|---|---|---|
| GET | `/promos?placement=…&lang=en\|bn` | `{items: [Promo]}`. **Promo**: `{id, kind, placement, sponsor: {name, logoUrl\|null, category}, title, body, cta, imageUrl\|null, link: {kind, url}\|null, code\|null, expiresAt\|null, terms, why}`. Text in the student's language (Bangla falls back to English). `why`: "Shown to students at {university}" / "…in {city}" / "Shown to all students", in the student's language. `imageUrl`/`logoUrl` are paths under the API base with `?v=`. |
| POST | `/promos/events` | `{events: [{promoId, type: "view"\|"tap"\|"copy"\|"hide", at}]}`, ≤ 50 per call → 204. A view counts once per promo per student per **app session** (the app sends at most one per screen visit); the server ignores views beyond 20 per promo per student per day and events for promos not served to that placement. `hide` sets `promo_hides.until = now + 7 days`. Rate-limited. Staff events are ignored. |
| GET | `/promos/{id}/image?v=` | No sign-in. JPEG; immutable cache when `v` is current, else `max-age=300`; draft images need the current `v`. |
| GET | `/sponsors/{id}/logo?v=` | Same rules. |

Allowed app routes for `link_kind = app`: `/explore`, `/deals`, `/bus`,
`/blood`, `/groups`, `/find-class`, `/cgpa`, `/campus`,
`/campaigns/{id}`. Anything else is refused (`INVALID_PROMO`).

### Admin (role admin)
| Method | Path | Notes |
|---|---|---|
| GET/POST | `/admin/sponsors` | List (`?q=&archived=`, paged) / create. |
| GET/PATCH/DELETE | `/admin/sponsors/{id}` | DELETE archives (keeps reports). |
| POST/DELETE | `/admin/sponsors/{id}/logo` | multipart `image`, ≤ 4 MB → square ≤ 512 px. |
| GET/POST | `/admin/promos` | List (`?status=&kind=&placement=&sponsorId=&q=`, paged, with today's and total views/taps) / create (draft). |
| GET/PATCH/DELETE | `/admin/promos/{id}` | Edit any field while draft or paused; while live only `ends_at`, `total_views`, `daily_cap`, `priority`, `status`. DELETE only drafts. |
| POST | `/admin/promos/{id}/status` | `{status: "live"\|"paused"\|"ended"}`; going live validates the whole promo. |
| POST | `/admin/promos/{id}/duplicate` | A draft copy (image copied). |
| POST/DELETE | `/admin/promos/{id}/image` | multipart `image`, ≤ 8 MB → 2:1 ≤ 1600 px (same pipeline as campaign banners). |
| GET | `/admin/promos/{id}/stats?from=&to=` | `{days: [{day, views, viewers, taps, copies, hides}], totals: {views, viewers, taps, copies, hides, ctr}}`. |
| GET | `/admin/sponsors/{id}/stats?from=&to=` | Totals per promo of that sponsor, for a sponsor report. |

Audit: `sponsor.*`, `promo.*`. `/admin/stats` adds `sponsors: {livePromos,
viewsToday, tapsToday}`.

## 5. Campaign sponsor
- A `campaign`-kind promo links a sponsor to a campaign (one live per
  campaign). Campaign JSON (student list/detail and public) adds
  `sponsor: {name, logoUrl|null, link|null}` or null.
- App: "Powered by [logo] Brand" chip at the poster's bottom-right, on the
  share card, and the rules page shows it under the title.

## 6. App
- **Components** (campus_ui, reusable): `CsSponsoredLabel` ("Sponsored · Brand"
  with an ⓘ that opens the Why sheet), `CsPromoCard` (card), `CsPromoFeedPost`,
  `CsDealCard`, `CsSponsorLine`, `CsPoweredBy`.
- **Why / Hide sheet** from ⓘ or ⋯: `why` text, "Sponsors never see who you
  are", "Hide this ad" (7 days; it animates out).
- **Smooth**: precache the image, then fade + size in (`AnimatedSize` +
  `AnimatedOpacity`, 250 ms). Nothing is inserted above what's on screen.
- **Views**: counted when ≥ 50 % of the ad is visible for ≥ 1 s
  (`visibility_detector`), once per screen visit; taps/copies/hides sent at
  once; events batched every 10 s and when the app goes to background; lost
  events are fine.
- **Links**: web links open in the in-app browser (Custom Tabs); app links go
  through the router.
- **Deals page** (`/deals`): a searchable list grouped by "Near you"
  (targeted to my university/city) and "Everywhere"; Copy shows a snackbar
  "Code copied"; expired deals disappear. Explore gets a "Student deals" row
  with the number of live deals.
- **Strings**: EN/BN for every label (Sponsored, Supported by, Powered by,
  Why…, Hide this ad, Code copied, Student deals, Visit, Terms).
- **Offline**: no ads; nothing is cached across launches.

## 7. Web (admin panel)
- **Sponsors** (nav item): list with search; sponsor page: details, logo
  upload, category (General / Health), contact, notes, its promos, a sponsor
  report (totals per promo, CSV and printable report for the sponsor).
- **Ads** (nav item): list with filters (status, kind, placement, sponsor),
  today's and total views/taps, status chips; create/edit with:
  - kind and placement pickers (placement limited by kind; `line:blood` only
    for health sponsors);
  - EN/BN texts with counters; image upload (2:1 crop hint);
  - link: none / website / app screen (dropdown of allowed routes);
  - deal code, expiry, terms;
  - targeting: all, or pick universities and/or cities;
  - schedule, daily cap, total views, priority;
  - **live preview**: the ad as the app draws it (light and dark, phone width),
    switching EN/BN;
  - Publish / Pause / End / Duplicate.
- **Report** per ad: a daily chart (views, taps), totals, CTR, CSV export.
- Dashboard: a Sponsors card.
- **Privacy policy**: sponsored content; we count views and taps in total;
  sponsors never get your data.

## 8. Play Console
"Contains ads: Yes" in the store listing (App content → Ads). Data safety does
not change: no data goes to ad networks or sponsors.
