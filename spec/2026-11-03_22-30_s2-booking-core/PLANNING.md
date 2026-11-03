# Planning: S2 Booking core

- **Spec ID:** 2026-11-03_22-30_s2-booking-core
- **Created:** 2026-11-03 22:30 (local)
- **Status:** Implemented
- **Phase:** 2, Correctness core (`ROADMAP.md`)
- **Parent:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (approved), delivery step S2
- **Builds on:** `spec/2026-11-03_09-29_s1-foundations/` (implemented)
- **PRD:** `Velio Group Bookings PRD.md`

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

Phase 2 has to prove the PRD's hardest promise: **an activity is never oversold** (PRD R1, goal "Never oversell"). Nothing in the codebase books a spot yet. S1 built the schema and its constraints, but there is no booking transaction, no way for a host to create an activity or change its capacity, no host removal, and no test that fires real parallel requests at the last spots.

Every later spec depends on this engine: S3 broadcasts its commits, S4 runs claims through it (PRD I6), and S5–S7 put buttons on it.

## 2. Context and current behavior

- [Verified, `apps/api/migrations/20261103140100_schema.sql`] The schema S2 needs already exists and needs **no migration**:
  - `activities.spots_left` with `CHECK (spots_left >= 0 AND spots_left <= capacity)`, plus `version` and `bookings_paused`;
  - `bookings` with the partial unique index `bookings_one_confirmed_per_user (activity_id, user_id) WHERE status = 'confirmed'`, the unique constraint `bookings_user_idempotency_key (user_id, idempotency_key)`, and unique `ref` checked against `^VLO-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$`;
  - `plans`, `booking_removals` (insert-only, trigger-guarded) and `events`;
  - the location-lock trigger, which raises SQLSTATE `VL001` (`location_locked`) when the date, time zone or location changes on an activity with a confirmed booking.
- [Verified, same file] `velio_api` has `SELECT, INSERT, UPDATE` on `activities`, `plans`, `bookings` and `events`, and `SELECT, INSERT` on `booking_removals`. That covers every S2 write.
- [Verified, `apps/api/src/app.ts`, `errors.ts`] Routes mount on an `OpenAPIHono` app under `/api`; `ApiError` plus `app.onError` is the single error path; `fromPostgresError` maps trigger SQLSTATEs to codes.
- [Verified, `packages/contracts/src/errors.ts`] The error-code union already holds `sold_out`, `already_booked`, `activity_started`, `bookings_paused` and `location_locked`.
- [Verified, `apps/api/src/modules/identity/middleware.ts`] `requireUser` guards authenticated routes; `c.var.user` is the caller.
- [Verified, `apps/api/src/db/client.ts`] Kysely on postgres.js, pool size 10 by default; `db_pool_in_use` is already instrumented.
- [Verified, `apps/api/test/helpers/`] Each test file gets a fresh database cloned from `velio_test`; fixtures insert users, activities, plans and bookings directly.
- [Verified, MVP plan §6] "Only `modules/bookings` writes to `activities.spots_left`."
- [Verified, MVP plan §4.8] No delivery spec owns the activity create/edit **API**. S5 owns the create-activity **screen**. S2's capacity edit needs `PATCH /activities/:id`, and the k6 smoke needs activities created without test-only bypasses (MVP plan §4.13). See §12, Q1.

## 3. Desired outcome

- A direct booking either succeeds and takes exactly one spot, or fails with a specific typed reason, never both (PRD B1).
- Retries and repeat taps never book twice (PRD B2).
- A direct booking creates a Plan owned by the booker (PRD B3).
- A host can create an activity, edit it within the business rules, change its capacity (never below confirmed bookings), and remove an attendee, freeing the spot at once.
- The engine is ready for S4's claims to run through the same transaction (PRD I6).
- **Proof:** a concurrency test in `bun test` fires truly parallel HTTP requests at the last 1, 5 and 14 spots and asserts exactly N succeed; a k6 `last_spot_race` smoke run against local Compose shows the same.
- Booking metrics exist from the first booking.

## 4. Proposed solution

### 4.1 Module layout [Proposal]

