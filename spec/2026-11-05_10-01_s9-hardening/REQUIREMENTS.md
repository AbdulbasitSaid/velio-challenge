# Requirements: S9 Hardening

## 1. Purpose and scope

Prove that the prototype meets the PRD's non-functional requirements under 10× the assumed peak, and close Phase 5 (M1). Scope: the full k6 suite from a temporary runner, the runner stack, keeping load data out of product metrics, Lighthouse, an accessibility pass, Playwright and Flutter E2E, and three carried-over findings. Design: `PLANNING.md`.

## 2. Goals and non-goals

**Goals:** recorded evidence for every Phase 5 exit criterion; a performance baseline; no distortion of product metrics by test traffic.

**Non-goals:** performance tuning beyond fixing a failed threshold (see FR-014); moving off the single instance; Flutter E2E in CI; native-app accessibility beyond the owner's manual checks.

## 3. Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | A `VelioLoadRunner` CDK stack creates one spot ARM instance in eu-west-2, reachable only through SSM. Its runtime is capped by a scheduled shutdown that terminates it. Its role is limited to the load prefix of the deploy bucket and the Grafana secret. It is deployed and destroyed by scripts. | MVP plan §4.13, §7 (S10) |
| FR-002 | A script uploads `load/` to the runner, runs a named scenario at a given scale through SSM, and brings the results JSON back to `load/results/`. | MVP plan §4.13 |
| FR-003 | Communities have an `is_test` flag. A `velio-load` test community is seeded. | Proposal |
| FR-004 | Test communities and their activities don't appear in the community list, community pages, the community map, suggestions or profile activity lists. A direct activity or invite link still works. | Proposal |
| FR-005 | Every S8 metric view and the admin activities list exclude activities in test communities, except the oversell check, which covers every activity. The admin metrics response states that test data is excluded. | Proposal; PRD Success metrics |
| FR-006 | `load/seed.ts` creates each scenario's activities and invites in `velio-load`, through the public API only. `load/cleanup.ts` pauses a run's activities through the admin API. | MVP plan §4.13 |
| FR-007 | The k6 suite has `last_spot_race`, `viewers`, `booking_mix`, `invite_claims`, `browse` and `soak`, sized by environment (smoke, 1×, 10×), with the thresholds in PLANNING §4.3. Each VU signs in with its own device ID. | MVP plan §4.13; PRD Q4, R2 |
| FR-008 | The full run records a baseline: p50, p95 and p99 for successful bookings, snapshot reads and socket latency, in `load/results/baseline.json`. | MVP plan §4.13 |
| FR-009 | The invite-page open beacon no longer gets `503` on full page loads through CloudFront. | S6 F1 |
| FR-010 | Playwright tests in `apps/web/e2e/` cover host create, booker book and Plan and public link, guest claim with live attendance, a live sell-out on a second viewer, and the admin page. They run on phone and desktop viewports. | MVP plan §7 (S9) |
| FR-011 | A CI job runs the Playwright suite against local Compose on every push. | Owner decision 2026-11-05 |
| FR-012 | Axe scans every page the Playwright flows reach for WCAG 2.1 A and AA rules. A keyboard-only run completes booking and claiming. | PRD Accessibility |
| FR-013 | The Flutter smoke and parity integration tests run on the iOS simulator against the deployed stack. The community-map preview (cards per pin, pin→card, card→pin, card opens the activity) is checked by a test with a Maps key or by the owner on a device. | MVP plan §7 (S9); explore-map-preview |
| FR-014 | Any failed threshold or `serious`/`critical` accessibility violation is fixed within S9 if the fix is local to one component or query. A fix that needs a design change is recorded and raised with the owner. | Proposal |

## 4. Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | `last_spot_race` at 500 VUs gives exactly N bookings for N ∈ {1, 5, 14}, and oversell stays 0. | PRD Correctness; R1 |
| NFR-002 | Booking success ≥ 99.5% of attempts on available spots under `booking_mix` and `invite_claims`. | PRD Success metrics |
| NFR-003 | Socket update latency p95 ≤ 2 s with 5,000 viewers during the race. | PRD Live availability; Q4 |
| NFR-004 | Activity and invite pages reach first content in < 1.5 s on Lighthouse's mobile preset with throttling, on the deployed stack. | PRD Performance |
| NFR-005 | The invite page's JS stays ≤ 200 kB transferred. | S6 NFR-002 (amended) |
| NFR-006 | No `serious` or `critical` axe violations, and WCAG AA contrast, on every page scanned. Spots-left changes are announced politely, not on every tick. | PRD Accessibility |
| NFR-007 | `browse` has `http_req_failed` < 1%. | MVP plan §4.13 [Assumption] |
| NFR-008 | `soak`: API memory and booking p95 show no upward trend over 30 min at expected peak. | MVP plan §4.13 |
| NFR-009 | The Playwright CI job finishes in under 10 minutes. | Proposal |
| NFR-010 | Versions are the latest stable, pinned exactly (k6, Playwright, axe, Lighthouse, AMI). | CLAUDE.md |

