# Campus Saga — Beta checklist (R1 "My Class")

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
| Backend on a public server | **Live (2026-10-28): https://api-campus.silifton.com** on the Tecsior VPS, `/opt/campussaga`, compose project `campussaga` (127.0.0.1:7030), nginx `fx-api-campus.silifton.com.conf`, Let's Encrypt (auto-renew), direct DNS. Redeploy: `backend/deploy/deploy.sh`. Nightly DB dump + weekly log wipe: `/etc/cron.d/campussaga` (from `backend/deploy/campussaga.cron`). Off-site backups still to set up |
| Push delivery | **Live (2026-10-28)** on Android: FCM API enabled in `bitlaabuzz`, service-account key on the server (`deploy/secrets/fcm-service-account.json`; local copy in `~/campussaga-secrets/`, back it up with the upload key) |
| iPhone | Builds; pushes need the APNs key; sign-in uses the browser sheet |

## 1. Server address (decided: `api-campus.silifton.com`)

Students' phones need a public HTTPS address for the API. Either:

- the final product domain (`api.<domain>`) if it is ready, or
- a temporary beta address on silifton.com: **`api-campus.silifton.com`** (chosen).

The app reads it at build time, so switching later only means a new app
build (the old one keeps pointing at the old address until updated; keep the
old address running for a while, or use the force-update minimum build).

## 2. Deploy the backend

Follow [DEPLOYMENT.md](DEPLOYMENT.md) §3 on the VPS (Tecsior conventions):
port 7030 on 127.0.0.1, nginx vhost, certbot, `/opt/campussaga`, `.env`
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
{ "APP_ENV": "production", "API_BASE_URL": "https://api-campus.silifton.com/api/v1" }
```

```sh
cd apps/mobile
flutter build appbundle --release --dart-define-from-file=env/beta.json
# → build/app/outputs/bundle/release/app-release.aab
```

Raise the build number in `pubspec.yaml` (`version: 0.9.0+N`) for every
upload.

## 4. Play Console (internal testing first)

1. Create the app (`com.silifton.campussaga`), accept **Play App Signing**.
2. Testing → Internal testing → create a release → upload the `.aab`.
3. Testers: an email list (up to 100) or a Google Group. Share the opt-in link.
4. **After the first upload:** Setup → App integrity → copy the *App signing
   key* SHA-1 and SHA-256 and add them to Firebase, or Google sign-in fails
   for installs from Play:
   ```sh
   firebase apps:android:sha:create 1:1001688697061:android:5fd623ec12432a0e4f2c0c <SHA> --project bitlaabuzz
   ```
5. Data safety form: answer from [site/privacy.html](../site/privacy.html)
   (email, name, app activity in groups, crash logs, device IDs = push token;
   encrypted in transit; deletion in-app and by email; no ads, no selling).
6. Before closed/open testing or production, Google reviews the app and
   needs a way to sign in. Plan a reviewer account (e.g. a test university
   domain with a fixed code) before leaving internal testing.

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

## 6. Feedback and support

Profile → About → **Send feedback** opens an email to hello@silifton.com
with the app version and phone. Crashes arrive in Firebase Crashlytics
(release builds only).

## Later (not needed for the Android beta)

- iPhone: APNs key in Firebase + Push Notifications / Background Modes
  capabilities, then TestFlight.
- Native Google picker on iPhone (blocked by google_sign_in vs Firebase iOS 13).
- Exact-alarm policy check before production (see ARCHITECTURE.md §7).