```text
apps/api/src/modules/
  activities/
    routes.ts      # POST /activities, PATCH /activities/:id
    service.ts     # create, edit (non-capacity fields)
  bookings/
    engine.ts      # bookSpot, removeBooking, changeCapacity: the only writers of spots_left
    ref.ts         # VLO- reference generation
    routes.ts      # POST /activities/:id/bookings, POST /host/bookings/:id/removal
    metrics.ts     # booking instruments
```

`activities/service.ts` calls `bookings/engine.changeCapacity` for the capacity part of an edit, so the parent rule (only `modules/bookings` writes `spots_left`) holds.

### 4.2 The booking transaction (`bookSpot`)

The MVP plan §4.4 shape, with the S4-only steps left as an extension point.

**Inputs:** `{ activityId, userId, idempotencyKey, source: 'direct' | 'vouch' | 'public', planId?, inviteId?, platform?, extend?(tx, booking) }`. S2 calls it with `source: 'direct'` only. S4 passes `planId`, `inviteId` and an `extend` callback that inserts the claim and attribution rows inside the same transaction.

**Before the transaction** (read checks for clear errors; the database stays the authority):

1. **Idempotent replay:** look up `bookings` by `(user_id, idempotency_key)`.
   - Same activity → return that booking with `200`, whatever its current status. Nothing is written.
   - Different activity → `409 idempotency_conflict`.
2. **Activity exists** → otherwise `404 not_found`.
3. **Host can't book their own activity** (PRD business rules) → `403 forbidden`.
4. **Already booked:** the caller has a confirmed booking on this activity → `409 already_booked`. This also means a repeat tap with a new key never queues on the row lock.

**Transaction** (READ COMMITTED, the Postgres default):

```sql
BEGIN;
-- 1. Take the spot. Locks the activity row; everything below is serialized per activity.
UPDATE activities
   SET spots_left = spots_left - 1, version = version + 1
 WHERE id = $activity AND spots_left > 0 AND starts_at > now() AND NOT bookings_paused
RETURNING spots_left, version, capacity;
--    0 rows → ROLLBACK, then classify by re-reading the row, in this order:
--    activity_started → bookings_paused → sold_out.
-- 2. Direct booking: INSERT plans (activity_id, owner_id = user). Claims reuse $planId.
-- 3. INSERT bookings (ref, …) ON CONFLICT (ref) DO NOTHING RETURNING *;
--    no row → new ref, retry (at most 5 times, then internal).
--    unique violation on bookings_one_confirmed_per_user  → ROLLBACK ⇒ already_booked
--    unique violation on bookings_user_idempotency_key    → ROLLBACK ⇒ replay (step 1 above)
-- 4. extend(tx, booking)  -- S4: invite_claims, attributions. No-op in S2.
-- 5. INSERT events ('booking_succeeded', user, activity, generation, platform).
-- 6. SELECT pg_notify('activity_spots', json {activityId, spotsLeft, version, committedAt}).
COMMIT;
```

- **Why the race is safe** [Verified, PostgreSQL docs, "Transaction Isolation", READ COMMITTED]: a concurrent `UPDATE` waits for the row lock, then re-evaluates its `WHERE` clause against the newly committed row. When the last spot is gone, `spots_left > 0` is false and 0 rows are updated. Overselling would need the `CHECK` constraint to fail too.
- **Idempotency race:** two requests with the same key both pass the replay check. The second waits on the row lock, decrements, then hits the unique constraint at step 3 and rolls back, which restores its spot. It then returns the first booking as a replay.
- **Lock order:** every S2 write path locks the activity row before touching `bookings`, so booking, removal and capacity edit can't deadlock with each other.
- **Nothing slow inside the transaction:** no network calls, no logging I/O. Statements 2–6 are single-row inserts.
- **`committedAt`** is `clock_timestamp()` taken at step 6, the last statement before `COMMIT`. [Proposal; S3 measures latency from it.]
- **`pg_notify` in S2** [Proposal]: emitting the notification now costs one statement, and nobody listens until S3. S3 then adds the listener without touching the engine. Postgres delivers it only on commit (PRD NFR).
- **Rejections:** after the rollback, insert one `events` row `booking_rejected` with `props.reason` (outside the transaction, best-effort: a failure is logged, never returned to the caller). For `not_found`, `activity_id` is null, because `events.activity_id` references `activities` [Verified, schema] and an unknown ID would fail the foreign key. Replays and `idempotency_conflict` record no event.

