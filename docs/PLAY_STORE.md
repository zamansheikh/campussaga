# VarsityKotha on Google Play

Everything needed to publish the Android app, in the order Play Console asks
for it. Status as of 28 October 2026: **all files are ready; the reviewer
sign-in still has to be switched on on the server** (section 2).

## 1. What's ready

| What | File | Play requirement |
|---|---|---|
| App Bundle | `~/Desktop/varsitykotha-<version>-beta-release.aab` (`apps/mobile/tool/build.sh --server beta --type aab` moves each bundle to the Desktop) | Signed with the upload key, target SDK 36, min SDK 24, version 1.0.2 (6) (first upload was 1.0.0 (3)), native libraries 16 KB aligned, native debug symbols included, no advertising ID |
| App icon | `store/google-play/icon-512.png` | 512 × 512 PNG |
| Feature graphic | `store/google-play/<locale>/feature-graphic.png` | 1024 × 500 |
| Phone screenshots | `store/google-play/<locale>/phone-01.png` … `phone-08.png` | 8 × 1080 × 1920 (9:16) |
| Promo video | `store/google-play/<locale>/promo-video.mp4` (not in git; rebuild with `tool/store/build.sh`): 47 s (EN) / 50 s (BN), 1080p, narration and music | Play takes a **YouTube link**: upload it (Public or Unlisted, ads off) and paste the URL |
| Title, short and full description | `store/google-play/<locale>/title.txt`, `short-description.txt`, `full-description.txt` | 30 / 80 / 4000 characters |
| Release notes | `store/google-play/<locale>/changelogs/3.txt` | 500 characters |

`<locale>` is `en-US` (default) and `bn-BD` (Bangla translation). The folder
layout is the one `fastlane supply` uses, so uploads can be automated later.

Screenshots, in order: Today · Routine · Class changes · Tests & deadlines ·
Campus Voice · Official replies · Find your class · Bus routes & CGPA.

**Rebuilding the graphics** after app changes: `tool/store/build.sh` (needs
Flutter, Node, Google Chrome and ffmpeg). It renders the app screens with demo
data (`apps/mobile/tool/screenshots/store_test.dart`), then frames, the
feature graphic, the icon and the videos (`tool/store/`). Captions and the
narration script are in `tool/store/content.mjs`.

**Narration and music** come from ElevenLabs (Starter plan, so commercial use
is allowed): Bangla voice *Tazim* (native Bangladeshi accent), English voice
*Jessica*, model `eleven_v4`, and a generated instrumental music bed. The
clips are in `tool/store/audio/` (in git), so rebuilding costs nothing. After
changing a line, run `ELEVENLABS_KEY_FILE=<path to key.txt> tool/store/build.sh`:
only the changed lines are generated again. The mix ducks the music under the
voice and levels it to -16 LUFS.

## 2. Before submitting: reviewer sign-in on the server

