# Validation: S2 Booking core

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] Scope matches parent S2, plus the activities API (open question Q1, recorded as a departure).
- [x] No invented numeric targets: N ∈ {1, 5, 14} and 500/25 VUs come from PRD Q4 and MVP plan §4.13; M = 200 and 3 rounds are test sizing, not product targets.
- [x] Open questions Q1 and Q2 (PLANNING §12) answered before implementation (2026-11-03, see the PLANNING change log).

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, FR-008 | V-BK-1 |
| FR-002, FR-003 | V-BK-2, V-BK-3 |
| FR-004 | V-BK-4, V-CC-2 |
| FR-005 | V-BK-5, V-CC-3 |
| FR-006 | V-BK-1, V-CC-1 |
| FR-007 | V-BK-6 |
| FR-009 | V-BK-3 |
| FR-010 | V-BK-7 |
| FR-011 | V-BK-8 |
| FR-012 | V-RM-1…4, V-CC-4 |
| FR-013 | V-ACT-1, V-ACT-2 |
| FR-014 | V-ACT-3, V-ACT-4 |
| FR-015 | V-CAP-1…3, V-CC-5 |
| FR-016 | V-BK-9 |
| FR-017 | V-OBS-2 |
| NFR-001, NFR-002, AC-001, AC-006 | V-CC-1, code review of the engine |
| NFR-003, NFR-004 | Code review; V-CC-4, V-CC-5 (no deadlocks) |
| NFR-005, SEC-002 | V-OBS-1 |
| NFR-006, AC-005 | V-K6-1 |
| NFR-007 | Not checked: no target in S2 |
| AC-002 | V-CC-2 |
| AC-003 | V-CC-4 |
| AC-004 | V-CAP-2 |
| SEC-001 | V-SEC-1 |
| SEC-003 | V-CON-2 |

### Checks

`bun test` against Compose Postgres, a fresh database per file (S1 helpers).

