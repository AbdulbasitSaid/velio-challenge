# Requirements: S7b Flutter web parity

## Purpose and scope

Bring the Flutter app to parity with the web app: communities, activity pages with direct booking, the Host / Booker toggle, My activities, create and edit with photo and location, and live attendance. Design: `PLANNING.md`. Screen IDs refer to `spec/2026-11-03_10-34_complete-ui-design/`.

## Goals and non-goals

- **Goals:** every web flow for bookers and hosts works natively on iOS and Android with the same rules and copy; S7 guest flows are unchanged.
- **Non-goals:** API, contract or web changes; admin and metrics pages; push notifications; tablets and landscape (UI-D5); offline caching of host screens (PRD M2 covers the last activity and My plans only).

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | A Booker / Host toggle on every top-level screen switches the interface and is remembered on the device; switching goes to code entry (booker) or My activities (host). | PRD W1, Rules |
| FR-002 | In booker mode, a bottom bar offers Explore, Code and My plans. The app still opens on code entry. | PLANNING §4.1 |
| FR-003 | C1 community: cover, name, blurb and count line; list of activities with live spots; a List / Map toggle when Maps is on, with the map showing only activities with spots; empty state. | PRD A2, A6; S5 FR-020, FR-022 |
| FR-004 | B1 activity: photo with live spots, title, date and time in the activity's zone, venue, price, capacity, who's going, host, About and location, with the host, already going, removed, started, paused, sold out, signed out and offline states as the web shows them. | PRD A2, A3, A5, B1; S5 FR-023, FR-024 |
| FR-005 | Book sends one `Idempotency-Key` per attempt, reused on retry until a final outcome. Success shows "You're in" with a medium haptic. Sold out shows "Someone just took the last spot." with a heavy haptic and next steps. A server or network error offers "Try again" and books once at most. | PRD B1, B2, M3, Edge cases; S5 FR-025 |
| FR-006 | H3 My activities: Upcoming and Past, each card with booked of capacity and the web's status chip (`hostRow`); Create; empty state; signed-out hosts are asked to sign in. | PRD W1; S5 FR-032 |
| FR-007 | H2 create: photo, title, description, community, date, time, time zone, location (Places search, pin, venue, address), meeting point, price and spots, with the copy deck's validation and summary. Publish creates the activity and shows "Published. {title} is live in {community}." | PRD A1, A4, Q2, Q13; S5 FR-033 |
| FR-008 | H2 edit: changed fields only; after the first booking, date, time, zone and location are locked with the locked banner; spots never below bookings; price and community are read-only; `location_locked` and `capacity_below_bookings` land on their fields. | PRD A1, Q2; Maps FR-005; S5 FR-034 |
| FR-009 | The photo is centre-cropped to 16:10, uploaded as 1280 px and 640 px JPEGs with the presigned POSTs; unreadable and upload failures show the web's messages. | S5 FR-013; PRD Q5 |
| FR-010 | Location search uses Places API (New) when a key is configured. Without a key, or when search fails, the host drops a pin, or types venue, address and coordinates when Maps is off. | Maps FR-017, FR-021 |
| FR-011 | H1 attendance: booked or marked count with live spots; guests with ref, booked time and source; live updates on `host:<id>`; guest search by name or ref. | PRD H1, D5; S5 FR-035, FR-038 |
| FR-012 | Before the start, Remove asks for confirmation, then removes and shows "{Name} removed. Their spot is open again." From the start (also while the screen is open), each guest is marked Attended or No-show, the latest mark winning, with the web's failure messages. | PRD H1, H2, D3; S5 FR-036, FR-037 |
| FR-013 | Activity links in next steps, the Plan and the profile open the in-app activity page. | PLANNING §4.2 |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | Every new screen renders without overflow at 360 px, and at 390 px with text at 200%. | UI-D5; S7 NFR-001 |
| NFR-002 | Touch targets ≥ 44; semantic labels on controls; spots changes announced politely on B1 and H1. | UX NFR-001–003 |
| NFR-003 | New packages are the latest stable, pinned exactly. | CLAUDE.md |
| NFR-004 | `dart format`, `flutter analyze` and `flutter test` pass. | S7 NFR-005 |

## Use cases

- **Tunde books directly:** Explore → Sunset Kayaking → Book → "You're in" → Invite a friend.
- **Amara hosts on her phone:** Host → Create → photo, place, date → Publish → shares the page; on the day, marks who came.

## Acceptance criteria

- **AC-001:** against local Compose or the deployed stack, a booker books from Explore and lands on "You're in"; a host creates an activity with a photo, edits it, and sees a booking arrive in attendance live.
- **AC-002:** unit tests cover the ported rules (validation, zoned time, price, patch body, booking outcomes, attendance stats, ordering, search, host rows, save failures).
- **AC-003:** widget tests pass at 360 px and at 200% text for C1, B1, H1, H2 and H3 in their main states.
- **AC-004:** S7's existing tests still pass.

## Business rules and edge cases

As S5: no overselling (the API decides); bookings close at the start; capacity never below bookings; date, time and place lock after the first booking; price and community are set once; marking opens at the start; removal is before the start and always confirmed; a host can't book their own activity.

## Error handling and failure behavior

- Network failure on load → X4 offline with retry; on Book or Save → retry banner, same key.
- `401` → signed out (S7 behavior); host screens show the sign-in prompt.
- `403` or `404` on host screens → X4 not found (S5 SEC-008).
- Places or Maps failure → the fallback in FR-010.

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | Presigned S3 uploads carry no `Authorization`, `X-Device-Id` or `traceparent` header. | PLANNING §4.5 |
| SEC-002 | The host sees names, refs and sources, never contacts or notes. | PRD H1, Privacy |
| SEC-003 | The Places key is never committed; it comes from a build-time define. | Maps §5.5 |

## Performance and reliability

Photo processing runs off the UI thread. Live updates follow the six realtime rules, as in S7.

## Compatibility constraints

iOS 15+, Android 8+ (S7). `image_picker` needs a photo-library usage string on iOS.

## Data and migration

None. The role preference is new local state.

## Dependencies and integrations

API endpoints listed in PLANNING §4.6; Google Places API (New), optional.

## Explicitly excluded functionality

Admin and metrics; camera capture; editing price or community; cancelling a booking as a booker (PRD Next, X3).
