# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project has no versioned releases yet. Maintained with the `changelog` skill (`.claude/skills/changelog/SKILL.md`).

## [Unreleased]

### Added
- A specification-driven development process: the project constitution (`CLAUDE.md`), a roadmap (`ROADMAP.md`), this changelog with its maintenance skill, and the `spec/` directory for timestamped specifications. No application functionality exists yet. ([spec](spec/2026-11-03_07-25_establish-sdd-constitution/))
- The Velio design system and the complete Group Bookings UI in Claude Design: tokens and 29 components (including Google Maps location, picker and community map components), and 42 high-fidelity screens covering guest, booker, host, community, profile, account, error and admin flows on web (phone and desktop) and Flutter, with responsive rules for 360px to desktop and text scaling to 200%. Source is saved with the spec. ([spec](spec/2026-11-03_10-34_complete-ui-design/))

### Changed
- Product requirements now include Google Maps locations (host place search and pin, maps with directions, community map, meeting point) and a My plans screen; the MVP plan and S1 schema were updated to match. ([spec](spec/2026-11-03_10-34_google-maps-locations/))