| ID | Check | Expected |
| --- | --- | --- |
| V-CON-1 | `bun run contracts:openapi`; diff `openapi.json` | Regenerated file committed by the user; CI drift check passes |
| V-CON-2 | Schema test: `Booking`, `BookingResponse`, `HostActivity` keys | No contact or hash fields |
| V-ACT-1 | Create an activity with valid input | `201`; `spotsLeft = capacity`, `version = 0`, host is the caller |
| V-ACT-2 | Create with a past `startsAt`, capacity 0, bad currency, 141-char meeting point, bad lat, invalid time zone, unknown community, no session | `validation_failed` (or `not_found` for the community, `unauthenticated` without a session); nothing inserted |
| V-ACT-3 | Edit title/description as host; edit as another user | `200`; `403 forbidden` |
| V-ACT-4 | After a confirmed booking, edit `startsAt`, `location.lat`, `meetingPoint`; then title | `409 location_locked` each, nothing changed; title edit succeeds |
| V-BK-1 | Book an open activity | `201`, body per FR-008; `spots_left` −1, `version` +1; one Plan owned by the booker; booking `source = direct` |
| V-BK-2 | Unknown activity; host books own; already booked; missing key; malformed key; no session | `404`, `403`, `409 already_booked`, `400`, `400`, `401`; `spots_left` unchanged |
| V-BK-3 | Sold out; started (`starts_at` in the past via fixture); paused (`bookings_paused` set in SQL); started **and** paused **and** sold out | `sold_out`, `activity_started`, `bookings_paused`; precedence per FR-003; nothing written |
| V-BK-4 | Same key, same activity, sequentially; same key, other activity; replay after host removal | `200` same booking, no writes; `409 idempotency_conflict`; `200` with `status: removed` |
| V-BK-5 | Second booking with a new key | `409 already_booked`; spot not taken |
| V-BK-6 | Unit: 10,000 refs match the pattern; forced collision (stubbed generator returns an existing ref first) | All valid; booking succeeds with a second ref; >5 collisions → `internal`, nothing written |
| V-BK-7 | Engine test: call `bookSpot` with an existing `planId` and an `extend` callback that inserts a row, then one that throws | Booking joins the given Plan and the row commits; on throw, spot, booking and row all roll back |
| V-BK-8 | `LISTEN activity_spots` on an admin connection; book, remove, change capacity; then a rejected booking | One notification per committed change with matching `spotsLeft` and `version`; none for the rejection |
| V-BK-9 | After V-BK-1, V-BK-2 and V-BK-3 | `booking_succeeded` row for the success; `booking_rejected` rows with the right `props.reason`, with a null `activity_id` for `not_found`; no event for a replay |
| V-CAP-1 | Raise capacity on a sold-out activity | `spots_left` = increase; `version` +1 |
| V-CAP-2 | AC-004 | As stated |
| V-CAP-3 | Lower to exactly the confirmed count; set to the current value; set capacity 0 on an activity with no bookings | Succeeds, `spots_left = 0`; second is a no-op, `version` unchanged; third `400 validation_failed`, nothing changed |
| V-RM-1 | Host removes a confirmed booking | `200`; status `removed`; `spots_left` +1; one `booking_removals` row |
| V-RM-2 | Remove the same booking again | `200`; no second `booking_removals` row; `spots_left` unchanged |
| V-RM-3 | Non-host removes; unknown booking ID; no session | `403`, `404`, `401` |
| V-RM-4 | After removal, another user books the freed spot | `201` |
| V-CC-1 | Concurrency (PLANNING §4.8): N ∈ {1, 5, 14}, M = 200, 3 rounds each, through a real `Bun.serve` | Exactly N `201`s, M − N `sold_out`, nothing else; invariant AC-006 holds; distinct refs and Plans; `booking_row_wait_seconds` recorded at least one wait > 0 |
| V-CC-2 | AC-002 | One booking; one `201` and 19 `200`s with the same ID; `spots_left` −1 |
| V-CC-3 | One user, 20 new keys in parallel | One `201`, 19 `already_booked`; one spot taken |
| V-CC-4 | AC-003 | Exactly one new booking; invariant holds; no deadlock errors |
| V-CC-5 | Capacity raises and lowers interleaved with 50 parallel bookings, 3 rounds | Invariant holds after each round; `spots_left` never < 0; no deadlock errors |
| V-OBS-1 | In-memory metric reader (S1 telemetry test pattern): run V-BK-1…3 | Instruments per NFR-005 with only the listed labels; no IDs, keys or refs in any label, span attribute or log line besides activity ID |
| V-OBS-2 | Corrupt the invariant in SQL as superuser (raise `spots_left` without removing a booking, bypassing the engine), then book | Booking response unaffected; `oversell_detected` logged; counter +1 |
| V-SEC-1 | Each host endpoint as a non-host, and every S2 endpoint without a session | `403`, `401` |
| V-K6-1 | API running locally; `bun run load:smoke` | Thresholds pass: per activity exactly N `201`s and 25 − N `sold_out`; `check.ts` reports 0 oversold; summary saved to `load/results/` |
| V-CI-1 | Run every CI step locally: format, lint, typecheck, migrate, codegen verify, `bun test`, OpenAPI drift | All pass. Green on GitHub is confirmed after the user pushes |

**Static analysis and formatting:** Prettier, ESLint and `tsc --noEmit` across `apps/api`, `packages/contracts` and `load/` (V-CI-1).

**Manual verification:** V-K6-1 and reading the k6 summary.

**Preconditions:** Bun and Docker; Compose up; `bun run db:migrate`; `.env` from `.env.example`.

**Known limitations:**

- The concurrency test runs one API process. Multi-instance correctness rests on the same database constraint and isn't tested separately.
- The k6 smoke is a laptop run at 5% of the target load; the 10× load test is S9.
- CI green on GitHub is pending the user's push.

## Part B: Executed checks

