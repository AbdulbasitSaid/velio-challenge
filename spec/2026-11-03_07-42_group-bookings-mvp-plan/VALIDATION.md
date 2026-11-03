# Validation: Group Bookings MVP

## Part A: Planned checks

### Spec review checklist

- [ ] Every PRD P0 requirement maps to at least one FR, NFR or SEC requirement.
- [ ] Every requirement maps to at least one check below.
- [ ] No numeric target appears that is not in the PRD or marked as an assumption.
- [ ] Departures from the PRD are listed (realtime transport, §4.2).
- [ ] Open decisions are listed and none is silently assumed.
- [ ] Delivery specs S1–S9 cover every requirement exactly once as owner.

### Traceability

| Requirement | Checks | Owner spec |
| --- | --- | --- |
| FR-001 | U-ACT-1, E2E-1 | S5 |
| FR-002, FR-003 | INT-RT-1, E2E-2 | S3 |
| FR-004, FR-005, NFR-001 | CONC-1, CONC-2, INT-BK-1 | S2 |
| FR-006, FR-007 | INT-PL-1, E2E-1 | S2, S5 |
| FR-008–FR-010 | U-INV-1, INT-INV-1 | S4 |
| FR-011 | INT-ATT-1 | S4 |
| FR-012 | CONC-3, INT-INV-2 | S4 |
| FR-013–FR-015 | INT-HOST-1, E2E-3 | S2, S5 |
| FR-016 | INT-AUTHZ-1 | S5 |
| FR-017 | MAN-DL-1, E2E-4 | S6, S7 |
| FR-018, FR-019 | FL-1, MAN-MOB-1 | S7 |
| FR-020 | INT-OPEN-1 | S4, S6 |
| FR-021–FR-023 | INT-BK-2 | S2 |
| FR-024 | INT-OPS-1 | S4, S8 |
| FR-025 | E2E-5, MAN-EDGE-1 | S5–S7 |
| FR-026–FR-028 | INT-MET-1, INT-FLAG-1, MAN-ADMIN-1 | S8 |
| NFR-002 | LOAD-3, LOAD-4 | S9 |
| NFR-003 | INT-RT-2 | S3 |
| NFR-004 | PERF-1 | S6 |
| NFR-005 | A11Y-1 | S9 |
| NFR-006 | INT-RT-1 | S3 |
| NFR-007 | LOAD-1–LOAD-5 | S9 |
| NFR-008 | OPS-BK-1 | S10 |
| NFR-009 | INT-RT-3 | S3, S10 |
| NFR-010, NFR-011 | OBS-1, OBS-2 | S1, S2, S3 |
| NFR-012 | OBS-3 | S8 |
| NFR-013 | OBS-4 | S8 |
| NFR-014 | LOAD-1–LOAD-6 | S2 (smoke), S9 |
| SEC-001, SEC-002 | INT-AO-1, INT-HASH-1 | S1, S4 |
| SEC-003, SEC-004 | INT-PRIV-1 | S4 |
| SEC-005, SEC-006 | INT-RL-1 | S4 |
| SEC-007 | INT-SESS-1 | S1 |
| SEC-008 | Documented limitation, no check | — |
| SEC-009, SEC-010 | OPS-SEC-1 | S10 |
| SEC-011 | OBS-5 | S1, S8 |

### Key proposed checks

API unit and integration tests run with `bun test` against a real Postgres from Docker Compose, with a fresh schema per test file. Concurrency tests use separate connections fired together.