**Response:** `201 { booking, activity: { id, spotsLeft, version } }` for a new booking; `200` with the same shape on replay, where `activity` is the current state.

### 4.3 Booking reference

`VLO-` plus 5 characters from the invite-code alphabet (`23456789ABCDEFGHJKMNPQRSTUVWXYZ`), drawn with `crypto.randomInt` so there's no modulo bias [Proposal]. About 28.6 million references; a collision is retried through `ON CONFLICT (ref) DO NOTHING`, which suppresses only the `ref` constraint and leaves the others to raise.

### 4.4 Host removal (`removeBooking`)

`POST /api/host/bookings/:id/removal` (MVP plan §4.8; PRD H1, D3).

```sql
BEGIN;
SELECT activity_id FROM bookings WHERE id = $booking;                 -- 404 if missing
-- Caller must be the activity's host → otherwise 403 forbidden.
UPDATE activities SET spots_left = spots_left + 1, version = version + 1
 WHERE id = $activity RETURNING spots_left, version;                  -- locks the row first
UPDATE bookings SET status = 'removed' WHERE id = $booking AND status = 'confirmed' RETURNING id;
--    0 rows (already removed) → ROLLBACK, return 200 with the current state (idempotent; no double free)
INSERT INTO booking_removals (booking_id, removed_by) VALUES ($booking, $host);
SELECT pg_notify('activity_spots', …);
COMMIT;
```

- The freed spot goes to whoever books next (PRD business rules, Host removal).
- Attribution is untouched (PRD Host removal). S2 writes no attribution anyway.
- **Removal after the start time** is allowed [Proposal]: the PRD doesn't restrict it, and bookings are closed by then, so the freed spot can't be taken.
- **Response:** `200 { booking, activity: { id, spotsLeft, version } }`.

### 4.5 Activities API (see §12, Q1)

**`POST /api/activities`** (authenticated; PRD A1, A4):

- Body: `communitySlug`, `title`, `description?`, `startsAt` (ISO 8601 with offset), `timezone` (IANA), `location { placeId?, venueName, addressText, lat, lng, meetingPoint? }`, `priceMinor`, `currency`, `capacity`.
- `spots_left = capacity`, `version = 0`, `host_id = caller`.
- Validation in the contract: `startsAt` in the future; `capacity` a positive integer; `priceMinor` a positive integer; `currency` three upper-case letters; `meetingPoint` at most 140 characters; `lat`/`lng` in range. The database checks remain the authority (S1); an invalid time zone (`VL004`) maps to `validation_failed`.
- **Photo** is not part of S2. `photo_key` stays null until S5 adds the signed upload (PRD Q5).
- Returns `201` with the activity in its **host view** (`HostActivity`: every stored field, plus `bookedCount`).

**`PATCH /api/activities/:id`** (host only → otherwise `403 forbidden`):

- Body: any of `title`, `description`, `startsAt`, `timezone`, `location`, `capacity`.
- Date, time zone and location changes after the first confirmed booking fail with `409 location_locked` (S1 trigger, already mapped).
- **Capacity** goes through `changeCapacity` (below).
- The whole edit runs in one transaction, capacity first, so a rejected capacity leaves nothing half-applied.
- Returns `200` with `HostActivity`.

**`changeCapacity`** (MVP plan §4.4; PRD business rules, Capacity):

```sql
UPDATE activities
   SET capacity = $n, spots_left = spots_left + ($n - capacity), version = version + 1
 WHERE id = $activity AND capacity - spots_left <= $n
RETURNING spots_left, version;
-- 0 rows → 409 capacity_below_bookings
SELECT pg_notify('activity_spots', …);
```

