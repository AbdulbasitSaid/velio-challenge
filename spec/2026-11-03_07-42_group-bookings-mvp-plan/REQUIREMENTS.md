# Requirements: Group Bookings MVP

## Purpose and scope

The verifiable requirements for the MVP (PRD P0 plus its metrics, flag and rollout tooling). They refine the PRD into checkable statements. Delivery specs S1–S9 inherit these IDs; they do not renumber them.

## Goals and non-goals

- **Goals:** the PRD's five targets (zero oversell, ≥ 99.5% booking success on available spots, p95 ≤ 2 s live updates, 30% invite rate, 25% vouch open-to-claim), plus trustworthy attribution and a measurable holdout.
- **Non-goals** (PRD): payments, full authentication, trust scores, host verification. Also: push, email or SMS sent by Velio; waitlist; booker cancellation; vouch holds (P1).

## Functional requirements

| ID | Requirement | PRD |
| --- | --- | --- |
| FR-001 | A signed-in user can create an activity with title, description, one photo, start time, IANA time zone, location (place ID, pin, venue name, address, optional meeting point; amended 2026-11-03), price (minor units and ISO currency) and capacity ≥ 1. | A1 |
| FR-002 | The activity page shows spots left and updates without refresh on every connected web and mobile client after any booking, removal or capacity change. | A2 |
| FR-003 | When spots left reaches 0, every connected client shows Sold out and the book or claim action is disabled. | A3 |
| FR-004 | A booking attempt either confirms a booking and decrements spots left by exactly 1, or returns exactly one typed error (`sold_out`, `already_booked`, `activity_started`, `bookings_paused`, or a generic error) and changes nothing. | B1 |
| FR-005 | A user has at most one confirmed booking per activity. Repeating a request with the same idempotency key returns the original result. | B2 |
| FR-006 | A direct booking creates a Plan owned by the booker. A claim adds the guest to the Plan the invite came from. | B3, Business rules |
| FR-007 | The Plan view lists members, how each joined (direct, via inviter name, public link) and each invite's status (created, opened, claimed). | L1 |
| FR-008 | Any Plan member can create a vouch invite with an invitee name, an optional contact and an optional note. It can be claimed at most once. | I1 |
| FR-009 | Any Plan member can create a public link that can be claimed many times until sold out, paused or started. | I2 |
| FR-010 | Every invite has a unique 6-character code from the alphabet `23456789ABCDEFGHJKMNPQRSTUVWXYZ` and a deep link `/i/<code>`. | I3 |
| FR-011 | A claim by a user created in that claim writes one attribution record (inviter, invitee, rail, invite, generation = inviter generation + 1). A later claim never changes it. A later vouch for an existing user writes a trust edge instead. | I4, D4 |
| FR-012 | Claims run through the same transaction as FR-004 and FR-005. A vouch is consumed in that transaction, and claim-specific errors are `already_claimed`, `invite_expired`, `invite_paused` and `invalid_code`. | I6 |
| FR-013 | The host's attendance view lists each confirmed attendee's display name, booking time and source, updates live, and never shows contact details or invite notes. | H1, D5 |
| FR-014 | A host can remove an attendee. Spots left increments in the same transaction and the removed guest's Plan shows the removal. | H1, D3 |
| FR-015 | After start time, a host can mark each attendee as attended or no-show. A later mark supersedes an earlier one without deleting it. | H2 |
| FR-016 | The web app offers a Host / Booker toggle that switches the interface. Host actions are permitted only on activities the user hosts. | W1 |
| FR-017 | Opening `/i/<code>` opens the Flutter app when installed, and otherwise a web claim page with the same flow. The app also accepts a typed code. | M1 |
| FR-018 | The app shows the last viewed activity offline with a "Last updated" time, and disables Claim offline. No claim is queued. | M2 |
| FR-019 | The app gives haptic feedback on claim success and sold out, and shows loading skeletons. | M3 |
| FR-020 | An open is recorded once per invite per device, only after a client has rendered the invite page. | Scope challenge 2, R9 |
| FR-021 | Capacity can be changed only to a value ≥ confirmed bookings. Date, time and location (every location field, including the meeting point) cannot change once a booking exists. | Business rules (Q2, Q13) |
| FR-022 | Bookings and claims are rejected after start time. Invites expire at start time. | Edge cases |
| FR-023 | A host cannot book their own activity. | Business rules |
| FR-024 | Admins can pause bookings on an activity. Hosts and link creators can pause a public link. A paused link shows a clear state and rejects claims. | Operations, R1, R7 |
| FR-025 | Every edge-case state in the PRD's Edge cases table is implemented with the stated copy and next step. | Edge cases |
| FR-026 | The funnel events and technical events listed in the PRD are emitted with user, activity, invite, rail, generation, platform and timestamp. | Success metrics |
| FR-027 | 10% of users are assigned to the holdout by a stable hash of user ID, recorded at first exposure. The API returns no invite tools to them. | Holdout design |
| FR-028 | An admin page shows each PRD goal metric, per-rail funnel, K-factor and the guardrail, split by arm. | Release plan |
| FR-029 | Communities exist as seeded records (name, slug, blurb, cover photo). Every activity belongs to one. A community page lists its upcoming activities with spots left. | Q11 |
| FR-030 | The sold-out and expired screens offer "Tell [inviter]" (share sheet, prefilled), the host's other upcoming dates, and "More in [community]": up to 3 upcoming activities in the same community with spots, soonest first. Each block is hidden when empty. | Q9, Edge cases |
| FR-031 | A profile page shows the public-form name, initials avatar, "On Velio since [month year]" and upcoming hosted activities, and never bookings or Plans. | Q10 |
| FR-032 | Avatars render initials on a colour picked deterministically from a fixed palette, identically on web and Flutter. | Q8 |
| FR-033 | Every confirmed booking has a unique reference `VLO-XXXXX`, shown on the guest's success card and Plan and in the host's attendance list. It is never part of a public URL. | UX-2 |
| FR-034 | Wherever a price is shown it reads "{price} · pay the host on the day". There is no checkout step. | UX-1, Non-goals |
| FR-035 | Location is set with Google Places search and a draggable pin, shown with a map, address and "Get directions" on activity, invite, "You're in" and Plan screens (interactive native map in Flutter), and on a community map view. Maps never block booking. Detailed in `spec/2026-11-03_10-34_google-maps-locations/`. | A4–A7, Q13 |
| FR-036 | My plans lists the session user's Plans, upcoming and past, with activity, date, booking reference and members, on web and Flutter (`GET /me/plans`). | L2, Q14 |

