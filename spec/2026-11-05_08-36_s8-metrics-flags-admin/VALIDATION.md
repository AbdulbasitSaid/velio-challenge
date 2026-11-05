# Validation: S8 Metrics, flags and admin

Spec: `spec/2026-11-05_08-36_s8-metrics-flags-admin/`

## Part A: Planned checks

### A.1 Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check.
- [x] PRD figures used as given (10% holdout, 99.5%, 2 s p95, 30%, 25%, 1.5× guardrail, 5 min check). No invented product numbers; the engineering choices (02:00 UTC, 7-day default, 60 events per minute, 1 s admin budget) are marked as assumptions.
- [x] PRD departures: `availability_rendered` stays a metric, not a row (PLANNING §4.2), and the purge job is dropped (Q7 amended). Both are raised with the owner in the review summary.
- [x] Owner decisions recorded (PLANNING change log).

### A.2 Traceability

| Requirement                                     | Checks                                                   |
| ----------------------------------------------- | -------------------------------------------------------- |
| FR-001, AC-001                                  | T1 `armOf` unit test                                     |
| FR-002, FR-003, AC-002                          | T2 API holdout tests                                     |
| FR-004, AC-003                                  | T3 claim event test                                      |
| FR-005                                          | T3 (forced error in the engine through a test hook)      |
| FR-006, AC-004, SEC-003                         | T4 events endpoint tests                                 |
| FR-007                                          | T9 web reporter test                                     |
| FR-008, AC-005                                  | T5 views on a seeded scenario                            |
| FR-009, NFR-003                                 | T6 admin metrics test (shape, values, timing)            |
| FR-010, FR-011, FR-012, FR-013, AC-006, SEC-001 | T6 admin auth, pause/resume, list, audit                 |
| FR-014, AC-008                                  | T9 web admin page test                                   |
| FR-015, FR-016, AC-007                          | T7 job tests                                             |
| FR-017, FR-018, AC-009                          | M1 Grafana push and Chrome check                         |
| AC-010                                          | M2 deployed check                                        |
| NFR-001                                         | T8 concurrency tests                                     |
| NFR-002, SEC-004                                | Code review of the metric definitions; a grep for labels |
| NFR-004                                         | S1 static checks                                         |
| SEC-002                                         | T6 asserts no names, contacts or codes in the admin JSON |

### A.3 Checks

- **T1–T7** `bun test apps/api` (new files under `test/flags`, `test/events`, `test/admin`, `test/jobs`, `test/metrics`).
- **T8** `bun test apps/api/test/concurrency` (on CI if local socket limits refuse, as seen 2026-11-05).
- **T9** `bun run web:test`.
- **S1** `bun run lint && bun run typecheck && bun run format:check`; `bun run contracts:openapi && bun run contracts:dart` (diff additive only); in `apps/mobile`, `flutter analyze` and `flutter test`.
- **M1** `GRAFANA_URL=… GRAFANA_SA_TOKEN=… bun run grafana:push`, twice. Open each dashboard and the alert list in Chrome.
- **M2** After the deployment authorization: `/admin` on the CloudFront host with the token, pause and resume a test activity, and the oversell gauge in Grafana Explore.

### A.4 Preconditions and test data

The Compose stack running. The seeded scenario for T5 builds users in both arms, direct and invited bookings, vouch and public invites with opens and claims, a started activity with attended, no-show and removed marks, and one deliberately unclaimed invite. The Grafana token comes from the owner.

### A.5 Expected results

All automated checks pass, the views match the hand-computed figures, and the dashboards and alerts are visible and idempotent.

### A.6 Known limitations

The rolling realtime p95 on the admin page covers one instance since the process started (at most the last hour). Grafana is the authoritative view. Product-trigger windows (7 days) need real traffic to mean anything.

## Part B: Executed checks

All run 2026-11-05 on macOS (Apple silicon), Bun 1.4.4, Flutter via fvm, with the local Compose stack.