Run on 2026-11-03 on macOS against the Compose Postgres (`postgres:18.6`). The first run used local Bun 1.3.13. Bun was then upgraded to the pinned 1.4.4 and every check was rerun (last row). Green on GitHub stays pending the user's push.

| Check | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| V-CON-1 | `bun run contracts:openapi`, then compare with the file on disk | Pass: regenerated. A second raw generation is byte-identical, so CI's `git diff --exit-code` passes once the user commits it | FR-008, FR-013 |
| V-CON-2 | `packages/contracts/test/schemas.test.ts` | Pass: `Booking`, `BookingResponse` and `HostActivity` have no contact, hash, key or token fields; `Booking` has exactly the FR-008 keys | SEC-003 |
| V-ACT-1…4 | `apps/api/test/activities/activities.test.ts` | Pass (20 tests): create; 7 invalid inputs (past start, capacity 0, bad currency, 141-character meeting point, latitude 91, invalid time zone → `validation_failed`; unknown community → `not_found`) insert nothing; host edit, non-host `403`; date and location edits before a booking; after a booking, `startsAt`, `lat` and `meetingPoint` edits, and a mixed edit, each return `location_locked` and change nothing, while a title edit succeeds | FR-013, FR-014, SEC-001 |
| V-CAP-1…3 | Same file, `capacity` block | Pass: raising capacity reopens a sold-out activity (`version` +1, then bookable); lowering below confirmed bookings returns `capacity_below_bookings` with the row unchanged, and the edit's other fields roll back; lowering to exactly the confirmed count sells it out; the same value is a no-op that keeps `version`; capacity 0 returns `400`; a non-host gets `403` | FR-015, AC-004 |
| V-BK-1…5, V-BK-9, FR-018 | `apps/api/test/bookings/bookings.test.ts` | Pass (16 tests): FR-008 body, a Plan owned by the booker, `spots_left` −1 and `version` +1, a `booking_succeeded` event; `404` / `403` / `400` (missing key) / `400` (bad key) / `401`, with nothing written; `already_booked`; `sold_out`, `activity_started`, `bookings_paused`; precedence started → paused → sold out, with `already_booked` ahead of them; same-key replay `200` with no writes (events included); `idempotency_conflict`; a replay after removal returns `status: removed`; a removed person gets `booking_removed`; `booking_rejected` reasons, with a null `activity_id` for `not_found` | FR-001…FR-006, FR-009, FR-016, FR-018 |
| V-RM-1…4 | Same file, removal block | Pass: removal frees the spot (+1, `version` +1) and writes one `booking_removals` row; a repeat returns `200` and frees nothing; non-host `403`, unknown `404`, no session `401`; the freed spot goes to the next booker | FR-012, SEC-001 |
| V-BK-6…8, V-OBS-1, V-OBS-2 | `apps/api/test/bookings/engine.test.ts` | Pass (8 tests): 10,000 references match the pattern; one collision is retried; persistent collisions fail and write nothing; `extend` joins the given Plan and commits its row, and a throwing `extend` rolls back the spot, booking and row; `LISTEN activity_spots` receives exactly 4 notifications (2 bookings, 1 removal, 1 capacity change), none for the rejection or the no-op capacity change, with matching `spotsLeft`/`version`; metric labels are only `outcome`/`path`, `outcome` or none, and no IDs, keys or refs appear in them; a broken invariant logs `oversell_detected` (activity ID only) and adds 1 to the counter, while the booking still succeeds | FR-007, FR-010, FR-011, FR-017, NFR-005, SEC-002 |
| V-OBS-1 (spans, logs) | `apps/api/test/telemetry/telemetry.test.ts`, new test | Pass: the `booking.transaction` span has exactly `activity.id`, `booking.path` and `booking.outcome`; the user ID, idempotency key and booking reference appear in no span or log line | SEC-002, NFR-005 |
| V-CC-1…5 | `bun test apps/api/test/concurrency` | Pass (9 tests, about 3 s), and 5 consecutive reruns also pass. 200 parallel HTTP bookers × 3 rounds × N ∈ {1, 5, 14}: exactly N `201`s, M − N `sold_out`, invariant holds, distinct refs and Plans. Same key × 20: one `201` and 19 `200`s with one booking ID, also on the last spot. 20 new keys: one `201` and 19 `already_booked`. Removal racing 20 bookers × 3 rounds: exactly one takes the freed spot. Capacity edits racing 50 bookings × 3 rounds: invariant holds, no `500`s (so no deadlocks) | NFR-001, NFR-002, NFR-004, FR-004, FR-005, FR-012, FR-015, AC-001, AC-002, AC-003, AC-006 |
| Mutation check | Temporarily deleted `.where('spots_left', '>', 0)` from the engine, ran the concurrency file, then restored it (`grep` confirms the line is back) | Pass: the mutant fails 5 of 9 tests, so the test detects an unguarded decrement | NFR-001, NFR-002 |
| V-K6-1 | API run locally (`bun apps/api/src/index.ts`, development database), then `bun run load:smoke` with `grafana/k6:2.3.0` | Pass, run `20261103T223531`: 1 spot → 1 booked / 24 sold out; 5 → 5 / 20; 14 → 14 / 11; `checks` rate 1. All 7 thresholds `ok` in `load/results/k6-20261103T223531.json`. `check.ts`: 0 oversold, every activity `confirmed = N`, `spots_left = 0`. `http_req_duration` (sign-ins included) averaged 85.3 ms, p95 171.4 ms; not a baseline (NFR-007). No error or warning lines in the API log | NFR-006, AC-005 |
| V-SEC-1 | Covered inside V-ACT-3, V-CAP, V-BK-2 and V-RM-3 | Pass: every S2 endpoint returns `401` without a session; each host action returns `403` for a non-host | SEC-001 |
| V-CI-1 | `bun run format:check`, `bun run lint`, `bun run typecheck` (now including `load/`), `bun run db:codegen --verify`, `bun test`, OpenAPI regeneration | Pass: 176 tests across 12 files, 0 failures; types up to date; no OpenAPI drift | All |
| V-CI-1 (rerun on the pinned Bun) | Local Bun upgraded to 1.4.4 (`bun upgrade`); `bun install --frozen-lockfile`, then every step above | Pass: `bun test v1.4.4`, 176 tests, 0 failures; lockfile unchanged | All |