## 5. Use cases

- An engineer runs `bun run load:remote viewers --scale 10x` and gets a pass/fail summary and a results file.
- The owner opens `/admin` after a load run and sees the same product figures as before it.

## 6. Acceptance criteria

- **AC-001** The runner stack deploys, runs a scenario through SSM, returns results, and is destroyed; no runner instance remains afterwards.
- **AC-002** A 10× `last_spot_race` meets NFR-001 against production through CloudFront.
- **AC-003** A 10× `viewers` run meets NFR-003, or the instance's ceiling is found and recorded with the socket count reached.
- **AC-004** `booking_mix`, `invite_claims` (no double claims) and `browse` meet NFR-002 and NFR-007. `soak` meets NFR-008.
- **AC-005** `baseline.json` exists and its figures are in VALIDATION.
- **AC-006** `/api/admin/metrics` returns the same goal and funnel figures before and after a load run (apart from real users' activity in between), and `velio-load` appears in no public list.
- **AC-007** Three full page loads of a deployed invite page record an open with no `503` in the network log.
- **AC-008** The Playwright suite passes locally, in CI and once against the deployed stack (admin test skipped there).
- **AC-009** Axe reports no `serious` or `critical` violations; the keyboard run passes; Lighthouse meets NFR-004 and NFR-005.
- **AC-010** The Flutter smoke and parity tests pass on the iOS simulator against the deployed stack; the map preview is checked (test or device).
- **AC-011** The owner's VoiceOver and TalkBack checks are recorded.

## 7. Business rules and edge cases

- Public links allow 60 claim attempts a minute each, so `invite_claims` spreads claims across links rather than raising the limit.
- Auto-pause (200 opens an hour with under 2% claims) must not fire in `invite_claims`: each link gets claims as well as opens.
- Paused test activities stay paused; they never reopen.
- An invite to a test activity behaves like any other invite.

## 8. Error handling and failure behavior

- A 1× failure stops the run before 10×; the failure is reported, not retried blindly.
- If the runner is reclaimed (spot interruption), the run is repeated; partial results are discarded and noted.
- If production becomes unhealthy during a run, k6 stops (abort thresholds on `http_req_failed` > 20% for 30 s). The deploy workflow's health checks and the restore procedure are the recovery path.

## 9. Security and privacy

- **SEC-001** The runner has no inbound rules and no SSH. Its IAM role grants only the `load/` prefix and `velio/prod/grafana` read.
- **SEC-002** No secrets (admin token, Grafana keys, session tokens) appear in `load/results/`, logs, the repository or chat.
- **SEC-003** Load and E2E contacts are synthetic (`@example.com`). No real personal data is used.
- **SEC-004** No test-only bypass is added to the API.
- **SEC-005** Claude never types the production admin token into a web page; scripts read it from Secrets Manager.

## 10. Performance and reliability

Covered by NFR-001–NFR-008. The baseline (FR-008) is the reference for later regressions (over 20% flagged, not failed).

## 11. Compatibility constraints

- k6 scripts run on the Compose `k6` image locally and the pinned k6 binary on the runner.
- Playwright runs Chromium only. Safari is covered by the owner's VoiceOver check.

## 12. Data and migration

- Forward-only migration: `communities.is_test`, the `velio-load` row, and redefined views. Existing data is unaffected (`is_test` defaults false).
- Load rows remain in production permanently, marked by their community.

## 13. Dependencies and integrations

AWS (EC2 spot, SSM, S3, Secrets Manager, CloudFront), Grafana Cloud (Prometheus remote write), GitHub Actions, the iOS simulator.

## 14. Explicitly excluded

- Load testing the web's server rendering (`browse` reads API endpoints and the invite page HTML only).
- A per-activity booking queue (R2's fallback) unless the run proves it's needed. That would be a new spec.
- Flutter E2E in CI.
- A real domain or WAF.
