# Requirements: S7 Flutter app

## Purpose and scope

The Flutter app for iOS and Android: code entry, deep links, the invite view with live spots and a native map, claim and "You're in" with haptics, invite outcomes, the Plan with invite creation, My plans, profile, sign in and errors, an offline cache, and a generated Dart API client. Screen IDs and copy keys refer to `spec/2026-11-03_10-34_complete-ui-design/` and the UX spec copy deck. Design: `PLANNING.md` in this directory.

## Goals and non-goals

- **Goals:** a guest claims from a link or code in one flow; the app shows live, never-queued availability; the last invite and My plans work offline; contracts can't drift from the API.
- **Non-goals:** hosting, activity pages and community pages (web-only, PRD W1); admin; push notifications (PRD Next); mobile timings and analytics events (S8); full E2E suite (S9); tablets and landscape (UI-D5).

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | A Dart client generated from `packages/contracts/openapi.json` is committed, and CI fails when regenerating it changes any file. | MVP plan §5, §8 |
| FR-002 | The theme comes from the `velio_tokens` Dart package generated from the shared tokens; fonts match the web. | UX FR-008 |
| FR-003 | Every request sends `X-Device-Id` (a UUID kept in secure storage) and, when signed in, `Authorization: Bearer` with the token from secure storage. | S4 §4.5; MVP plan §4.6 |
| FR-004 | G8 code entry is the home screen: a 6-character code field (unambiguous alphabet, upper-cased, paste accepted); an invalid code shows an inline error and keeps the code; rate-limited shows `claim.rateLimited`; a valid code opens the invite. | PRD M1, Edge cases, R10 |
| FR-005 | `https://<host>/i/<code>` links open the app on that invite when installed on Android (App Links), on cold start and while running. iOS Universal Links are out of scope (no Apple Developer account; PLANNING §12 Q1). Unknown paths show "This link needs a newer version of the app" with "Open in the browser instead". | PRD M1 |
| FR-006 | The invite screen chooses G1, G2, G5, G6 or G7 (and the paused, already-going and bookings-paused variants) from the invite view as S6 PLANNING §4.3 lists. | PRD Flows, Edge cases, Lifecycles |
| FR-007 | G1 and G2 show the photo, title, date and time in the activity's zone with the zone named, price with "pay the host on the day", host, who's going (`PublicPerson`), live spots, the no-hold line and the location with a native map. | PRD Flows; Maps FR-009; UX-1 |
| FR-008 | Live spots follow the six realtime rules with `platform=ios|android`; the socket closes in the background and resumes with a refetch on foreground. | `packages/contracts/src/realtime.ts`; PRD A2, A3, R3 |
| FR-009 | After the invite's first frame, the app sends one open beacon with the device ID and its platform. | PRD Scope challenge 2; S4 FR-006 |
| FR-010 | G3 claim: two fields (display name, phone or email) with the rail disclosure for a new guest; "Claiming as {Name} / {masked contact} · saved on this phone / Not you?" for a signed-in guest. One idempotency key per attempt, reused on retry. Rejections map as S6 FR-009. | PRD Flows (Zainab 3), Identity, I6; UX FR-006 |
| FR-011 | G4 You're in shows the booking reference, members, the native map and directions, "See the plan" and "Invite a friend"; directions offer Apple Maps or Google Maps on iOS. | PRD Flows (Zainab 4), A5; Maps FR-011; UX-2 |
| FR-012 | Haptic feedback on claim success and on landing on sold out; native skeletons while loading. | PRD M3 |
| FR-013 | B4 Plan shows members, sources, invite statuses live, the own booking reference, the map and the removed state; when `canInvite`, "Invite a friend" creates a vouch or opens the public link and hands it to the native share sheet with the copy deck's message. | PRD L1, I1–I3, Flows (Zainab 5) |
| FR-014 | B6 My plans lists upcoming and past Plans with activity, date, reference, members and live spots, with removed, empty and loading states. | PRD L2, Q14 |
| FR-015 | The last viewed invite and the last My plans list are cached on the device with their fetch time and shown offline with "Last updated …" (or "Showing your saved plans."), the stale badge and the location text; offline the map area shows "Map unavailable offline". | PRD M2; Maps FR-013 |
| FR-016 | Offline, Claim is disabled with "Reconnect to claim"; no claim or booking is ever queued. | PRD M2, Edge cases |
| FR-017 | P1 profile, X1 sign in (for My plans on a new device) and X4 errors (not found, server error with retry, newer app needed) as designed. | PRD Q10, Q14; UI design P1, X1, X4 |
| FR-018 | If the map can't load or no key is configured, the address, meeting point and directions still show and claiming is unaffected. | PRD A7; Maps FR-012 |
| FR-019 | The app's Android package, signing certificate fingerprints and iOS app ID are supplied to S6's association configuration. | S6 FR-017 |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | Every screen renders without overflow at 360 px wide, and at 390 px with text scaled to 200%. | UI design FR-015, UI-D5 |
| NFR-002 | Touch targets ≥ 44 × 44; semantic labels on every control; spots changes announced politely at most once per 5 s; reduced motion respected. | UX NFR-001–004 |
| NFR-003 | Latest stable Flutter and packages, pinned exactly (`.fvmrc`, `pubspec.lock`). | CLAUDE.md |
| NFR-004 | Platform minimums are the higher of iOS 15 / Android 8 and what the pinned Flutter and packages require, recorded in Part B. | MVP plan §10 |
| NFR-005 | `dart format`, `flutter analyze` and `flutter test` pass in CI. | CLAUDE.md |
| NFR-006 | Release builds use HTTPS only and log no request bodies or headers. | PLANNING §5 |