Google's reviewers have no university email. The API has a reviewer sign-in
(off by default) and a hidden demo university with demo data: see
[BETA.md, Reviewer access](BETA.md#reviewer-access). Steps:

1. Deploy the current backend (migration 00580).
2. Add `REVIEW_EMAIL=play-review@review.varsitykotha.com` and a random
   `REVIEW_CODE` (6 digits) to `/opt/varsitykotha/deploy/.env`, restart the API.
3. Seed the demo data (`backend/deploy/review-seed.sql`).
4. Test it on a phone: sign in with that email and code.

## 3. Play Console, step by step

### Create the app
- App name **VarsityKotha**, default language **English (United States)**,
  **App**, **Free**. Accept the declarations.

### Main store listing
- English: paste the `en-US` texts, upload the icon, feature graphic and the 8
  phone screenshots, add the YouTube link.
- **Add translation → Bengali (bn-BD)**: paste the `bn-BD` texts and upload
  the `bn-BD` feature graphic and screenshots (and its video link).
- Tablet screenshots are optional; skip them (the app is phone-first).

### Store settings
- Category: **Education**. Tags: Education, Productivity, Social.
- Contact: email `hello@silifton.com`, website `https://varsitykotha.com`.
- External marketing: on.

### App content
| Section | Answer |
|---|---|
| Privacy policy | `https://varsitykotha.com/privacy` |
| App access | **All or some functionality is restricted** → add instructions: email `play-review@review.varsitykotha.com`, code = the `REVIEW_CODE`, steps: open the app, tap "Use university email instead", enter the email, tap "Send code", type the code (no email arrives) |
| Ads | **No, my app does not contain ads** |
| Content rating | Category **Social or Communication** (users post and comment). Answer honestly: no violence, sexual content, drugs, gambling or bad language from the app itself; **users can interact and share content** (Campus Voice posts, comments, photos), with reporting and moderation; **shares location with other users: Yes** from build 6 (a student who opts in to share their bus live shows other students where that bus is, anonymously); no purchases. Expect a "Users interact" descriptor |
| Target audience | **18 and over** (university students). The app is not for children |
| News app | No |
| COVID-19 / Health / Financial features | None |
| Government app | No |
| Data safety | See below |
| Advertising ID | **No** (the app doesn't use it; no `AD_ID` permission) |
| Account deletion | In the app (Profile → Delete account) and on the web: `https://varsitykotha.com/delete-account` |

### Data safety
- Does the app collect or share user data? **Yes, collects. Shares: No**
  (Firebase, Resend and our storage only process data for us, which Play
  doesn't count as sharing).
- Encrypted in transit: **Yes**. Users can request deletion: **Yes**.

| Data type | Collected | Optional? | Purpose | Notes |
|---|---|---|---|---|
| Personal info → Email address | Yes | Required | App functionality, Account management | University or Google email |
| Personal info → Name | Yes | Required | App functionality | Shown to classmates |
| Personal info → User IDs | Yes | Required | App functionality, Account management | Internal account ID |
| Personal info → Phone number | Yes | Optional | App functionality | Blood donation: a donor's number (sent only to a requester they offer to help) and a request's contact number |
| Health and fitness → Health info | Yes | Optional | App functionality | Blood donation: blood group and last donation date |
| Photos and videos → Photos | Yes | Optional | App functionality | Photos attached to Campus Voice posts, and an optional profile photo |
| App activity → Other user-generated content | Yes | Optional | App functionality | Routines, announcements, course links, Campus posts, comments and polls, blood requests |
| App activity → Other actions | Yes | Optional | App functionality | Reactions, poll votes, follows, reports, blood donation offers, bus trip ratings, "bus near" alerts |
| App activity → App interactions | Yes | Optional | App functionality | Live buses (build 6): which live bus a student opened, kept 24 h, only to tell a sharer how many students saw their bus |
| App info and performance → Crash logs | Yes | Required | App functionality | Crashlytics; no user ID |
| App info and performance → Diagnostics | Yes | Required | App functionality | Crashlytics device and app version |
| Device or other IDs | Yes | Required | App functionality | Push token and Crashlytics installation ID |
| Location → Precise location | Yes | Optional | App functionality | Live buses (build 6): only while a student shares the bus they're on; points deleted 24 h after sharing ends, so **not** "processed ephemerally". Also a rep's "Use my location" for a stop |

Not collected: approximate location, contacts, financial info, messages,
audio, files, web history, installed apps. (Phone number and health info
are collected only for blood donation, optionally, from build 6.)

Bus route maps and location (build 4 and later): the app has the
foreground location permission (`ACCESS_FINE_LOCATION`, asked only when
someone taps "Where am I" or "Use my location"; no background location).
"Where am I" uses the location on the phone only. A transport rep's "Use my
location" saves the stop's position with the route, so declare
**Location → Precise location: collected, optional, App functionality, not
shared** to be safe. Map images and place search come from OpenStreetMap,
which sees the phone's IP address and the map area like any website (listed
in the privacy policy).

Live buses (build 6, docs/BUS_LIVE.md): sharing a bus runs a
**location foreground service** (`FOREGROUND_SERVICE_LOCATION`) with an
ongoing notification, started by the student in the app. Play Console →
App content → **Foreground service permissions**: declare *Location*, task
"Live bus sharing: a student on a university bus shares its position so
students waiting at stops see where it is; started by the user, stops on
Stop, at the end of the route or after 3 hours", with a short screen
recording of starting and stopping it. The share sheet is the prominent
disclosure (what is sent, also with the screen off, and who sees it). No
`ACCESS_BACKGROUND_LOCATION`, so no background location declaration.

### Permissions to explain if asked
- `SCHEDULE_EXACT_ALARM`: class reminders at the exact time (the student
  turns it on; not `USE_EXACT_ALARM`, so no declaration form).
- `POST_NOTIFICATIONS`: class changes, announcements, blood requests and
  "bus near" alerts.
- `FOREGROUND_SERVICE_LOCATION`: only while sharing a bus live (above).
- Photos: the system photo picker, so no photo permission.

## 4. Releasing

1. **Internal testing** first: create a release, upload the `.aab`, paste the
   release notes (`changelogs/3.txt`), add testers (email list), roll out.
2. **After the first upload**: Setup → App integrity → copy the **App signing
   key SHA-1** and add it in Firebase *and* as an Android OAuth client in
   Google Cloud (see [BETA.md](BETA.md), step 4), or Google sign-in fails for
   installs from Play.
3. **Closed testing**: personal developer accounts created after November
   2023 must run a closed test with at least 12 testers for 14 days before
   production. Organisation accounts can skip this.
4. **Production**: promote the tested release. Review usually takes a few
   days for a new app.
5. Keep the reviewer login on: Google reviews every update with it. The
   demo data is refreshed every night, so its tests and deadlines stay upcoming.

Every new upload needs a higher build number: `apps/mobile/tool/build.sh`
asks, or pass `--bump`.
