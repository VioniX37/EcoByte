# EcoByte

Last updated: 2026-05-30

EcoByte is a cross-platform Flutter app that helps reduce electronic waste through reuse, resale, education, and community participation. This repository is Supabase-first (auth, database, and storage) and targets Android, iOS, Web and desktop platforms.

## Quick Links

- Documentation: [CONTRIBUTING.md](CONTRIBUTING.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)

## One-line start

1. Copy `.env.example` to `.env` and set required keys. 2. Run `flutter pub get`. 3. Run `flutter run`.

## Core Features

- Supabase-backed authentication and profiles
- Email verification and password reset flows
- Community feed with media uploads and likes
- Marketplace for listing and browsing reusable electronics
- Location-aware recycling map
- Daily quiz and scoring
- AI assistant for repair/recycling guidance

## Supported Platforms

- Android, iOS, Web, macOS, Linux, Windows (via Flutter platform folders)

## Requirements & Prerequisites

- Flutter SDK (stable channel recommended)
- Android Studio (or Android SDK) for Android builds
- Xcode for iOS builds (macOS only)
- A Supabase project with the expected schema and storage bucket

## Environment variables

Copy `.env.example` to `.env` and set the values below before running locally:

```env
GOOGLE_API_KEY=
SEARCH_ENGINE_ID=
GEMINI_API_KEY=
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_RESET_PASSWORD_REDIRECT_TO=
```

Note: Do not commit `.env` or any secrets to the repository.

## Supabase: expected schema & storage

Tables (examples): `profiles`, `products`, `messages`, `message_likes`, `quiz_sets`, `quiz_questions`, `quiz_attempts`.

Storage buckets: `uploads` (public read, authenticated write/delete per policy).

Apply the SQL migrations and RLS policies in `supabase/migrations/` before first run.

## Development: run locally

Install packages:

```bash
flutter pub get
```

Run on the default device/emulator:

```bash
flutter run
```

Run on web (Chrome):

```bash
flutter run -d chrome
```

Run unit/widget tests:

```bash
flutter test
```

Format and analyze:

```bash
dart format .
dart analyze
```

Build release artifacts:

```bash
flutter build apk --release
flutter build web --release
flutter build ios --release   # macOS only
```

## Project structure (high level)

lib/
- `app/` - shared state, repositories, and utilities
- `pages/` - feature screens (auth, home, map, marketplace, quiz, AI)
- `main.dart` - application bootstrap

Other folders: `assets/`, `supabase/` (migrations), `web/`, `android/`, `ios/`, `windows/`, `macos/`, `linux/`, `test/`

## Immediate Priority Backlog

1. Forgot password + reset email flow
2. Email verification enforcement at signup/login
3. Secure session handling review and token expiry UX
4. Test coverage for auth, posting, listing, and quiz flows
5. Production monitoring/alerting integration

These are prioritized for stability and production readiness. See `CONTRIBUTING.md` for how to contribute fixes and add tests.

## Production gap summary

Areas to address before production:

- End-to-end test coverage for critical user journeys
- Role-based access control and row-level security audit
- Crash/error monitoring and structured analytics
- Data retention & privacy policy artifacts
- CI/CD pipelines and release gating

## Troubleshooting

- If `flutter pub get` fails on Windows due to symlink restrictions, enable Developer Mode.
- If uploads fail with 401/403, verify Supabase storage bucket policies were applied.
- If map data is empty, verify RPC/table permissions used by recycler lookup.

## Repository maintenance (sync steps)

Run these locally to bring your workspace up to date after changes:

```bash
git fetch --all --prune
git status
flutter pub get
dart format .
dart analyze
flutter test
```

To inspect outdated packages:

```bash
flutter pub outdated
```

When upgrading packages, do it in small batches and run `dart analyze` + `flutter test` after each upgrade.

## Contributing

See `CONTRIBUTING.md` for branch, commit, and PR guidelines.

## Changelog

See `CHANGELOG.md` for release notes and change history.

## License

This repository is distributed under the terms in `LICENSE` (non-commercial, personal-use-only). See that file for details.

## Maintainer

- Builder: VioniX
- Project: EcoByte
