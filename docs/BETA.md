# VarsityKotha — Beta checklist (R1 "My Class")

Goal from the roadmap: **5+ class groups (200+ students) for 2 weeks with no
critical bugs**, Android first. iPhones follow once the Apple push key is set.

## Status

| Area | State |
|---|---|
| R1 features (groups, routine, reminders, changes, announcements, pushes, retakes, personal classes, new semester, co-CRs) | Built and tested |
| Android release build | Signed App Bundle builds (`0.9.0+2`) |
| Upload key | `~/campussaga-secrets/upload-keystore.jks` (+ `key.properties.backup`). **Back both up to the password manager now.** Losing the upload key is recoverable with Play App Signing, but slow |
| Upload key in Firebase | SHA-1 and SHA-256 registered (Google sign-in works in release builds) |
| Privacy policy / account deletion page | Updated for groups, personal classes, announcements and pushes (`site/`; publishes on push to `main`) |
| Backend on a public server | **Live (2026-10-28): https://api.varsitykotha.com** on the Tecsior VPS, `/opt/varsitykotha`, compose project `varsitykotha` (containers `varsitykotha-*-1`, volumes `varsitykotha_pgdata` / `varsitykotha_media`; renamed from `campussaga` on 2026-10-28) (127.0.0.1:7030), nginx `fx-api.varsitykotha.com.conf`, Let's Encrypt (auto-renew), DNS on Cloudflare (DNS only, not proxied). The old `api-campus.silifton.com` still serves older app builds. Redeploy: `backend/deploy/deploy.sh`. Nightly DB dump + weekly log wipe: `/etc/cron.d/varsitykotha` (from `backend/deploy/varsitykotha.cron`). Off-site backups still to set up |
| Push delivery | **Live (2026-10-28)** on Android: Firebase project `varsitykotha` (moved from `bitlaabuzz` on 2026-10-28), service-account key on the server (`deploy/secrets/fcm-service-account.json`; local copy `~/campussaga-secrets/fcm-service-account.varsitykotha.json`, back it up with the upload key) |
| iPhone | Builds; pushes need the APNs key; sign-in uses the browser sheet |

## 1. Server address (`api.varsitykotha.com`)

Students' phones need a public HTTPS address for the API. Either:

- the product domain: **`api.varsitykotha.com`** (since 2026-10-28), or
- the first beta address, `api-campus.silifton.com`, kept running for older builds.

The app reads it at build time, so switching later only means a new app
build (the old one keeps pointing at the old address until updated; keep the
old address running for a while, or use the force-update minimum build).

## 2. Deploy the backend

Follow [DEPLOYMENT.md](DEPLOYMENT.md) §3 on the VPS (Tecsior conventions):
port 7030 on 127.0.0.1, nginx vhost, certbot, `/opt/varsitykotha`, `.env`
secrets, the **FCM key file** in `deploy/secrets/`, backups and the log
cron. Then check:

```sh
curl https://<api-host>/api/v1/health      # {"status":"ok","db":"ok"}
```

## 3. Build the beta app

Easiest: `apps/mobile/tool/build.sh`. It asks which server (beta, this Mac
over USB, this Mac on Wi-Fi, or a URL), APK / App Bundle / per-CPU APKs,
whether to raise the build number, and which connected phone to install on.
Plain-http servers get a debug build (release builds only talk HTTPS).
The result is copied to `apps/mobile/build/out/` with the version and server
in its name. Without questions:
`tool/build.sh --server beta --type aab --bump --install none --yes`.

By hand, `apps/mobile/env/beta.json` (git-ignored):

```json
{ "APP_ENV": "production", "API_BASE_URL": "https://api.varsitykotha.com/api/v1" }
```

```sh
cd apps/mobile
flutter build appbundle --release --dart-define-from-file=env/beta.json
# → build/app/outputs/bundle/release/app-release.aab
```

Raise the build number in `pubspec.yaml` (`version: 0.9.0+N`) for every
upload.

## 4. Play Console (internal testing first)

