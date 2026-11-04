# Validation: S3 Realtime

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] Scope matches parent S3 (WS gateway, `NOTIFY` bridge, versioned events, snapshot and poll fallback, latency acks, realtime metrics), plus the snapshot left to S3 by S2.
- [x] No invented product targets: 2 s, 10 s, 30 s and 5,000 viewers come from the PRD and MVP plan; 250 sockets is 5% (MVP plan §4.13 smoke sizing). The 4 kB, 20-topic, 20-error, 60 s and 8-member values are engineering limits marked as proposals.
- [x] Open questions Q1 and Q2 (PLANNING §12) answered before implementation (2026-11-04).

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, FR-004, SEC-001 | V-SNAP-1, V-SNAP-2, V-CON-1 |
| FR-002, NFR-006 | V-SNAP-3, code review |
| FR-003, AC-006 | V-SNAP-4 |
| FR-005 | V-RT-2 |
| FR-006, FR-007, AC-004, SEC-002 | V-RT-3 |
| FR-008, FR-010, AC-001 | V-RT-1 |
| FR-009 | V-RT-5 |
| FR-011 | V-RT-4 |
| FR-012, AC-003 | V-RT-7 |
| FR-013, NFR-001, AC-002 | V-RT-6 |
| FR-014 | V-RT-8 |
| FR-015 | V-RT-9 (configuration and a ping observed) |
| FR-016 | V-RT-9 |
| FR-017 | V-RT-10 |
| FR-018 | V-CON-1 (review of the documented rules) |
| NFR-002, AC-005 | V-K6-1 |
| NFR-003, SEC-004 | V-OBS-1 |
| NFR-004, NFR-005 | Code review |
| SEC-003 | V-RT-2 (production-mode app without the header) |

### Checks

`bun test` against Compose Postgres, a fresh database per file (S1 helpers), with the app on a real `Bun.serve` port and Bun's WebSocket client.

| ID | Check | Expected |
| --- | --- | --- |
| V-CON-1 | Schema tests for `PublicActivity` and the realtime messages; `bun run contracts:openapi` and diff | No `displayName`, contact, code or ref fields; regenerated file; CI drift check passes; client rules documented next to the schemas |
| V-SNAP-1 | Snapshot anonymous; then signed in as a member, as the host, as a removed member | Shape per FR-001; `viewer` null, then the caller's booking, `isHost: true`, booking with `status: removed`; names in `PublicPerson` form only |
| V-SNAP-2 | Unknown ID; malformed ID | `404 not_found`; `400 validation_failed` |
| V-SNAP-3 | Query count through the Kysely log hook | ≤ 2 anonymous, ≤ 3 signed in; `spotsLeft`/`version` from one statement |
| V-SNAP-4 | Open; sold out; started; started and sold out | `open`, `sold_out`, `started`, `started` |
| V-RT-1 | Two sockets on `activity:A`, one on `activity:B`; book A, remove on A, change A's capacity, then a sold-out and an already-booked attempt on A | Each A socket gets exactly 3 `spots` messages with committed values; B gets none; rejections produce nothing |
| V-RT-2 | Upgrade without `platform`; with an invalid `platform`; with cookie; with bearer; anonymous; production-mode app without `X-Origin-Verify` | `400`; `400`; identified; identified; anonymous; `403` |
| V-RT-3 | AC-004 matrix plus member and host accepted; unknown activity | As AC-004; members and host get `subscribed`; `not_found` for the unknown ID |
| V-RT-4 | 50 parallel bookings on one activity with 50 spots, one socket subscribed | 50 `spots` messages, versions strictly increasing, last `spotsLeft = 0` |
| V-RT-5 | Member socket on `plan:P` and host socket on `host:A`; book into Plan P through the engine with `planId` (S2 extension point); remove that booking; call `notifyAttendance(A)` in a committed transaction | `plan` messages on P for both; `attendance` to the host for all three |
| V-RT-6 | AC-002 with an in-memory metric reader; then a duplicate ack, an ack for an unknown version, and an ack from an unsubscribed socket | 100 samples, p95 ≤ 2 s; the 3 extra acks add no samples and increment `realtime_acks_ignored_total` by 3 |
| V-RT-7 | AC-003 using `pg_terminate_backend` from an admin connection | `resync` on every subscribed socket; `realtime_listener_reconnects_total` +1; the next booking is delivered |
| V-RT-8 | Send invalid JSON, an unknown type, a 5 kB frame, 21 topics; then 20 malformed messages | `validation_failed` errors, socket open; close code 1008 after the 20th |
| V-RT-9 | Inspect the server's WebSocket config and observe a ping on a test socket with a shortened interval; call the shutdown path with sockets open | 30 s interval configured; ping received; sockets closed with 1012 |
| V-RT-10 | `/api/readyz` with the listener stopped, then started | 503, then 200 |
| V-OBS-1 | In-memory metric reader over V-RT-1…7 | Instruments per NFR-003 with only the listed labels; no IDs, topics or tokens in labels, span attributes or logs (activity ID allowed on spans and logs) |
| V-K6-1 | `bun run dev`, then `bun run load:viewers` | NFR-002 thresholds pass; summary saved to `load/results/` |
| V-CI-1 | `bun run format:check`, `bun run lint`, `bun run typecheck`, `bun test`, OpenAPI drift check | All pass |

