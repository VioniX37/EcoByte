# EcoByte

EcoByte is a Flutter application focused on reducing electronic waste through reuse, resale, education, and community participation.

This upgraded version is Supabase-first (auth, database, and storage) and is ready to run across Android, iOS, and Web.

## Core Features

- Authentication and profile onboarding (Supabase Auth + profile bootstrap)
- Community feed (posts, likes, media uploads)
- Marketplace (list, browse, and manage reusable electronics)
- Recycling map (location-aware recycler discovery)
- Daily quiz and score tracking
- AI assistant for repair/recycling guidance
- Theme-aware premium UI flow

## Tech Stack

- Flutter (Dart)
- Supabase Auth
- Supabase Postgres
- Supabase Storage
- Google / Gemini APIs for AI and search enrichment

## Project Structure

```text
EcoByte/
	lib/
		app/                  # shared state, repositories, reusable widgets
		pages/                # feature screens (auth, home, map, community, buy/sell, quiz)
		main.dart             # app bootstrap
	assets/                 # images/icons (including vionix branding asset)
	supabase/migrations/    # SQL migrations and policies
	web/                    # web manifest and bootstrap HTML
	android/, ios/, linux/, macos/, windows/  # platform runners
	test/                   # widget tests
```

## Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (bundled with Flutter)
- Supabase project with required schema
- Android Studio / Xcode (for mobile builds)

## Environment Setup

1. Copy `.env.example` to `.env`.
2. Fill all required values:

```env
GOOGLE_API_KEY=...
SEARCH_ENGINE_ID=...
GEMINI_API_KEY=...
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

## Supabase Requirements

The app expects these tables:

- `profiles`
- `products`
- `messages`
- `message_likes`
- `quiz_sets`
- `quiz_questions`
- `quiz_attempts`

Storage bucket:

- `uploads` (public read, authenticated write/delete per policy)

Apply migration/policy scripts from `supabase/migrations/` before first run.

## Run Locally

Install dependencies:

```bash
flutter pub get
```

Run on default device:

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

Build web release:

```bash
flutter build web --release
```

Build Android APK:

```bash
flutter build apk --release
```

## Web Readiness Notes

- `web/index.html` has EcoByte metadata (title + description).
- `web/manifest.json` is configured with EcoByte naming and branding colors.
- The app is configured as a PWA-style installable web app through Flutter's manifest flow.

## Upgrade Notes

- Firebase dependencies/config have been removed from active app flows.
- Supabase repository helpers now drive auth, profile data, uploads, and core feature reads/writes.
- Existing UI/feature behavior has been preserved while modernizing data layer integration.

## About Screen and Branding

- The app includes an **About** page available in dropdown menus directly above **Logout**.
- The About screen introduces the application and credits **VioniX** as the builder.
- Branding asset expected: `assets/vionix.png`.

## License and Usage

This repository is distributed under a **non-commercial, personal-use-only** license.

- Cloning for personal setup/run is allowed.
- Commercial use, resale, sublicensing, redistribution, and unauthorized reuse are prohibited.

See `LICENSE` for full terms.

## Production Gap Review (Current)

The app is strong functionally, but for production-grade maturity it still needs:

1. Full account recovery flow
2. Email verification and stronger auth guardrails
3. Role-based access control and stricter row-level policies audit
4. End-to-end automated test suite (critical journeys)
5. Crash/error monitoring (Sentry, Crashlytics, or equivalent)
6. Structured analytics and event instrumentation
7. Rate limiting / abuse protection on write-heavy flows
8. Better offline/poor-network behavior and sync conflict handling
9. Data retention/privacy policy and legal compliance pages
10. In-app support/contact and incident response process
11. CI/CD pipelines with automated quality gates
12. Formal release versioning/changelog discipline

## Immediate Priority Backlog

1. Forgot password + reset email flow
2. Email verification enforcement at signup/login
3. Secure session handling review and token expiry UX
4. Test coverage for auth, posting, listing, and quiz flows
5. Production monitoring/alerting integration

## Troubleshooting

- If `flutter pub get` fails on Windows due to symlink restrictions, enable Developer Mode.
- If uploads fail with 401/403, verify Supabase storage bucket policies were applied.
- If map data is empty, verify RPC/table permissions used by recycler lookup.

## Maintainer

- Builder: VioniX
- Project: EcoByte
