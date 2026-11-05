# Validation: S9 Hardening

## Part A: Planned checks

### Spec review checklist

- [x] Every Phase 5 exit criterion that belongs to S9 (k6 at 10× with a baseline, Lighthouse, accessibility, Playwright and Flutter E2E) maps to a requirement.
- [x] Thresholds come from the PRD or MVP plan §4.13. The two without a PRD figure (`browse`, `soak`) are marked as assumptions.
- [x] Owner decisions (runner, target, E2E placement, carried-over findings) are recorded in PLANNING §4 and the change log.
- [x] No API bypass; insert-only tables untouched.
- [x] Every FR, NFR, SEC and AC maps to a check below.

### Traceability

| Requirement | Check |
| --- | --- |
| FR-001, AC-001, SEC-001 | C1 CDK test; L0 deploy, run and destroy |
| FR-002 | L0 |
| FR-003–FR-005, AC-006 | T1 API tests; L6 before/after metrics |
| FR-006 | T2 local smoke; L5 cleanup |
| FR-007, NFR-001, AC-002 | L1 |
| NFR-003, AC-003 | L2 |
| NFR-002, NFR-007, AC-004 | L3 |
| NFR-008, AC-004 | L4 |
| FR-008, AC-005 | L1–L4 summaries; `baseline.json` |
| FR-009, AC-007 | B1 |
| FR-010, FR-011, NFR-009, AC-008 | E1 local; E2 CI; E3 deployed |
| FR-012, NFR-006, AC-009 | A1 axe; A2 keyboard |
| NFR-004, NFR-005, AC-009 | P1 Lighthouse |
| FR-013, AC-010 | F1 smoke/parity; F2 map preview |
| AC-011, NFR-006 (announcements) | M1 owner screen readers |
| FR-014 | Recorded per finding in Part B |
| NFR-010 | S1 version review |
| SEC-002 | S2 grep of results and logs |
| SEC-003 | Code review of seed and E2E fixtures |
| SEC-004 | Diff review: no new conditional paths in `apps/api/src` keyed on test data, apart from read filtering |
| SEC-005 | Procedure: admin token only read by scripts |

### Proposed tests

**Unit and integration (`bun test`):**
- T1 `apps/api/test/metrics/test-communities.test.ts`. Seed one real and one test activity, each with bookings, invites, opens, claims and a `booking_failed`. Every view and `/api/admin/metrics` count only the real one; `v_oversell` sees an oversold test activity (forced in the test DB); `/api/communities`, the community page, suggestions and profiles omit the test community and activity; a direct `GET /api/activities/:id` and the invite page still work.
- T2 Local smoke of each k6 scenario through Compose (`bun run load:<name>`), at 1–5% scale.
- C1 CDK test for `VelioLoadRunner`: a spot instance, no ingress, the shutdown in user data, IAM limited to the prefix and secret.

**E2E:**
- E1 `bun run web:e2e` locally against Compose.
- E2 The `e2e` CI job on GitHub.
- E3 `E2E_BASE_URL=https://depimls1pcvv4.cloudfront.net bun run web:e2e` (admin test skipped).
- F1 `flutter test integration_test/smoke_test.dart` and `parity_test.dart` on the iOS simulator with `API_BASE_URL` set to the deployed stack.
- F2 `integration_test/map_preview_test.dart` with a Maps key, or the owner's device check.

**Load (on the runner, through CloudFront):**
- L0 Deploy the runner, run `last_spot_race` at 1×, fetch results, destroy; check that no instance remains.
- L1 `last_spot_race` at 10×.
- L2 `viewers` at 10×.
- L3 `booking_mix`, `invite_claims` and `browse` at 10× (`browse` runs alongside).
- L4 `soak` for 30 min at 1×.
- L5 `cleanup.ts` pauses every run activity.
- L6 `/api/admin/metrics` captured before L1 and after L5. The goal and funnel figures match, apart from real users' activity in between (from the events table). Oversell is 0.

**Other:**
- B1 Three full page loads of a deployed invite in Chrome, with the network log: no `503`, one open recorded.
- A1 Axe in the Playwright suite (fails on `serious` or `critical`).
- A2 Keyboard-only Playwright run of booking and claiming.
- P1 Lighthouse CLI, mobile preset, 3 runs each on the deployed invite page (G1, G2) and an activity page; medians recorded.
- M1 The owner: VoiceOver on iOS Safari and TalkBack on Android on the activity page during a live booking, and on the claim flow.

### Static analysis and formatting

S1: `bun run lint`, `typecheck`, `format:check`, `db:codegen --verify`, `web:build`, `contracts:openapi` stable, `contracts:dart` if the admin schema changes, `flutter analyze`, `flutter test`, and the full root `bun test`.

### Security and performance checks

- S2: `grep` `load/results/` and the run logs for `Bearer `, the admin token's prefix and `glc_`; expect nothing.
- Runner IAM reviewed in the synthesised template.
- Pre-flight before L1: Grafana usage headroom checked, a fresh backup taken, AWS's CloudFront load-testing guidance read.

### Manual verification procedures

M1 (above), F2 if done on a device, and B1.

### Preconditions and test data

- Tasks 1, 5 and 6 deployed (owner's push) before L0 and E3.
- `velio-load` community present in production.
- A claimable vouch invite in `velio-load` for F1.
- iOS simulator with Flutter via fvm.

### Expected results

All thresholds in PLANNING §4.3 met, or a ceiling found and recorded (AC-003). No `serious`/`critical` axe violations after fixes. FCP < 1.5 s. Every E2E suite passes.

### Known limitations and open questions

- One `t4g.small` may fail `viewers` at 5,000 sockets. That outcome is recorded, not hidden, and any scale-up is a new spec.
- Lighthouse throttling is simulated; the PRD's "mid-range Android over 3G" is approximated by the mobile preset.
- Screen-reader checks depend on the owner.

## Part B: Executed checks

Not run yet. Filled in after implementation.