- Raising capacity on a sold-out activity reopens it (PRD Lifecycles: SoldOut → Open).
- Setting the current capacity again changes nothing and doesn't bump `version` [Proposal]. The engine adds `AND capacity <> $n` to the `UPDATE`; when 0 rows come back it re-reads the row and returns success if `capacity = $n`, otherwise `capacity_below_bookings`.
- Capacity is at least 1 [Verified, schema: `CHECK (capacity >= 1)`]. The contract rejects 0 with `validation_failed`, so an activity with no bookings can't be lowered to 0 and surface as a constraint error.

**Not in S2:** `GET /api/activities/:id` (the public snapshot with members and a signed static map URL) is S3's "snapshot", because it needs the realtime version contract and Maps signing secrets. S2's responses carry `spotsLeft` and `version` directly.

### 4.6 New error codes [Proposal]

Added to the contracts union and `errors.ts`:

| Code | HTTP | When |
| --- | --- | --- |
| `idempotency_conflict` | 409 | The `Idempotency-Key` was already used by this user for a different activity. |
| `capacity_below_bookings` | 409 | Capacity lowered below the number of confirmed bookings. |

`Idempotency-Key` is required on `POST /activities/:id/bookings`: 1–128 characters from `[A-Za-z0-9_-]` (a UUID fits). Missing or malformed → `400 validation_failed`.

### 4.7 Booking metrics and the oversell assertion

Instruments from the MVP plan §4.12, created in `bookings/metrics.ts`. Labels are only those listed; never activity, user or booking IDs.

| Instrument | Type | Labels |
| --- | --- | --- |
| `booking_attempts_total` | counter | `outcome` (`success`, `replay`, `sold_out`, `already_booked`, `activity_started`, `bookings_paused`, `forbidden`, `not_found`, `idempotency_conflict`, `error`), `path` (`direct`; S4 adds `claim`) |
| `booking_duration_seconds` | histogram | `outcome`, `path` |
| `booking_row_wait_seconds` | histogram | none. Time spent in the conditional `UPDATE` (lock wait), R2's early signal |
| `booking_removals_total` | counter | `outcome` (`removed`, `already_removed`) [Proposal] |
| `oversell_detected_total` | counter | none [Proposal] |

- A `booking.transaction` span wraps the engine call, with `outcome` and `path` attributes. The activity ID may appear as a span attribute; user IDs, contacts and codes never do (CLAUDE.md telemetry rule).
- **Oversell assertion** (PRD Operations: "runs after every booking"; MVP plan §4.9): after a successful commit, the engine compares confirmed bookings with `capacity − spots_left` for that activity, in a single `SELECT` so both sides come from one snapshot and a concurrent booking can't cause a false alarm. Any mismatch logs `oversell_detected` at error level (activity ID only) and increments `oversell_detected_total`. The 5-minute job, the `oversell_activities` gauge and alerting are S8.

### 4.8 Concurrency test

`apps/api/test/concurrency/last-spot.test.ts`, run by `bun test` and therefore in CI.

- Starts the real app with `Bun.serve` on an ephemeral port and a pool of 20 connections, so requests are concurrent at the database, not serialized by the test.
- Signs in M = 200 distinct users through `POST /api/sessions` beforehand.
- For each N ∈ {1, 5, 14} (PRD Q4 and MVP plan §4.13), 3 rounds: create an activity with N spots, release all M requests together, wait for all.
- Asserts per round: exactly N `201`s; M − N `409 sold_out`; no other status; `spots_left = 0`; confirmed bookings = capacity; every success has a distinct `ref` and its own Plan.
- Additional races in the same file:
  - **Same key, in parallel:** one user sends one key 20 times at once → exactly one booking; one `201`, the rest `200` with the same booking ID; `spots_left` dropped by 1.
  - **Same user, new keys, in parallel:** 20 keys at once → one `201`, the rest `already_booked`; one spot taken.
  - **Removal racing bookings:** sold-out activity, one removal and 20 bookings at once → exactly one booking takes the freed spot; invariant holds.
  - **Capacity racing bookings:** raise and lower capacity while bookings run → the invariant `capacity − spots_left = confirmed bookings` holds after every round, and `spots_left` never goes negative.