## Use cases

- **Zainab with the app:** taps Tunde's link → app opens on the invite → Claim → haptic → "You're in".
- **Code from a voice call:** opens the app, types `K7PQ2N`, sees the invite.
- **Patchy signal:** reopens the app offline → the saved invite and "Reconnect to claim".
- **Generation 2:** from the Plan, Zainab invites her friend through WhatsApp.

## Acceptance criteria

- **AC-001:** UI design flow 3 (code entry → invite → claim) and flow 1's app path (link → claim → You're in → Plan → My plans) complete on Android and iOS against the deployed stack.
- **AC-002:** a verified Android App Link opens the app on a real device or emulator. (iOS Universal Links out of scope, PLANNING §12 Q1.)
- **AC-003:** in airplane mode, the last invite and My plans show from cache with their labels, and Claim is disabled.
- **AC-004:** with the app and a browser on one invite, a claim in the browser updates spots in the app within the realtime target, and sold out appears with a haptic.
- **AC-005:** widget tests pass at 360 px and at 200% text scale for every screen.
- **AC-006:** the Dart client drift check passes in CI.

## Business rules and edge cases

As S6: invites don't hold spots; sold out isn't an invite state; vouches are single use and the guest's own claim shows their booking; invites expire at start; invalid codes are rate-limited per device and shown inline; offline claims are never queued; a recognised guest skips the name and contact step.

## Error handling and failure behavior

- Network failure → retry states with the same idempotency key; cached content where available.
- `401` → token cleared, guest treated as signed out.
- Socket loss → stale badge, 10 s polling, reconnect.
- Map failure → address block.
- Unknown deep link → X4 with browser fallback.

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | Token and device ID in platform secure storage; never in `shared_preferences` or logs. | MVP plan §4.6 |
| SEC-002 | The raw contact is never stored on the device; only a masked form for display. | PRD Privacy |
| SEC-003 | Public screens show only `PublicPerson`; full names only in the Plan and G4 (the guest is then a member). | PRD Q12 |
| SEC-004 | Maps keys are restricted per platform and not committed to the repository. | Maps §5.5 |
| SEC-005 | Deep links accept only `/i/<code>` with a valid code shape; anything else goes to X4. | PLANNING §4.6 |

## Performance and reliability

Skeletons immediately; cached content first on revisit; map only on detail screens; socket closed in background. Mobile timings are measured in S8.

## Compatibility constraints

iOS and Android phones, portrait, 360–430 px wide; minimums per NFR-004; tablets show the phone layout centred.

## Data and migration

None on the server. Device storage: secure storage (token, device ID), `shared_preferences` (cache, local profile).

## Dependencies and integrations

S3, S4 APIs; S5 tokens; S6 association files; Google Maps SDKs (owner's keys).

## Explicitly excluded functionality

Hosting, activity and community pages, admin, push, payments, waitlist, tablets and landscape layouts, app-store publication, TestFlight, release builds and iOS Universal Links (PLANNING §12 Q1, Q2, decided 2026-11-04).
