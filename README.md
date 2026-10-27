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
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Self-hosting Supabase on our VPS |

## Project layout

```
apps/mobile/            Flutter app (Android, iOS)  · com.silifton.campussaga
packages/campus_core/   Domain models, repository interfaces (pure Dart)
packages/campus_ui/     Design system: tokens, theme, components
packages/campus_data/   Backend (Supabase) implementations
packages/campus_l10n/   English + Bangla strings
supabase/               Backend: migrations, security tests, email templates, config
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

Needs Docker (OrbStack) and the Supabase CLI (`brew install supabase/tap/supabase`).

```bash
supabase start            # local backend: database, auth, API, test mailbox
supabase db reset         # rebuild from migrations + seed.sql
supabase test db          # security tests (supabase/tests/)
supabase status           # URLs and local keys
```

Sign in locally with any address at `demo.ac.bd`; the 6-digit code arrives
in Mailpit at http://127.0.0.1:54324. Put the local publishable key from
`supabase status` in `apps/mobile/env/local.json` (the Android emulator
reaches your Mac at `10.0.2.2`).

## Everyday commands

```bash
dart format .                 # format
flutter analyze               # lint the whole workspace
./tool/test_all.sh            # run every test
```

Changing text: edit `packages/campus_l10n/lib/src/arb/*.arb`, then run
`flutter gen-l10n` inside `packages/campus_l10n`.

Changing the launcher icon: see `apps/mobile/flutter_launcher_icons.yaml`.