### 4.9 k6 `last_spot_race` smoke

MVP plan §4.13: smoke runs on a laptop against local Compose at 1–5% of target load. Full runs (500 VUs from the spot EC2) are S9.

```text
load/
  seed.ts                     # signs in a host through the API, creates activities with N ∈ {1, 5, 14}, writes load/results/seed-<runId>.json
  scenarios/last_spot_race.js # one scenario per activity, 25 VUs released together, each with its own session
  check.ts                    # after the run: SQL invariant check on the seeded activities (oversell = 0)
```

- **25 VUs** per activity (5% of the 500-VU target). Each VU signs in through `POST /api/sessions` with its own contact and device ID; no test-only bypasses (MVP plan §4.13).
- **Thresholds** (pass/fail): per activity, a custom counter of `201`s equals N exactly and of `409 sold_out` equals 25 − N; `checks` rate 100%.
- **Runner:** the official `grafana/k6` image, latest stable, pinned by exact tag in `infra/docker-compose.yml` under a `load` profile so `docker compose up` never starts it. It reaches the API on the host through `host.docker.internal`.
- **Data:** seeded users are named `Load <runId> …`. The smoke runs against the local development database and leaves its data; `check.ts` reads only the run's activities [Proposal]. A cleanup script is S9's, with the hosted runs.
- **One command:** `bun run load:smoke` runs seed → k6 → check, with the API already running (`bun run dev`).
- Results go to `load/results/` (already git-ignored) and are summarised in `VALIDATION.md` Part B.

### 4.10 Contracts

`packages/contracts/src/activities.ts` and `bookings.ts`:

- `ActivityCreate`, `ActivityPatch`, `Location`, `HostActivity`, `ActivityState { id, spotsLeft, version }`;
- `Booking { id, ref, activityId, planId, source, status, createdAt }`;
- `BookingResponse { booking: Booking, activity: ActivityState }`.

`openapi.json` is regenerated; CI's drift check covers it.

## 5. Architectural considerations

- **Security:** every write is authenticated. Host-only actions check `activities.host_id = caller` in the same transaction as the write. IDs are UUIDv7 and not secrets; authorization never relies on them being unguessable.
- **Performance:** one short transaction holding one row lock (R2). At 500 concurrent bookers the pool of 10 queues requests in the API; that's acceptable for correctness, and S9 sizes the pool against the load test [Assumption].
- **Maintainability:** one engine for every path that changes `spots_left`; S4 extends it rather than copying it (PRD I6).
- **Operations:** the `bookings_paused` kill switch is honoured by the engine now. The admin endpoint to set it needs admin access, which arrives with S8 [Proposal]; until then it's set in SQL.
- **Accessibility:** no UI in S2.

## 6. Components and files affected

| Path | Change |
| --- | --- |
| `apps/api/src/modules/activities/{routes,service}.ts` | New |
| `apps/api/src/modules/bookings/{engine,ref,routes,metrics}.ts` | New |
| `apps/api/src/app.ts` | Mount the two route groups |
| `apps/api/src/errors.ts` | Status for the two new codes; map `VL004` to `validation_failed` |
| `packages/contracts/src/{activities,bookings,errors,index}.ts` | New schemas; two new error codes |
| `packages/contracts/openapi.json` | Regenerated |
| `apps/api/test/activities/*.test.ts`, `test/bookings/*.test.ts`, `test/concurrency/last-spot.test.ts` | New |
| `apps/api/test/helpers/` | A helper to start the app on a port and sign in many users |
| `load/{seed.ts,check.ts,scenarios/last_spot_race.js}` | New |
| `infra/docker-compose.yml` | `k6` service under the `load` profile |
| `package.json` (root) | `load:smoke` script; `load` added to lint/typecheck scope as needed |
| `README.md`, `CHANGELOG.md`, `ROADMAP.md` | Docs |

**No migration.** **No new npm dependencies** [Proposal]: k6 runs from its container image.

## 7. Implementation phases and ordered tasks