### Static analysis and formatting

ESLint, Prettier and `tsc --noEmit` as in CI.

### Security checks

V-RT-2 (origin header), V-RT-3 (topic authorization), V-SNAP-1 and V-CON-1 (public names only), V-OBS-1 (no identifiers in telemetry).

### Manual verification

After the user deploys: open `wss://<distribution>.cloudfront.net/api/ws?platform=web` from a browser console, subscribe to a seeded activity, book from another session, and see the `spots` message. Then check `realtime_commit_to_ack_seconds` in Grafana Cloud. This needs a deploy, so it may be recorded as not run.

### Preconditions and test data

Compose Postgres running and migrated. For V-K6-1, the API running locally (`bun run dev`) and Docker for the k6 image.

### Known limitations

- Latency in tests and the local smoke is far below production (no CloudFront, no mobile network). The PRD target is checked for real in S9 and in production metrics.
- The ping interval is checked by configuration and one shortened-interval observation, not by a 30 s wait.

## Part B: Executed checks

All checks run on 2026-11-04 on macOS (Bun 1.4.4, Compose `postgres:18.6`), unless stated.

| ID | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| V-CON-1 | `bun test packages/contracts`; `bun run contracts:openapi` | **Pass.** 8 tests. `PublicActivity`'s JSON Schema has no `displayName`, contact, hash, code, note, ref or token fields; topic grammar and message schemas parse as specified. `openapi.json` regenerated with the snapshot route, `/api/ws` and the message schemas. Client rules documented in `packages/contracts/src/realtime.ts`. | FR-001, FR-018, SEC-001 |
| V-SNAP-1…4 | `bun test apps/api/test/activities/snapshot.test.ts` | **Pass.** 7 tests: anonymous shape with `no-store`, short names only (no surname or email in the body), `viewer` for member, host, outsider and removed member, member count with an 8-person preview, 404 and 400, status order including started-and-sold-out, directions URL with and without a place ID. Query count through a counting Kysely instance: 2 anonymous, 3 signed in; spots and version from the first statement. | FR-001–FR-004, NFR-006, AC-006, SEC-001 |
| V-RT-1…10, V-OBS-1 | `bun test apps/api/test/realtime` (real `Bun.serve`, Postgres `LISTEN`, Bun WebSocket client) | **Pass,** 12 tests, in 3 local runs and once in a Linux container (below). Booking, removal and capacity change each reached both subscribed sockets with committed values and nothing reached the other activity; rejections sent nothing. 50 parallel bookings arrived as 50 strictly increasing versions. `plan` and `attendance` hints on booking into a Plan, removal and `notifyAttendance`. Topic authorization matrix as AC-004, with bearer and cookie identity. Malformed, unknown, oversize and 21st-topic messages answered with `validation_failed`; 20 malformed closed with 1008. Pings observed at a 200 ms test interval; shutdown closed with 1012. 100 acknowledged bookings gave 100 samples, every one ≤ 2 s (asserted on the histogram's max, so p95 ≤ 2 s); duplicate, unknown and unsubscribed acks added 3 to `realtime_acks_ignored_total`. `pg_terminate_backend` on the listen connection → `resync`, `listening()` true again, the next booking delivered. Readiness 503 → 200 → 503 with the listener stopped, started, stopped. Metric labels exactly as NFR-003. | FR-005–FR-017, NFR-001, NFR-003, AC-001–AC-004, SEC-002–SEC-004 |
| V-K6-1 | `bun run load:viewers` against `bun apps/api/src/index.ts` (development database) | **Pass** (run `20261104T111321`): 250 / 250 sockets saw sold out; spots latency p(95) 47 ms, max 69 ms; 0 out-of-order events; 14 booked, 11 sold out; checks 100%; post-run SQL check: 0 oversold. An earlier run (`20261104T111230`) also passed, with p(95) 44 ms. | NFR-002, AC-005 |
| V-CI-1 | `bun run format:check`, `bun run lint`, `bun run typecheck`, `bun test` | **Pass with one environment exception.** Format, lint and typecheck pass. `bun test`: 195 pass, 2 fail. The 2 failures are S2's 200-parallel-booker concurrency test, refused connections (`ECONNREFUSED`): macOS has `kern.ipc.somaxconn = 128`. The committed code (an export of `HEAD`) fails the same way on this machine, so it isn't caused by S3. The same tests pass on Linux: `docker run … oven/bun:1.4.4 bun test apps/api/test/concurrency apps/api/test/realtime` → 21 pass, 0 fail. | — |
| Load regression | `bun run load:smoke` (S2), after the seed script change | **Pass** on rerun. The first run lost 5 requests per scenario: refused connections throw before `check()`, so they are missing from the counts rather than failed checks (S2's script). The rerun matched exactly (1/24, 5/20, 14/11; 0 oversold). | S2 NFR-006 |
| V-CI-1 (GitHub) | GitHub Actions CI on push of `b5dea1b` (run 41823140398), 2026-11-04 | **Pass** (1m14s): format, lint, types, migrations, drift checks and the full test suite on Linux. | — |
| Manual (production) | After the user's deploy of `b5dea1b` (Deploy run 41823309743, success): `GET https://depimls1pcvv4.cloudfront.net/api/readyz`; a Bun WebSocket client to `wss://…/api/ws?platform=web` subscribing to an unknown activity | **Pass.** Readiness `ok`, so the listener is listening in production. The upgrade passed CloudFront and the origin check, and the gateway answered `{type:"error",code:"not_found"}` for the topic. Booking through production to see a live `spots` event wasn't done, to keep test data out of production. | FR-005, FR-007, FR-017, SEC-003 |

**Checks not run:**

- Grafana Cloud check of `realtime_commit_to_ack_seconds`: not run; no client renders and acknowledges in production until S5–S7.

**Deviations from the plan** (also in PLANNING's change log):

- The gateway uses Bun's WebSocket handler directly rather than `hono/bun`'s `upgradeWebSocket`, which Hono 4.13 marks deprecated and which doesn't expose Bun's pub/sub topics. The route still lives in the Hono app, so origin verification and sessions apply.
- The listener keeps its own connection and retry loop, because postgres.js's `listen()` re-subscribes only once after a drop.
- Bun's hard frame cap is 64 kB (frames above it close with 1009); the 4 kB limit of FR-014 is enforced by the app.
- The two latency histograms declare second-scale bucket boundaries (10 ms to 10 s), so Grafana can read p95 against 2 s.

**Known limitations:**

- Local and smoke latencies are far below production (no CloudFront, no mobile network); the 5,000-viewer run is S9.
- S2's booking histograms still use the SDK's default buckets (0, 5, 10, … seconds), which can't show sub-second latency. Recorded for S8, which builds the dashboards.

**Final validation status: Passed with exceptions** (the macOS connection-backlog failures in S2's concurrency test, local only; CI on GitHub passed).