| Check   | Command or procedure                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Result                                                                                                                                                                                                                 | Covers                                          |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| T1, T2  | `bun test apps/api/test/metrics/holdout.test.ts`: 10,000 IDs gave 900–1,100 holdouts and stable arms; holdout gets `canInvite: false`, `403 invites_unavailable` and one `holdout` exposure after two reads; exposed gets tools and one `exposed` row                                                                                                                                                                                                                                                                                        | Pass (4/4)                                                                                                                                                                                                             | FR-001–FR-003, AC-001, AC-002                   |
| T3, T4  | `bun test apps/api/test/metrics/events.test.ts`: one `invite_claimed` per claim; an injected database failure gives `500 internal` and one `booking_failed`; `activity_viewed` stored with the session user and `platform`; unknown activity stores nothing; `web_vital` stores nothing; 4 bad payloads give `400`; the 61st event in a minute gives `429`                                                                                                                                                                                   | Pass (6/6)                                                                                                                                                                                                             | FR-004–FR-006, AC-003, AC-004, SEC-003          |
| T5, T6  | `bun test apps/api/test/metrics/admin.test.ts`: a scenario with both arms, vouch and public invites, opens, claims (two new users, one existing), a removal, a server error and attendance marks; every goal, funnel, invite-rate, K-factor, plans, guardrail and holdout figure equals the hand count; no names, contacts or codes in the JSON; admin 404 without a token, 401 without or with a wrong one, 429 after 10 wrong; pause → `bookings_paused`, resume → `201`, unknown ID → 404; on-demand audit clean and shown in the metrics | Pass (5/5)                                                                                                                                                                                                             | FR-008–FR-013, AC-005, AC-006, SEC-001, SEC-002 |
| T7      | `bun test apps/api/test/metrics/jobs.test.ts apps/api/test/telemetry/rolling.test.ts`: oversell 0, then 1 after two confirmed bookings on a 1-spot activity; audit clean, then a hand-edited invite caught as `invites`; next audit at 02:00 UTC; rolling p95 and ageing                                                                                                                                                                                                                                                                     | Pass (4/4)                                                                                                                                                                                                             | FR-015, FR-016, AC-007, FR-009                  |
| T8      | `bun test apps/api/test/concurrency`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | **Not passing locally**: 4–5 of 15 fail with `ECONNREFUSED` from the local listener under 200 parallel connections, a different subset each run, as before S8 (explore-map-preview VALIDATION). See the k6 check below | NFR-001                                         |
| T8 (k6) | `bun run load:smoke` against the running dev API (the owner's `bun --watch` server on :3001; confirmed it served the new `/api/events` route)                                                                                                                                                                                                                                                                                                                                                                                                | Pass: 1/5/14 spots → exactly 1/5/14 booked, the rest `sold_out`, 0 oversold, p95 176.5 ms                                                                                                                              | NFR-001                                         |
| T9      | `bun run web:test` (new `test/admin.test.tsx`: helpers; token form → tiles with status in words; header sent; token in sessionStorage; rejected token returns to the form and is forgotten; Pause asks first and then calls the API; vitals page mapping and events)                                                                                                                                                                                                                                                                         | Pass: 226 tests, 18 files                                                                                                                                                                                              | FR-007, FR-014, AC-008                          |
| S1      | `bun run lint`, `bun run typecheck`, `bun run format:check`, `bun run db:codegen --verify`, `bun run web:build`; `bun run contracts:openapi` (stable on a rerun) and `bun run contracts:dart` (adds the admin and event models and `invites_unavailable`); in `apps/mobile` `flutter analyze` (no issues) and `flutter test` (293 pass); `dart analyze` in `packages/api-client-dart`                                                                                                                                                        | Pass                                                                                                                                                                                                                   | NFR-004                                         |
| Full    | `bun test` (root): 293 pass, 6 fail. The 6 were the 5 local `ECONNREFUSED` race tests plus the CDK secrets test, which was then updated for `admin-token` and passes (`bun test infra/aws`: 15/15)                                                                                                                                                                                                                                                                                                                                           | Pass apart from T8                                                                                                                                                                                                     | —                                               |
| Review  | Metric labels: `name`, `metric`, `page`, `connection` (closed lists), no IDs; jobs log counts, not activity IDs; no new runtime dependencies (`next/web-vitals` is part of Next)                                                                                                                                                                                                                                                                                                                                                             | Pass                                                                                                                                                                                                                   | NFR-002, SEC-004, NFR-004                       |

### Checks not run

- **M1 Grafana push and Chrome check** (FR-017, FR-018, AC-009): waiting for the owner's `GRAFANA_URL` and `GRAFANA_SA_TOKEN` in `.env`. The script was run without them and exits with the setup message. The metric names in the queries follow the OTLP → Prometheus naming and still need checking in Grafana Explore.
- **M2 deployed check** (AC-010): deployment needs its own authorization (PLANNING §7, task 9).
- **NFR-003** (metrics under 1 s): not timed. No measurement was taken.
- `/admin` was not opened in a browser; it was checked through component tests and the production build only.

### Deviations

See the PLANNING change log (2026-11-05): row-level views, the booking-success definition, no live push for the kill switch, and adjusted existing tests.

### Final validation status

**Passed with exceptions.** M1 (Grafana) and M2 (deployed) are pending, and the in-process concurrency tests can't run locally. The k6 race covers NFR-001 here; CI on Linux is the reference.