| # | Task | Verified by |
| --- | --- | --- |
| T1 | Contracts: activity and booking schemas, two new error codes; error status mapping | V-CON-1, V-CON-2 |
| T2 | `POST /activities` and `PATCH /activities/:id` (non-capacity fields), host checks, location lock | V-ACT-1…4 |
| T3 | Booking reference generator | V-BK-6 |
| T4 | `bookSpot` engine and `POST /activities/:id/bookings`: read checks, transaction, typed rejections, Plan creation, idempotent replay, `booking_succeeded`/`booking_rejected` events, `pg_notify` | V-BK-1…5, V-BK-7, V-BK-8 |
| T5 | `changeCapacity` wired into `PATCH` | V-CAP-1…3 |
| T6 | `removeBooking` and `POST /host/bookings/:id/removal` | V-RM-1…4 |
| T7 | Booking metrics, span and the oversell assertion | V-OBS-1, V-OBS-2 |
| T8 | Concurrency test | V-CC-1…5 |
| T9 | k6 smoke: `load/`, Compose profile, `load:smoke`; run it | V-K6-1 |
| T10 | README, OpenAPI regeneration, full CI command set locally | V-CI-1 |
| T11 | Record results; CHANGELOG, ROADMAP | Part B |

## 8. Dependencies and prerequisites

- S1 implemented [Verified, ROADMAP]. Local Compose Postgres and `bun run db:migrate`.
- Docker for the k6 image.
- **None** on AWS, Grafana Cloud or Google Maps.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| The concurrency test passes because the test serializes requests | Real HTTP server, pool of 20, all requests released together; V-CC-1 also asserts that `booking_row_wait_seconds` recorded waits above zero, which proves requests contended for the lock |
| Flaky concurrency test in CI | Assertions are on exact outcomes, never timings; 3 rounds per N |
| Classifying a 0-row `UPDATE` reads a different state than the `UPDATE` saw | Order of checks is fixed (started → paused → sold out); all three are true rejections, so a mislabel can't turn into a booking |
| Ref retries loop | At most 5 attempts, then `internal` |
| Rejection events add write load under a race | One insert per rejection, outside the transaction, best-effort; S9 measures it |
| Activities API overlaps S5 | S2 owns the API, S5 owns the screen and photo upload (Q1) |
| k6 inside Docker can't reach the host on Linux | Smoke is a laptop run (macOS, `host.docker.internal`); documented `--add-host` for Linux |

## 10. Alternatives considered

- **`SELECT … FOR UPDATE` then check then `UPDATE`:** two round trips holding the lock; the conditional `UPDATE` does it in one (PRD NFR, MVP plan §4.4).
- **`SERIALIZABLE` isolation:** correct but turns contention into serialization failures that must be retried, which hurts R2. Not needed: the single-row conditional update is safe under READ COMMITTED.
- **Idempotency in a separate table with stored responses:** more general, but the unique `(user_id, idempotency_key)` on `bookings` already exists and is enough for one endpoint.
- **Advisory locks per activity:** an extra mechanism for what the row lock already does.
- **Leaving the activities API to S5:** S2 would need fixture-only activities for capacity edits and the k6 smoke would need a database seeding bypass.

## 11. Estimated complexity

Medium (MVP plan §7). Most of the risk is in T4 and T8.

## 12. Assumptions and open questions

**Open questions (answers change scope):**

1. **Q1: Does S2 own the activity create/edit API?** No delivery spec owns it (§2). **Recommendation: yes**, without photo upload (S5). This departs from the MVP plan's delivery table, which lists only "capacity edit" for S2; the departure is recorded here and in the change log once you decide.
2. **Q2: Can a person removed by the host book the same activity again?** The PRD doesn't say. The schema allows it (the unique index covers confirmed bookings only), and the approved copy for that screen says "You can still book another date below" (UI design, `plan.removedBody`). **Recommendation: block it** with a new code `booking_removed` (409), so a host's removal sticks (for example, the wrong recipient of a vouch, PRD edge cases). This would be a new business rule, so it needs your approval and a PRD note.

**Assumptions:**

