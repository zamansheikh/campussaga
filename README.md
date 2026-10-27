<div align="center">

<img src="assets/icon/Campus_Saga_Icon.png" width="120" height="120" alt="Campus Saga icon (placeholder)">

# Campus Saga

**The daily app for university students:** class routine and reminders every
morning, and a safe, anonymous voice to get campus problems fixed.

</div>

> v2 is a fresh start. The old v1 app is kept at the git tag `v1-archive`.
> The name and logo are placeholders and will change.

## Docs

| | |
|---|---|
| [PLAN.md](PLAN.md) | Vision, users, principles, growth, risks |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Releases R0–R5, scope, definition of done |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Database, system design, data model, app structure |
| [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Colors, type, components, rebranding checklist |
| [docs/UNIVERSITIES.md](docs/UNIVERSITIES.md) | All 169 Bangladeshi universities and their student email domains, with patterns |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Running the Go API + Postgres on our VPS |

## Project layout

```
apps/mobile/            Flutter app (Android, iOS)  · com.silifton.campussaga
packages/campus_core/   Domain models, repository interfaces (pure Dart)
packages/campus_ui/     Design system: tokens, theme, components
packages/campus_data/   HTTP implementations of the repositories (talks to the Go API)
packages/campus_l10n/   English + Bangla strings
backend/                Go API: cmd/campusapi, internal/ (platform, modules), migrations/
tool/                   Scripts (test_all.sh)
```

It's a Dart pub workspace: one `flutter pub get` at the root resolves
everything.

## Getting started

Requires Flutter 3.47+ (Dart 3.13+).

```bash
flutter pub get
cp apps/mobile/env/example.json apps/mobile/env/local.json   # fill in backend values later
cd apps/mobile && flutter run --dart-define-from-file=env/local.json
```

The app runs without a backend for now; it connects once the env file has
real values.

## Backend (local)

Needs Go 1.26+ and Docker (OrbStack).

```bash
cd backend
make deps-up      # Postgres 18 (:55632) + Mailpit (SMTP :55625, UI http://localhost:58025)
make run          # API on http://localhost:8090/api/v1 (applies migrations first)
make seed         # dev universities: demo.ac.bd, sit.edu.bd
make test         # go test -race, fresh database per test
```

Sign in locally with any address at `demo.ac.bd`; the 6-digit code arrives
in Mailpit at http://localhost:58025 (without SMTP configured, the server
logs it). Set `API_BASE_URL` in `apps/mobile/env/local.json`: the Android
emulator reaches your Mac at `http://10.0.2.2:8090/api/v1`.

## Everyday commands

```bash
dart format .                 # format
flutter analyze               # lint the whole workspace
./tool/test_all.sh            # run every test
```

Changing text: edit `packages/campus_l10n/lib/src/arb/*.arb`, then run
`flutter gen-l10n` inside `packages/campus_l10n`.

Changing the launcher icon: see `apps/mobile/flutter_launcher_icons.yaml`.