**Checks not run:**

- CI on GitHub: it runs after the user commits and pushes.
- NFR-007: no target, by design.

**Deviations from the plan** (details in the PLANNING change log, 2026-11-03 implementation entry):

1. Removal locks the activity with `SELECT … FOR UPDATE` and frees the spot only after the booking actually changes, instead of incrementing first and rolling back.
2. After any failed attempt, the engine checks for a same-key replay again (a race found while writing V-CC-2).
3. The future-`startsAt` check is in the service, using the injected clock, rather than in the Zod contract.
4. `PATCH` applies fields, then capacity, so `pg_notify` is the last statement.
5. An optional `AppDeps.meterProvider` holds the booking metrics.
6. The `booking_attempts_total` outcome can also be `booking_removed`.
7. k6 signs each VU in during `setup()`. The Compose service adds `host.docker.internal:host-gateway`.

**Known limitations:**

- V-CC-1's contention assertion (`booking_row_wait_seconds` max > 0) is weak on its own: any recorded duration is above zero. The mutation check is the stronger evidence that the test exercises the race.
- The concurrency test and the k6 smoke use one API process (as planned).
- The k6 smoke data (`Load 20261103T223531 …`) was deleted from the local development database afterwards, at the user's request: 76 users and their sessions, 3 activities, 20 bookings and Plans, and 75 events. Only the seeded communities remain.

**Final validation status:** Passed with exceptions (GitHub CI pending the user's push).