- Removal is allowed after the activity's start time (§4.4).
- The pool size stays 10 in S2; S9 tunes it.
- `GET /api/activities/:id` is S3's.
- The kill-switch endpoint is S8's (needs admin access).
- k6 smoke data stays in the local development database.

## 13. Related specs and PRD sections

- PRD: B1–B3, I6, A1, A4, H1 (removal), business rules (Capacity and activities, Host removal, Payment and booking reference), Lifecycles, Edge cases (sold out mid-checkout, already booked, server error on booking, activity started), NFR Correctness under concurrency, R1, R2, Q2, Q4.
- MVP plan §4.4, §4.8, §4.12, §4.13, §6, §7.
- S1 Foundations (schema, identity, error envelope).
- Google Maps spec §5.1 (location lock), FR-005.
- Next: S3 (listener, snapshot) and S4 (claims via `extend`).

## 14. Change log

- 2026-11-03 22:30: created.
- 2026-11-03 (review, before approval): `booking_rejected` for `not_found` stores a null `activity_id`; capacity no-op made explicit in the SQL; capacity ≥ 1 enforced in the contract; oversell assertion runs as one statement; FR-003 now places replay and `idempotency_conflict` first.
- 2026-11-03: **approved for implementation** by the user, with the recommendations for both open questions. Q1: S2 owns `POST /api/activities` and `PATCH /api/activities/:id` (no photo upload); this departs from the MVP plan's delivery table, which lists only the capacity edit for S2. Q2: a person the host removed can't book that activity again (`409 booking_removed`); FR-018 becomes active. This is a new business rule that the PRD doesn't state; a note for the PRD is raised with the user rather than edited in. Implementation starts after the S10 deploy is up.
- 2026-11-03: **implemented.** Results are in `VALIDATION.md` Part B. Changes made during implementation, all within the approved scope:
  - **Removal SQL order (§4.4).** The engine locks the activity row with `SELECT … FOR UPDATE` (same lock order), checks the host, sets the booking to `removed` only if it is confirmed, and only then increments `spots_left`. Incrementing first, as drafted, would break the `spots_left <= capacity` check on a repeated removal of a full activity before the rollback could happen.
  - **Replay re-check (§4.2).** A parallel request with the same key can commit between this request's replay lookup and its precheck or `UPDATE`. That made a retry look `already_booked` or `sold_out`. Any failure after the first lookup now looks up the replay again before returning an error. V-CC-2 covers it, including on the last spot.
  - **`startsAt` in the future (§4.5)** is checked in the service against the injected clock, not in the Zod contract, so tests control time. The result is the same `validation_failed`.
  - **`PATCH` order (§4.5).** The transaction locks the row and checks the host, applies the non-capacity fields, then calls `changeCapacity`, so `pg_notify` is its last statement. Any rejection still rolls back the whole edit, which the tests verify.
  - **Metrics injection.** `AppDeps.meterProvider` (optional) is the provider for the booking metrics, so tests read them without replacing the process-global provider that the telemetry test owns. Production uses the global provider.
  - **Metric outcome value.** `booking_attempts_total` and `booking_duration_seconds` can also have `outcome = booking_removed` (FR-018). This is a new value, not a new label.
  - **k6.** VUs sign in during k6 `setup()`, each with its own contact and device ID, so every VU fires its booking together. The Compose service maps `host.docker.internal` to `host-gateway`, which also fixes the Linux risk in §9. `seed.ts` writes `load/results/seed.json`, which `check.ts` and the scenario read.
  - **Shared OpenAPI helpers.** `apps/api/src/openapi.ts` holds `SECURITY` and `errorResponse` for the new route modules. Identity routes were left unchanged.
  - **Image:** `grafana/k6:2.3.0`, the latest stable release on 2026-11-03 (GitHub release v2.3.0, 2026-09-21).
- 2026-11-03: follow-ups. The PRD now states FR-018 under Business rules → Host removal (amended 2026-11-03, owner decision). Local Bun was upgraded to the pinned 1.4.4 and the checks were rerun. The k6 smoke data was deleted from the local development database.