## Non-functional requirements

| ID | Requirement | PRD |
| --- | --- | --- |
| NFR-001 | Confirmed bookings never exceed capacity, under any concurrency. Enforced by database constraints and conditional writes. | Goals, NFR |
| NFR-002 | ≥ 99.5% of booking attempts on activities with spots available at attempt time succeed. | Goals |
| NFR-003 | p95 from commit to client render ≤ 2 s, measured on the server clock from commit to the client's render ack. | Goals, NFR |
| NFR-004 | Invite page first content < 1.5 s on mid-range Android over 3G (Lighthouse throttled profile). | NFR |
| NFR-005 | WCAG 2.1 AA contrast. Spots-left changes are announced politely and throttled. | NFR |
| NFR-006 | Clients ignore realtime events with a version ≤ the current one, re-fetch a snapshot on reconnect, and poll every 10 s while disconnected. | NFR, R3 |
| NFR-007 | At 10× the assumed peak (PRD Q4: 500 bookers on one activity within 10 s, 5,000 concurrent viewers), NFR-001, NFR-002 and NFR-003 still hold. | R2, Q4 |
| NFR-008 | The database is backed up nightly to S3 (14-day retention) and a restore procedure is documented and tested once. | §4.11 |
| NFR-009 | WebSocket connections survive idle periods through CloudFront (server ping every 30 s). | §4.11 |
| NFR-010 | The API and web app emit the metrics in PLANNING §4.12, with route-template, outcome and platform labels only (never entity IDs), and they appear in Grafana Cloud within 1 minute [Assumption: chosen for usefulness, not from the PRD]. | §4.12 |
| NFR-011 | Every API request produces a trace, sampled at the collector as in §4.12: all errors and every trace over 1 s are kept, plus 10% of the rest. Logs are JSON and carry `trace_id` and `request_id`. | §4.12 |
| NFR-012 | Alerts fire on the PRD triggers: oversell > 0, booking success < 99.5% over 1 h, realtime p95 > 2 s for 15 min. | Success metrics, §4.12 |
| NFR-013 | Web vitals from real invite-page loads and the Flutter link-to-render and claim-to-confirm timings are collected as histograms. | NFR performance, §4.12 |
| NFR-014 | The k6 suite in §4.13 is version-controlled, can be rerun with one command per environment, and every full run stores its summary in `load/results/` and records a booking-latency baseline. | R2, §4.13 |