1. Create the app (`com.silifton.varsitykotha`), accept **Play App Signing**.
2. Testing → Internal testing → create a release → upload the `.aab`.
3. Testers: an email list (up to 100) or a Google Group. Share the opt-in link.
4. **After the first upload:** Setup → App integrity → copy the *App signing
   key* SHA-1 and SHA-256 and add them to Firebase, or Google sign-in fails
   for installs from Play:
   ```sh
   firebase apps:android:sha:create 1:1058979568560:android:4cd9ab36c355f065ed5475 <SHA> --project varsitykotha
   ```
5. Data safety form: answer from [site/privacy.html](../site/privacy.html)
   (email, name, app activity in groups, crash logs, device IDs = push token;
   encrypted in transit; deletion in-app and by email; no ads, no selling).
6. Before closed/open testing or production, Google reviews the app and
   needs a way to sign in: see [Reviewer access](#reviewer-access).

## 5. Test on real phones before inviting students

Two phones (CR and classmate), ideally one Xiaomi/Oppo/Vivo/Realme:

- [ ] Onboarding, then sign in with Google (native picker) and with email code
- [ ] CR: create group, add a week of classes (several days at once), copy invite
- [ ] Classmate: join with the code; Today shows the next class and countdown
- [ ] Reminders on; a class 12 min ahead reminds at 10 min with the phone locked
- [ ] Reminders still fire after restarting the phone
- [ ] CR cancels / moves a class → classmate gets a push; tap opens the group
- [ ] CR posts an announcement → push + "New" on Today
- [ ] Hide a course; add a personal class; both reflected in Today/Routine/reminders
- [ ] Airplane mode: Today and Routine still open with the saved routine
- [ ] Make a co-CR; step down; start a new semester
- [ ] Bangla: switch language; notifications arrive in Bangla
- [ ] Delete account works and the CR role passes on

## Reviewer access

Reviewers have no university email, so Play Console's **App access** needs a
fixed login. The API has an off-by-default reviewer sign-in: one email, one
fixed 6-digit code, no email sent. The code goes through the normal code path
(same limit of 5 wrong tries, resend and hourly limits, 10 minute expiry),
only for that email; no other address and not the admin panel accept it.
The reviewer lands in a hidden demo university ("VarsityKotha Demo University",
domain `review.varsitykotha.com`) that no other student can see or pick.

**Enable** (on the server, in `/opt/varsitykotha/.env`; pick a random code and
keep it out of the repo and chat logs):

```sh
REVIEW_EMAIL=play-review@review.varsitykotha.com
REVIEW_CODE=<6 digits>
```

then deploy as usual (migration 00580 adds the demo flag) or at least
`docker compose up -d api`. The API refuses to start if only one is set or the
code is not 6 digits.

**Seed the demo data** (once; safe to re-run, it refreshes the dates):

```sh
cd /opt/varsitykotha/deploy
docker compose exec -T postgres psql -U campus -d campus < review-seed.sql
```

It creates the reviewer ("Play Reviewer", CSE batch 61), a CR and a classmate,
a class group (join code `DEMXRV`) with a Sunday-Thursday routine of 5 courses,
an upcoming class test and assignment, two announcements and four Campus Voice
issues with a few supports and comments.

**Play Console, App access** ("All or some functionality is restricted"): add
instructions with

- Email: `play-review@review.varsitykotha.com`
- Code: `<6 digits>` (the `REVIEW_CODE` value)
- Steps: open the app, choose "Sign in with email", enter the email, tap
  Send code, then type the code. No email arrives; the code is the fixed one.

**Rotate the code:** change `REVIEW_CODE` in `.env`, `docker compose up -d api`,
update the Play Console instructions. Do this after every review round.

**Disable and clean up:** remove both variables from `.env` and restart the
API (the reviewer can no longer sign in). To also delete the demo data:

```sh
docker compose exec -T postgres psql -U campus -d campus < review-unseed.sql
```

## 6. Feedback and support

Profile → About → **Send feedback** opens an email to hello@silifton.com
with the app version and phone. Crashes arrive in Firebase Crashlytics
(release builds only).

## Later (not needed for the Android beta)

- iPhone: APNs key in Firebase + Push Notifications / Background Modes
  capabilities, then TestFlight.
- Native Google picker on iPhone (blocked by google_sign_in vs Firebase iOS 13).
- Exact-alarm policy check before production (see ARCHITECTURE.md §7).
