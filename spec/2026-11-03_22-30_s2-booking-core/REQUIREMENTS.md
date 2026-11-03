# Requirements: S2 Booking core

## Purpose and scope

The booking engine and the endpoints around it: direct booking, host removal, activity creation and editing with capacity changes, booking metrics, the concurrency test and the first k6 smoke run. Parent IDs refer to `spec/2026-11-03_07-42_group-bookings-mvp-plan/REQUIREMENTS.md`. Design: `PLANNING.md` in this directory.

## Goals and non-goals

- **Goals:** zero overselling, proven by parallel tests against real Postgres; typed failures; idempotent retries; one engine that S4's claims reuse.
- **Non-goals:** invites, claims, attribution (S4); realtime listener, WebSockets and the activity snapshot (S3); photo upload, any UI (S5–S7); admin endpoints, the oversell job and dashboards (S8); full-scale load runs (S9).

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | `POST /api/activities/:id/bookings` (authenticated, `Idempotency-Key` required) either books one spot, decrementing `spots_left` by exactly 1, or fails with a typed reason and changes nothing. | PRD B1 |
| FR-002 | Rejection codes and statuses: `sold_out` 409, `already_booked` 409, `activity_started` 409, `bookings_paused` 409, `not_found` 404, `forbidden` 403 (host booking their own activity), `idempotency_conflict` 409, `validation_failed` 400 (missing or malformed key), `unauthenticated` 401. | PRD B1, edge cases, business rules; PLANNING §4.2, §4.6 |
| FR-003 | Request validation (`validation_failed`) and idempotent replay or `idempotency_conflict` are decided first. After that, when several reasons apply, the code returned follows this order: `not_found`, `forbidden`, `already_booked`, `activity_started`, `bookings_paused`, `sold_out`. | PLANNING §4.2 [Proposal] |
| FR-004 | A repeated request with the same user and `Idempotency-Key` for the same activity returns `200` with the original booking and writes nothing, including when the requests run in parallel. The same key for a different activity returns `idempotency_conflict`. | PRD B2, edge case "server error on booking" |
| FR-005 | A person holds at most one confirmed booking per activity; a second attempt with a new key returns `already_booked`. | PRD B2 |
| FR-006 | A successful direct booking creates a new Plan owned by the booker, in the same transaction, and the booking references it. | PRD B3, business rules (Plans) |
| FR-007 | Every booking gets a unique reference `VLO-` + 5 characters from `23456789ABCDEFGHJKMNPQRSTUVWXYZ`, generated in the booking transaction and retried on collision. | PRD business rules (booking reference) |
| FR-008 | The success response is `201 { booking { id, ref, activityId, planId, source, status, createdAt }, activity { id, spotsLeft, version } }`. | PLANNING §4.2 |
| FR-009 | Bookings close at the activity's start time and while `bookings_paused` is true. | PRD business rules, Operations (kill switch) |
| FR-010 | The engine accepts `source`, `planId`, `inviteId` and an in-transaction extension callback, so S4's claims run through the same transaction and rules. S2 exposes only the direct path. | PRD I6 |
| FR-011 | Every committed change to `spots_left` (booking, removal, capacity change) increments `activities.version` and emits `pg_notify('activity_spots', {activityId, spotsLeft, version, committedAt})` in the same transaction. | PRD NFR live availability; MVP plan §4.4, §4.5 |
| FR-012 | `POST /api/host/bookings/:id/removal`, by the activity's host only, sets the booking to `removed`, increments `spots_left` by 1, and inserts a `booking_removals` row, in one transaction. Repeating it on a removed booking returns `200` and frees nothing more. Non-host → `403 forbidden`; unknown booking → `404 not_found`. | PRD H1, D3, business rules (Host removal) |
| FR-013 | `POST /api/activities` (authenticated) creates an activity owned by the caller, with community, title, description, start time, IANA time zone, location (optional place ID, venue name, address, lat, lng, optional meeting point ≤ 140 characters), price in minor units, currency and capacity; `spots_left` starts equal to capacity. Start time must be in the future. Returns `201` with `HostActivity`.  | PRD A1, A4; Maps spec FR-005 |
| FR-014 | `PATCH /api/activities/:id` (host only) changes title, description, start time, time zone, location and capacity. Date, time zone or location changes after the first confirmed booking return `409 location_locked`. A rejected edit changes nothing. | PRD Q2, Q13 |
| FR-015 | Capacity can be raised at any time and lowered only down to the number of confirmed bookings; lower than that returns `409 capacity_below_bookings`. Capacity is always at least 1; 0 returns `400 validation_failed`. `spots_left` moves by the same difference. Raising capacity on a sold-out activity reopens it. | PRD business rules (Capacity), Lifecycles |
| FR-016 | Each rejected booking attempt records an `events` row `booking_rejected` with the reason; each success records `booking_succeeded` inside the transaction. | PRD Success metrics (funnel events) |
| FR-017 | After each successful booking, the engine checks confirmed bookings against `capacity − spots_left` for that activity; a mismatch logs `oversell_detected` and increments `oversell_detected_total`. | PRD Operations (oversell check), MVP plan §4.9 |
| FR-018 | A person whose booking on an activity the host removed can't book that activity again: `409 booking_removed`, checked after `already_booked` in the FR-003 order. Their replay of the removed booking still returns it (`200`, `status: removed`). | User decision 2026-11-03 (PLANNING §12, Q2); not in the PRD |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | Overselling is impossible by construction: the spot is taken with a single conditional `UPDATE … WHERE spots_left > 0` inside the booking transaction, with the database check constraint as the backstop. No application-level lock or counter. | PRD NFR correctness, R1 |
| NFR-002 | With M parallel requests for an activity with N spots (N ∈ {1, 5, 14}, M = 200), exactly N succeed, M − N get `sold_out`, and confirmed bookings equal capacity. This test runs in `bun test` against real Postgres, so CI runs it on every push. | PRD NFR correctness, R1; parent NFR-001 |
| NFR-003 | The booking transaction makes no network calls besides the database and holds the activity row lock for its statements only. | PRD R2 |
| NFR-004 | Booking, removal and capacity change lock the activity row before any `bookings` row, so they can't deadlock each other. | PLANNING §4.2 |
| NFR-005 | Metrics `booking_attempts_total` and `booking_duration_seconds` (labels `outcome`, `path`), `booking_row_wait_seconds`, `booking_removals_total` (`outcome`) and `oversell_detected_total` exist and carry no other labels. | MVP plan §4.12; CLAUDE.md |
| NFR-006 | The k6 `last_spot_race` smoke (25 VUs per activity, N ∈ {1, 5, 14}) against local Compose returns exactly N `201`s per activity, and the post-run SQL check finds no oversold activity. | MVP plan §4.13; ROADMAP Phase 2 exit |
| NFR-007 | Booking latency has no PRD target; S2 sets none. S9 records the baseline. | MVP plan §4.13 |