## Security and privacy

| ID | Requirement | PRD |
| --- | --- | --- |
| SEC-001 | Invites, claims, attribution, trust edges, removals and attendance marks are insert-only. The API role has no UPDATE or DELETE on them, and a trigger rejects either. | I5, NFR |
| SEC-002 | Attribution rows carry a per-activity hash chain, and an audit job detects any break. | NFR, R11 |
| SEC-003 | Contact details never appear in URLs, logs or host-facing responses. | NFR, D5 |
| SEC-004 | Contacts are stored as salted hashes for matching. Raw vouch contacts are deleted after the retention window. | R5, Q7 |
| SEC-005 | More than 10 invalid codes per device per hour are rejected with `rate_limited`. | R10 |
| SEC-006 | Public links are rate-limited per link and auto-paused on the R7 signal. | R7 |
| SEC-007 | Session tokens are random, stored hashed, and sent as httpOnly secure cookies on web and kept in secure storage on mobile. | — |
| SEC-008 | Identity is unverified (prototype). This must be replaced before general availability. | Non-goals |
| SEC-009 | The origin accepts traffic only from CloudFront (managed prefix list plus a secret origin header). There is no SSH. Known limitation: CloudFront reaches the origin over HTTP, which must be fixed before real users. | §4.11 |
| SEC-010 | Postgres is not reachable from outside the instance. EBS volumes and S3 buckets are encrypted, and S3 buckets are private (CloudFront OAC only). | §4.11 |
| SEC-011 | No contact details, invite notes, session tokens or invite codes appear in any metric, span attribute or log line; codes in logged paths are redacted. Grafana Cloud credentials are stored as secrets, never in the repository. | §4.12 |
| SEC-012 | Public endpoints (activity, invite, profile, community, next-steps) return people only as `PublicPerson` ("First L."). Full display names are returned only to Plan members and to the activity's host. | Q12, D5 |

## Acceptance criteria

- **AC-001:** 50 parallel booking requests on an activity with N spots (N ∈ {1, 5}) produce exactly N confirmed bookings, 50 − N `sold_out` responses, and spots left = 0.
- **AC-002:** two parallel claims of one vouch code produce one booking and one `already_claimed`.
- **AC-003:** repeating a booking request with the same idempotency key 5 times produces one booking.
- **AC-004:** a booking on one client updates spots left on another connected client, and the measured p95 is ≤ 2 s over 100 bookings in a test environment.
- **AC-005:** an invite page fetched by a link-preview user agent shows OG tags and records no open.
- **AC-006:** a new guest claiming Tunde's vouch gets generation = Tunde's + 1. A second claim by that guest elsewhere leaves their attribution unchanged.
- **AC-007:** UPDATE or DELETE on any insert-only table fails for the API role.
- **AC-008:** a holdout user's Plan response contains no invite actions.
- **AC-009:** every PRD edge-case row is reproducible and shows its specified copy.
- **AC-010:** the admin page's counts reconcile with direct SQL counts.

## Business rules and edge cases

As in the PRD's Business rules, Lifecycles and Edge cases sections. Those sections are normative for this spec.

## Error handling

All API errors return `{ "error": { "code": "<typed code>", "message": "<user-safe text>" } }`. Clients map codes to the PRD's copy. No raw errors reach users.

## Compatibility

- Web: the latest two versions of Chrome, Safari, Firefox and Edge; iOS Safari 16+; Android Chrome.
- Mobile: iOS 15+, Android 8+ [Assumption].

## Data and migration

New schema from scratch. Migrations are forward-only SQL files. No legacy data.

## Dependencies

- An AWS account (eu-west-2) for EC2 (including spot for the load runner), CloudFront, S3 and SSM.
- A Grafana Cloud free-tier stack (OTLP endpoint and Prometheus remote write).
- k6.
- A GitHub repository with Actions and GHCR.
- A Google Cloud project with billing and Google Maps Platform APIs, created by the owner when S10 starts.
- PostgreSQL 16+.
- Apple and Google developer accounts for Universal Links and App Links on device builds, served from the CloudFront hostname.

## Explicitly excluded

Payments, waitlist, booker cancellation, vouch holds, push, email or SMS from Velio, activity cancellation by the host (Q1), real authentication, trust scores, host verification, and integration with Velio's production systems.
