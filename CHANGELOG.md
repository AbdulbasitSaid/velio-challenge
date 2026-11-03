# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project has no versioned releases yet. Maintained with the `changelog` skill (`.claude/skills/changelog/SKILL.md`).

## [Unreleased]

### Added
- A specification-driven development process: the project constitution (`CLAUDE.md`), a roadmap (`ROADMAP.md`), this changelog with its maintenance skill, and the `spec/` directory for timestamped specifications. No application functionality exists yet. ([spec](spec/2026-11-03_07-25_establish-sdd-constitution/))
- The Velio design system and the complete Group Bookings UI in Claude Design: tokens and 29 components (including Google Maps location, picker and community map components), and 42 high-fidelity screens covering guest, booker, host, community, profile, account, error and admin flows on web (phone and desktop) and Flutter, with responsive rules for 360px to desktop and text scaling to 200%. Source is saved with the spec. ([spec](spec/2026-11-03_10-34_complete-ui-design/))
- The application foundation (S1): a Bun workspace with the API and a shared contracts package. Two commands set it up from a fresh clone. Local Docker Compose runs Postgres, MinIO and an OpenTelemetry Collector. The complete database schema is applied by forward-only migrations: insert-only tables reject updates and deletes for every role, user generation and creation time can't change, activity values are range-checked, and an activity's date and location lock after its first confirmed booking. The three communities are seeded. "Continue as" sign-in takes a name and an email or phone. Contacts are normalised and stored only as a keyed hash; web clients get a cookie and mobile clients a bearer token; sessions expire after 30 days idle or 90 days total, rotate on sign-in and support sign-out. Health and readiness endpoints, typed error envelopes and generated OpenAPI are in place. Traces, metrics and JSON logs share a trace ID, with personal data and invite codes redacted. A GitHub Actions CI workflow runs format, lint, types, migrations, drift checks and tests. It hasn't run on GitHub yet. ([spec](spec/2026-11-03_09-29_s1-foundations/))

### Changed
- Product requirements now include Google Maps locations (host place search and pin, maps with directions, community map, meeting point) and a My plans screen; the MVP plan and S1 schema were updated to match. ([spec](spec/2026-11-03_10-34_google-maps-locations/))