## Use cases

- **Tunde books** Sunset Kayaking with 3 spots left → `201`, a Plan, `VLO-…`, 2 spots left.
- **Tunde's network drops** after he taps; the app retries with the same key → the same booking, still 2 spots left.
- **500 people race** for the last spot → one booking, everyone else sees "Someone just took the last spot".
- **Amara removes** a guest who got a vouch meant for someone else → the spot is free for the next booker.
- **Amara adds two spots** to a sold-out session → it reopens with 2 spots.

## Acceptance criteria

- **AC-001:** the concurrency test (NFR-002) passes locally and its command runs in CI.
- **AC-002:** 20 parallel requests from one user with one key create one booking; all 20 responses carry the same booking ID.
- **AC-003:** a removal racing 20 bookings on a sold-out activity leads to exactly one new booking.
- **AC-004:** lowering capacity below confirmed bookings returns `capacity_below_bookings` and leaves capacity, `spots_left` and `version` unchanged.
- **AC-005:** the k6 smoke (NFR-006) passes, with its summary recorded in `VALIDATION.md` Part B.
- **AC-006:** after every concurrency round, `capacity − spots_left` equals the confirmed bookings for the activity.

## Business rules and edge cases

- A host cannot book their own activity (PRD business rules).
- Bookings close at start time; time is the database's `now()` at the decrement.
- A replay of a booking that the host has since removed returns that booking with status `removed`.
- A removed person can't rebook the same activity (FR-018).
- Removal after the start time is allowed [Assumption, PLANNING §12].
- Setting capacity to its current value is a no-op and doesn't bump `version`.

## Error handling and failure behavior

- Every rejection uses the S1 envelope `{ error: { code, message, requestId } }`.
- A database error during the transaction rolls everything back (spot, Plan, booking, event) and returns `internal`; a retry with the same key is safe (FR-004).
- Failure to write a `booking_rejected` event is logged and never changes the response.
- A trigger time-zone error (`VL004`) becomes `validation_failed`.

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | Every S2 endpoint requires a session. Host actions (edit, capacity, removal) check that the caller is the activity's host, inside the transaction that writes. | PRD business rules (Identity) |
| SEC-002 | Metrics, spans and logs carry no user IDs, contacts, tokens, idempotency keys or booking references; metric labels never carry entity IDs. Activity IDs may appear on spans and in logs. | CLAUDE.md; parent SEC-011 |
| SEC-003 | Booking and host responses expose no contact details. | PRD D5, Privacy NFR |

## Performance and reliability

NFR-001–NFR-004. Pool size stays at 10 [Assumption]; S9 tunes it under full load.

## Compatibility constraints

- Contracts additions are backwards-compatible: new schemas and two new error codes.
- k6 image: the latest stable `grafana/k6` release, pinned by exact tag, recorded in Part B.

## Data and migration

No migration. All tables, constraints and grants exist from S1. The k6 smoke writes test data to the local development database only.

## Dependencies and integrations

S1 (schema, identity, errors, telemetry). Docker for k6. No new npm dependencies. No AWS, Grafana Cloud or Google Maps.

## Explicitly excluded

Invite claims, attribution and trust edges; the `LISTEN` bridge and WebSockets; `GET /api/activities/:id`; photo upload; the kill-switch endpoint; the oversell job and `oversell_activities` gauge; SQL metric views; booker cancellation and waitlist (PRD X1, X3); any UI; full k6 suite and hosted load runs.