| ID | Check | Expected |
| --- | --- | --- |
| CONC-1 | 50 parallel bookings, N ∈ {1, 5} spots (AC-001) | Exactly N confirmed; others `sold_out`; spots left 0; `v_oversell` empty |
| CONC-2 | Same user, 10 parallel requests with different keys | 1 booking, 9 `already_booked` |
| CONC-3 | 2 parallel claims of one vouch (AC-002) | 1 booking, 1 `already_claimed`; no orphan user |
| INT-BK-1 | Idempotent retry (AC-003); each typed error path | Single booking; correct codes; no state change on error |
| INT-BK-2 | Capacity below bookings, date edit after booking, booking after start, host self-booking | All rejected |
| INT-RT-1 | Two WS clients; booking, removal; out-of-order event; disconnect and reconnect | Both converge to DB value; stale version ignored; snapshot on reconnect |
| INT-RT-2 | 100 bookings, latency from server-side acks (AC-004) | p95 ≤ 2 s |
| INT-ATT-1 | Generation and first-claim-wins (AC-006); existing-user claim | Attribution unchanged; trust edge written; existing user's generation kept |
| INT-AO-1 | UPDATE and DELETE on each insert-only table as the API role (AC-007) | Permission error |
| INT-HASH-1 | Tamper a row as superuser, run audit | Break detected at that row |
| INT-OPEN-1 | Preview-bot fetch versus beacon; repeat beacon (AC-005) | 0 opens from bot; 1 open per device |
| INT-FLAG-1 | Holdout user's Plan and invite endpoints (AC-008) | No invite tools; invite creation rejected |
| INT-MET-1 | Views versus raw counts on seeded data (AC-010) | Equal |
| INT-PRIV-1 | Host responses, logs and URLs scanned for contact data | None present |
| E2E-1..5 | Playwright: host creates → booker books → invites → guest claims on mobile viewport; edge-case states | Flows complete; copy matches PRD |
| FL-1 | Flutter widget and integration tests: offline card, disabled claim, haptics invoked | As FR-018 and FR-019 |
| PERF-1 | Lighthouse mobile, throttled, on `/i/<code>` | First content < 1.5 s |
| LOAD-1 | k6 `last_spot_race`, N ∈ {1, 5, 14}, 500 VUs within 10 s, deployed stack | Exactly N successes; rest `sold_out`; oversell 0 |
| LOAD-2 | k6 `viewers`: 5,000 WebSockets during LOAD-1 | p95 receive − `committedAt` ≤ 2 s; no stale versions applied |
| LOAD-3 | k6 `booking_mix` | Success ≥ 99.5% of attempts on available spots |
| LOAD-4 | k6 `invite_claims`, including the vouch double-claim race | No double claims; success ≥ 99.5% on available spots |
| LOAD-5 | k6 `soak`, 30 min at expected peak | No upward drift in memory or p95 |
| LOAD-6 | Telemetry overhead: short run with tracing off versus on | Difference recorded (no pass/fail) |
| OBS-1 | Local run: hit each route, book, claim, connect a socket | Every §4.12 metric present with only the allowed labels |
| OBS-2 | Trigger an error and a > 1 s request | Both traces kept; logs carry matching `trace_id` |
| OBS-3 | Force each PRD alert condition in staging (e.g. seed an oversell row as superuser) | Alert email received |
| OBS-4 | Load the invite page on a throttled phone profile; run a Flutter claim | Web vitals and mobile timings appear in Grafana |
| OBS-5 | Grep exported spans, metrics and logs from a full E2E run for seeded contact values, codes and tokens | No matches |
| INT-RT-3 | WS client idle 10 min through CloudFront | Connection stays open; updates still arrive |
| OPS-BK-1 | Restore the latest `pg_dump` into a fresh Postgres | Restored row counts match the source |
| OPS-SEC-1 | Hit the EC2 IP directly; request without the origin header; try port 5432 and 22 from outside; list the S3 bucket anonymously | All refused |
| A11Y-1 | axe plus manual screen-reader pass | AA; polite, throttled announcements |
| MAN-DL-1 | Tap link on iOS and Android with and without the app installed | App opens, or web claim page |

Static checks on every change: `tsc --noEmit`, ESLint, Prettier, `dart analyze`, `dart format --set-exit-if-changed`, and contract drift (regenerated client equals committed).

**Preconditions and test data:** a seed script with one host, three communities, activities with 1, 5 and 14 spots, a started activity, and users in both flag arms.

**Known limitations:**
- LOAD-1–LOAD-5 use an assumed peak (PRD Q4), not measured traffic. Booking latency has no PRD target, so the first full run sets a baseline rather than passing or failing.
- MAN-DL-1 needs signed device builds and the deployed CloudFront hostname (S10).
- With a single EC2 instance, LOAD-1 measures that instance's ceiling, not a horizontally scaled one.

## Part B: Executed checks

Not run. This spec is a plan, and no implementation has been authorized. Checks will be executed and recorded in delivery specs S1–S9.

**Final validation status:** Not run.
