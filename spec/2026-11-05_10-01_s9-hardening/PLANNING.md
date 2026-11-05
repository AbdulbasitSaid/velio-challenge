# Planning: S9 Hardening

- **Spec ID:** 2026-11-05_10-01_s9-hardening
- **Created:** 2026-11-05 10:01 (local)
- **Status:** Deferred (2026-11-05). Not approved or implemented; the owner stopped work here to prepare the assessment submission. Listed in `NEXT.md`.
- **Parents:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (§4.13 load testing, §7 row S9, and S10's deferred load-runner stack). Builds on S2–S8 and the S10 app stack.

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

Phase 5 ("Measure and harden", ROADMAP) closes the prototype (M1). Its exit criteria are not yet met:

- the full k6 suite at 10× the assumed peak, with a recorded baseline;
- the Lighthouse invite-page budget;
- an accessibility pass;
- Playwright and Flutter E2E tests that pass.

Three earlier findings are also still open. The owner chose to close them in S9 (2026-11-05).

## 2. Context and current behavior

- [Verified, `load/`] Only two k6 scenarios exist, `last_spot_race.js` and `viewers.js`, both sized for smoke runs (25 VUs per activity, 250 sockets) and run from the laptop's Compose `k6` service (`grafana/k6:2.3.0`). `load/seed.ts` creates activities through the public API in `explore-kenya`. `load/check.ts` checks the results. There is no `cleanup.ts`, no `lib/`, and none of `booking_mix`, `invite_claims`, `browse` or `soak`.
- [Verified, `infra/aws/lib/`] Only `app-stack.ts` exists. The load-runner stack from MVP plan §4.13 and §7 (S10) was never built.
- [Verified, MVP plan §4.13; PRD Q4, R2] Assumed peak: 50 bookers on one activity within 10 s and 500 viewers. At 10×: 500 bookers and 5,000 viewers. Thresholds come only from PRD figures. Booking latency has no PRD target, so the first full run records a baseline.
- [Verified, `infra/aws/lib/app-stack.ts:153`] Production is one `t4g.small` (burstable, 2 GiB) behind CloudFront `depimls1pcvv4.cloudfront.net`. §4.13 accepts that hitting its ceiling is a valid result.
- [Verified, `apps/api/src/config.ts:23`, `modules/invites/limits.ts`] Rate limits that load must respect: 60 claim attempts a minute per public link; 10 unknown codes an hour per device; 60 events a minute per device; public links auto-pause at 200 opens an hour with under 2% claims.
- [Verified, S1 schema, `20261103140100_schema.sql`] `invites`, `attributions` and `events` are insert-only for every role, so load-test rows cannot be deleted after a run. [Verified, `20261105090000_metrics_views.sql`] The S8 views do not filter anything, so load runs on production would distort `/admin` and the goals.
- [Verified, `bookings/engine.ts:330`] Booking events carry `activity_id`, so filtering by activity covers them.
- [Verified] No Playwright setup exists (no config, no `apps/web/e2e/`). The web has 226 Vitest component tests (S8 VALIDATION T9).
- [Verified, `apps/mobile/integration_test/`] `smoke_test.dart` (code → claim → Plan) and `parity_test.dart` exist and have run locally (S7, S7b).
- [Verified, S6 VALIDATION] Lighthouse ran on the deployed invite page (FCP 0.8–0.9 s). The JS budget is ≤ 200 kB (amended); the hero fix (D4) shipped. **F1 is open:** the open beacon gets `503` from CloudFront on full page loads, though the open is recorded. CloudFront and API logs weren't checked.
- [Verified, explore-map-preview VALIDATION] The Flutter community-map carousel hasn't run on a simulator or device.
- [Verified, S5 and S6 VALIDATION] No accessibility audit has been done (left to S9). The PRD requires WCAG AA contrast and polite announcements of spots-left changes.

## 3. Desired outcome

M1's Phase 5 exits are met and recorded. The full k6 suite has run at 10× from a temporary runner in eu-west-2, with a baseline on file and load data kept out of the product metrics. Lighthouse and an accessibility pass are recorded for the web. Playwright runs in CI. Flutter E2E has run on a simulator. F1, the map-preview device check and load-data exclusion are closed.

## 4. Proposed solution and rationale

### 4.1 Load-runner stack [Proposal]

A second CDK stack, `VelioLoadRunner`, in `infra/aws/lib/load-runner-stack.ts`, deployed for a run and destroyed afterwards (`bun run aws:load:deploy` / `aws:load:destroy`).

- One **spot** `c7g.xlarge` (Graviton, 4 vCPU, 8 GiB) in a public subnet of the app stack's VPC (or its own minimal VPC if cross-stack lookup adds friction). [Assumption] It's enough for 5,000 sockets plus 500 HTTP VUs. If k6 reports its own CPU saturation, the run is repeated on `c7g.2xlarge`, and the size is recorded.
- No inbound rules, no SSH; SSM only. Amazon Linux 2023 arm64, with the AMI pinned as in the app stack.
- User data installs a pinned k6 arm64 release, raises `nofile` and the ephemeral port range for 5,000+ sockets, and schedules `shutdown -h +180`. Spot with `instanceInitiatedShutdownBehavior: terminate` puts a hard cap on runtime.
- An IAM role allows read and write to a `load/` prefix in the existing deploy bucket (scripts in, results out) and read on `velio/prod/grafana` (remote write).
- Run flow: `load/run-remote.ts` (laptop) uploads `load/` to S3, then through SSM runs seed → scenario → check on the runner and pulls `results/*.json` back. It follows the pattern of the deploy workflow's SSM call.

Alternative rejected by the owner (2026-11-05): running from the laptop, which gives lower fidelity and skewed socket latency.

### 4.2 Keeping load data out of the product metrics [Proposal]

Insert-only tables rule out deleting after a run, so load data is marked and filtered.

- Migration: `communities.is_test boolean NOT NULL DEFAULT false`, and seed a `velio-load` community with `is_test = true`.
- Read APIs hide test communities and their activities: the community list, community pages, suggestions ("More in", host's other dates) and the community map. Direct links still work, which k6 needs.
- Each S8 view (and the admin activities list) excludes rows whose activity is in a test community. `v_oversell` is the exception: it keeps every activity, because oversell is a correctness check and load runs are where it matters most. The admin metrics response reports `loadExcluded: true` so the exclusion is visible.
- Telemetry is not filtered. k6 traffic is real production load, and Grafana tags k6's own series with `testid`.
- `load/cleanup.ts` closes a run's activities after it ends. It pauses bookings through the admin API, so nothing more can be booked and nothing shows anywhere. Rows stay, as the schema intends.

Alternative: a separate test stack (rejected by the owner, 2026-11-05).

### 4.3 k6 suite [Proposal]

`load/lib/` holds the shared helpers: sign-in per VU (`POST /api/sessions`, `X-Client: mobile`, a unique device ID, so rate limits apply as for real users, §4.13), the WebSocket subscribe helper and the custom metrics. Each scenario reads `API_URL` (CloudFront when remote). `load/seed.ts` gains a scenario argument and the `velio-load` community.

| Scenario | Shape (10× run) | Pass/fail thresholds |
| --- | --- | --- |
| `last_spot_race` | 500 VUs, each signed in, book one activity with N ∈ {1, 5, 14} within 10 s | Exactly N `201`; the rest `sold_out`; `/api/admin/metrics` oversell 0 |
| `viewers` | 5,000 sockets on one activity while 500 VUs race for it | p95 (receive − `committedAt`) ≤ 2 s; 0 version regressions; every socket ends on 0 left |
| `booking_mix` | Steady direct bookings across 20 activities with spots, at the expected-peak rate (50 bookings / 10 s) for 5 min | Success ≥ 99.5% of attempts on available spots (5xx and timeouts are failures; typed refusals are not) |
| `invite_claims` | Opens then claims on public links, spread across enough links to stay under 60 claims a minute per link; plus a vouch double-claim race (20 claimers per vouch, 25 vouches) | 0 double claims; claim success ≥ 99.5% on available spots; no `429` |
| `browse` | Snapshot, community and invite-page reads as background load during the other scenarios | `http_req_failed` < 1% [Assumption: no PRD figure, from §4.13] |
| `soak` | 30 min at expected peak (50 bookers / 10 s, 500 viewers) | No upward trend in API memory (host metrics) or booking p95 between the first and last 5 minutes |

- **Order:** smoke each new scenario locally first (`bun run load:<name>`), then on the runner at 1×, then at 10×. Stop and report if a 1× run fails.
- **Baseline:** p50, p95 and p99 for booking `201`s, snapshot reads and socket latency, written to `load/results/baseline.json` and VALIDATION. Later runs flag regressions over 20% for review rather than failing (§4.13).
- **Results:** k6 remote-writes to Grafana Cloud with a `testid` tag. End-of-test JSON goes to `load/results/`.
- **Pre-flight:** read AWS's CloudFront load-testing guidance. Check Grafana free-tier headroom. Take a fresh backup (S10 `backup.sh`). Run outside the owner's demo times.

### 4.4 Open beacon `503` (S6 F1) [Proposal]

1. Reproduce on the deployed invite page in Chrome. Capture the `503`'s response headers (`x-cache`, `x-amz-cf-id`, `server`) to tell CloudFront-generated from origin-generated.
2. Read the API's logs for the same minute through SSM (`docker logs velio-api-1`).
3. Likely causes to check [Assumption]: the beacon is sent with `keepalive`/`sendBeacon` during page load and CloudFront rejects the method or body for that behavior; or a cache behavior answers before origin. The fix is whichever is smallest.
4. If the fix changes the beacon's protocol or a CloudFront behavior beyond a header or method list, stop and ask.

### 4.5 Playwright E2E and accessibility [Proposal]

- `@playwright/test` and `@axe-core/playwright` (latest stable, pinned) as dev dependencies of `apps/web`. Chromium only, with a Pixel 7 profile for phone and a desktop profile. Tests go in `apps/web/e2e/`.
- Flows: (1) host creates an activity (no photo upload in CI, so no S3 needed, and no Places key, so the no-maps fallback), (2) booker books, sees the Plan, creates a public link, (3) guest opens the link, claims, and the host's attendance shows them live (two browser contexts), (4) the last spot sells out live on a second viewer, (5) the admin page with a test token.
- Accessibility: an axe scan (WCAG 2.1 A/AA tags) on every page the flows reach, failing on any `serious` or `critical` violation. Plus a keyboard-only pass of the booking and claim flows in Playwright (Tab and Enter, visible focus).
- CI: a new `e2e` job in `ci.yml` starts Compose Postgres, migrates and seeds, starts the API (`ADMIN_TOKEN` set to a test value), builds and starts the web on Node, and runs Playwright. Traces are uploaded on failure.
- Deployed pass: the same suite, run once from the laptop with `E2E_BASE_URL=https://depimls1pcvv4.cloudfront.net`. Its activities go in `velio-load`, so the run is excluded from metrics. The admin test is skipped there, because the production token is never typed into a page by Claude.
- Manual by the owner: VoiceOver (iOS Safari) and TalkBack on the activity page and the claim flow, checking that spots-left changes are announced politely and not on every tick (PRD Accessibility).

### 4.6 Lighthouse [Proposal]

Lighthouse CLI (pinned, run with `bunx`, not added to the repo), mobile preset with default throttling, three runs each on the deployed invite page (G1 claimable, G2 last spot) and an activity page. Record the median FCP, LCP, TBT, CLS and the accessibility score. Passing means FCP < 1.5 s (PRD Performance) and JS ≤ 200 kB (S6 NFR-002 as amended).

### 4.7 Flutter E2E [Proposal]

- Run `smoke_test.dart` and `parity_test.dart` on the iOS simulator against the deployed stack, using a claimable test invite in `velio-load`. Record the results.
- New `integration_test/map_preview_test.dart`: open a community map, check one card per pin, tap a pin and see its card scrolled into view, swipe to a card, tap it to open the activity. With no Maps key the map isn't native, so the test needs the simulator build with the owner's mobile Maps key. Otherwise this check is manual on the owner's phone.
- Not in CI (owner decision, 2026-11-05: macOS runners are slow and costly).

## 5. Architectural considerations

- No test-only bypasses in the API (§4.13). `is_test` is a data attribute; it changes nothing about how a booking runs.
- The load runner never runs on the instance under test, and reaches it only through CloudFront.
- Exclusion lives in SQL views, so `/admin`, analysts and Grafana's SQL panels (if added) agree.
- Telemetry rules stay: no IDs as labels; `testid` is a run label with a handful of values.

## 6. Security and privacy

- Load and E2E sessions use `@example.com` contacts and are tied to their run. Contacts are stored hashed, as for anyone.
- The runner's role covers only its S3 prefix and the Grafana secret. There is no inbound access.
- The production admin token is read by scripts from Secrets Manager at run time (cleanup, oversell check), and never written to results or logs.

## 7. Components and files affected

- `infra/aws/lib/load-runner-stack.ts`, `infra/aws/bin/app.ts`, `infra/aws/test/` (CDK test), root `package.json` scripts.
- `apps/api/migrations/<ts>_test_communities.sql` (column, seed row, view redefinitions); `apps/api/src/modules/communities/*`, `activities/*` (hide test communities in read APIs); `metrics/*` (`loadExcluded`); `db/types.ts` (codegen); contracts and OpenAPI, plus Dart regeneration if the admin schema changes.
- `load/lib/*`, `load/scenarios/{booking_mix,invite_claims,browse,soak}.js`, resized `last_spot_race.js` and `viewers.js` (size from env), `load/seed.ts`, `load/check.ts`, `load/cleanup.ts`, `load/run-remote.ts`, `load/results/baseline.json`.
- Beacon fix: `apps/web` (invite beacon) and/or `infra/aws/lib/app-stack.ts` (CloudFront behavior), depending on §4.4.
- `apps/web/e2e/*`, `apps/web/playwright.config.ts`, `apps/web/package.json`; `.github/workflows/ci.yml` (`e2e` job).
- Accessibility fixes found by axe or the manual pass, in `apps/web` (and `apps/mobile` if TalkBack/VoiceOver find issues).
- `apps/mobile/integration_test/map_preview_test.dart`.
- README (load runner, E2E), VALIDATION, CHANGELOG, ROADMAP.

## 8. Implementation phases and ordered tasks

1. **Test communities:** migration, read-API hiding, view exclusion, `loadExcluded`, tests (API).
2. **k6 library and scenarios:** `load/lib`, new scenarios, env sizing, seed, check, cleanup; local smoke of each.
3. **Load-runner stack:** CDK stack and test, `run-remote.ts`; deploy (needs the deployment of tasks 1 and 3 first), 1× runs.
4. **Full run:** pre-flight, 10× runs, baseline, cleanup, `cdk destroy`.
5. **Beacon 503:** diagnose, fix, deploy, recheck.
6. **Playwright and axe:** setup, flows, a11y scans, CI job; fix violations; deployed pass.
7. **Lighthouse** on the deployed stack.
8. **Flutter:** smoke and parity against deployed; map preview test or owner's device check.
9. **Owner manual checks:** VoiceOver and TalkBack.
10. VALIDATION Part B, CHANGELOG, ROADMAP (Phase 5 and M1 status).

Deployment of tasks 1, 5 and 6 happens by the owner's push (the Deploy workflow). Tasks 3 and 4 deploy and destroy the runner stack with CDK. Both are inside this spec's authorization once it's given.

## 9. Dependencies and prerequisites

- Owner: pushes to `master` to deploy (Claude never commits).
- Owner: the mobile Maps key for the map-preview simulator test, or a device check.
- Owner: VoiceOver and TalkBack checks.
- AWS: spot capacity for `c7g.xlarge` in eu-west-2; costs a few cents an hour, within the $20 budget.
- Grafana Cloud free tier: headroom for k6 remote-write series.

## 10. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| The 10× run takes production down (one `t4g.small`) | Fresh backup first; run at a quiet time; ramp 1× → 10×; finding the ceiling is a valid result (§4.13) |
| CPU credit drain on the instance | Unlimited mode is accepted; the surcharge is small for a short run (§4.13) |
| Load rows can't be deleted (insert-only) | Test communities and view exclusion (§4.2); activities paused after the run |
| The runner is left running | Spot instance with `shutdown -h +180` and terminate-on-shutdown; `cdk destroy` is a named task; the budget alert |
| Grafana free-tier series limit hit during the run | Check headroom first; k6 remote write limited to its built-in metrics plus the scenario's own |
| The runner is the bottleneck, not the server | Watch k6 CPU and dropped iterations; resize and rerun |
| CloudFront throttles or blocks a single-source load | Follow AWS's load-testing guidance; record any CloudFront 4xx/5xx separately from origin errors |
| Playwright is flaky in CI against live sockets | Wait for rendered state, not timers; retries 1 in CI; traces kept |

## 11. Alternatives considered

- Laptop-run full suite; a separate test stack; Flutter E2E in CI. Each was rejected by the owner (2026-11-05, see §4).
- Deleting load data with a privileged role: rejected, because it breaks the insert-only guarantee (S1, PRD I5).

## 12. Assumptions and open questions

- [Assumption] `c7g.xlarge` is enough for the full run (checked during task 3).
- [Assumption] `browse`'s `http_req_failed` < 1% (no PRD figure, §4.13).
- [Assumption] `soak`'s "no upward trend" is judged by comparing the first and last 5 minutes. No numeric limit is invented.
- [Assumption] Hiding test communities from read APIs doesn't conflict with the PRD (it adds no user-facing behavior; the PRD has no test-data rule).
- Open: none blocking. The map-preview check depends on whether the owner provides the Maps key for the simulator; otherwise the owner checks it on a device.

## 13. Estimated complexity

M–L. The full load run and beacon diagnosis carry the most uncertainty.

## 14. Related specs and PRD sections

- PRD: Non-functional requirements (correctness, live availability, performance, accessibility); Success metrics; R1, R2, R3; Q4.
- MVP plan §4.13, §7 (S9, S10). S6 VALIDATION (F1, Lighthouse). Explore-map-preview VALIDATION. S8 (views, admin API).

## 15. Change log

- 2026-11-05: created. Owner decisions the same day: spot EC2 runner; production with tagged data; Playwright in CI with Flutter local; close S6 F1, the map-preview device check and load-data exclusion in S9.
