# Planning: S8 Metrics, flags and admin

- **Spec ID:** 2026-11-05_08-36_s8-metrics-flags-admin
- **Created:** 2026-11-05 08:36 (local)
- **Status:** Implemented locally (2026-11-05). The Grafana push (needs the owner's token) and deployment (needs its own authorization) are outstanding.
- **Parents:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (§4.8, §4.9, §4.12, §7 row S8). Builds on S2 (booking engine), S3 (realtime acks), S4 (invites, opens, attribution, audit functions), S5/S6 (web) and S10 (AWS stack, Grafana Cloud export).

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

Phase 5 (ROADMAP, "Measure and harden") starts with S8. The PRD's release plan requires "a metrics endpoint and admin page showing the five goals; SQL views for invite rate, open-to-claim and K-factor by rail; the feature flag with holdout assignment in code". Its Operations section requires a per-activity kill switch, an oversell check every 5 minutes that pages, and a nightly attribution audit. None of that can be read or operated today.

## 2. Context and current behavior

- [Verified, `apps/api/migrations/20261103140100_schema.sql`] Tables exist but have no logic: `exposures (user_id, flag, arm, first_exposed_at)`, `events (name, user_id, activity_id, invite_id, rail, generation, platform, props, at)`, and `activities.bookings_paused`.
- [Verified, `grep insertInto('events')`] The server already writes `booking_succeeded` (in the booking transaction), `booking_rejected` (two paths in `bookings/engine.ts`), `invite_created` and `invite_opened` (`invites/service.ts`). There is no `invite_claimed`, `activity_viewed` or error event.
- [Verified, `bookings/engine.ts:352`] After each booking, an oversell assertion increments `oversell_detected_total` and logs `oversell_detected`. Nothing runs on a schedule, and nothing reports the count as a gauge.
- [Verified, `20261104120000_invites_attribution.sql:111,150`] `audit_chain(activity)` and `audit_all_chains()` exist, but nothing calls them.
- [Verified, `bookings/engine.ts:191-226`, `errors.ts`] Bookings and claims are refused with `bookings_paused` when the flag is set. No endpoint sets it.
- [Verified, `contracts/src/plans.ts:48`, `plans/service.ts:109`] `PlanView.viewer.canInvite = confirmed && !started`. Web (`plan-live.tsx`, `welcome.tsx`, `i/[code]/in/page.tsx`) and Flutter (`plan_page.dart`, `youre_in_page.dart`) render **no** invite prompt or tools when it is false. So a holdout can be enforced entirely by the API, with no client change.
- [Verified, `bookings/routes.ts:67`] The client platform arrives as the `x-client` header.
- [Verified, grep of `createCounter|createHistogram`] Existing OTel metrics: `booking_attempts_total`, `booking_duration_seconds`, `booking_row_wait_seconds`, `realtime_commit_to_ack_seconds`, `realtime_*`, `invite_*`, `rate_limited_total`, `oversell_detected_total`, `http_server_duration_seconds`, `db_pool_in_use`.
- [Verified, `infra/`] No `infra/grafana/`. The prod collector exports to Grafana Cloud (`otel-collector.prod-grafana.yaml`, S10).
- [Verified, `infra/aws/lib/app-stack.ts:60`] Secrets are generated in Secrets Manager by a `generated(name)` helper.
- [Verified, PRD Q7 amended 2026-11-04] Raw vouch contacts are never stored, so the plan's "raw-contact purge" job has nothing to purge.
- [Verified, owner 2026-11-05] The Flutter app isn't deployed. Only the API and web are deployed. Phase 4 loose ends are accepted as is, and deep links stay as built.

## 3. Desired outcome

An operator with the admin token opens `/admin` on the web and sees the five PRD goals, the funnel per rail, K-factor, the plans-happen guardrail and the holdout comparison. They can pause or resume bookings for any activity. 10% of bookers are a stable holdout who never see invite tools. Exposures are logged once per user. An oversell check every 5 minutes and a nightly audit feed gauges, and Grafana Cloud alerts on them. Three Grafana dashboards and the PRD's alert rules live as JSON in the repo and are pushed by a script. The web reports real-user Web Vitals.

## 4. Proposed solution [Proposal]

### 4.1 Feature flag and holdout (PRD "Holdout design")

- One flag, `group_invites`. A pure function `armOf(userId)` returns `holdout` when `sha256('group_invites:' + userId)` read as a big-endian uint32 `mod 100 < HOLDOUT_PERCENT`, and `exposed` otherwise. Same input, same arm, forever.
- `HOLDOUT_PERCENT` comes from config, default **10** (PRD). Tests set 0 so existing suites are unaffected; holdout tests set 100. The rollout stages (internal, one community, GA) belong to Phase 6 and are out of scope.
- **Exposure:** the first time a user reaches an invite surface, insert `exposures (user_id, 'group_invites', arm)` with `ON CONFLICT DO NOTHING`. Invite surfaces are a `PlanView` served to a confirmed member before the start (where `canInvite` would be true without the holdout) and any `POST /plans/:id/invites`. Both arms are logged, since analysis compares them.
- **Enforcement:** for holdout users, `canInvite` is `false`, and `POST /plans/:id/invites` returns `403 invites_unavailable`. Holdout users can still claim invites from others; the PRD analyses at the booker level, intention-to-treat. Web and Flutter need no change (§2).

### 4.2 Events

- **Server-side, in the same transaction as the fact:** keep the existing events and add `invite_claimed` (claim transaction, with rail, invite and generation). Add `booking_failed` (reason `error`), written best-effort outside the rolled-back transaction, so booking success counts real errors.
- **Client:** `POST /api/events` (public, `x-client` platform, at most 60 per device per minute through the existing `rate_limits`) accepts only:
  - `activity_viewed { activityId }`, stored in `events`;
  - `web_vital { metric: FCP|LCP|TTFB|CLS|INP, value, page: activity|invite|community|other, connection?: effectiveType }`, recorded only as the histogram `web_vitals_seconds{metric,page,connection}` (CLS unitless as `web_vitals_cls`) and never stored, to keep the table small.
  - Unknown names → `400`. No personal data is accepted. Activity IDs go in the database row only, never in labels.
- **Web:** Next's built-in `useReportWebVitals` (no new dependency) sends `web_vital` with `navigator.sendBeacon`. Activity and invite pages send `activity_viewed` once per page load.
- `booking_attempted` isn't a separate row: every attempt ends in exactly one of `booking_succeeded`, `booking_rejected` or `booking_failed`, so attempts are their sum. The counter `booking_attempts_total` already exists.
- `availability_rendered` stays a metric (`realtime_commit_to_ack_seconds`, S3), not a row. One row per ack would mean 5,000 writes per booking at the Q4 load.

### 4.3 SQL views (migration)

The ID names in the plan are kept. All are read-only; the API role gets `SELECT`.

| View                      | Definition (PRD "Success metrics")                                                                                                                                                                                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `v_oversell`              | activities where confirmed bookings > capacity                                                                                                                                                                                                                                        |
| `v_booking_success`       | per day: `booking_succeeded` ÷ (`booking_succeeded` + `booking_failed` + `booking_rejected` whose reason is not a domain refusal: `sold_out`, `already_booked`, `booking_removed`, `activity_started`, `bookings_paused`, `idempotency_conflict`, `already_claimed`, `invite_paused`) |
| `v_invite_rate`           | per rail and arm: exposed bookers (`exposures`, arm `exposed`, with a `booking_succeeded`) who created ≥ 1 invite of that rail within 24 h of their first booking ÷ those bookers                                                                                                     |
| `v_open_to_claim_by_rail` | per rail: claims (`invite_claims`) ÷ unique opens (`invite_opens`, already one per invite and device)                                                                                                                                                                                 |
| `v_k_factor_by_rail`      | per rail: users whose first attribution is through that rail (new users) ÷ users who created ≥ 1 invite of that rail; later vouches (trust edges) excluded (D4)                                                                                                                       |
| `v_plans_happened`        | per arm of the Plan's booker: Plans whose activity has started where every confirmed member is marked attended ÷ Plans whose activity has started                                                                                                                                     |
| `v_guardrail`             | invited vs organic attendees after the start: (no-show marks + host removals) ÷ bookings; plus the ratio                                                                                                                                                                              |
| `v_holdout`               | per arm: bookers, new users brought in per booker, Plans happened                                                                                                                                                                                                                     |

Exact SQL is written against the real tables in the implementation and reviewed against these definitions.

### 4.4 Admin API and token

- `ADMIN_TOKEN` is a generated Secrets Manager secret (`generated('admin-token')`) passed to the API container. When unset, every `/api/admin/*` route returns `404`. With a wrong or missing `Authorization: Bearer …`, it returns `401` (constant-time compare, failed attempts rate-limited per IP), and the token never appears in logs.
- `GET /api/admin/metrics?days=7` returns an `AdminMetrics` contract: the five goals with value, target and a triggered flag; the funnel per rail; K-factor per rail; guardrail; holdout split; oversell count; last audit result. Realtime p95 comes from an in-process rolling window of the last hour of acks (single instance, §5), with its sample count.
- `GET /api/admin/activities` lists upcoming activities with spots and paused state. `POST /api/admin/activities/:id/pause` and `/resume` set `bookings_paused`, then send the existing activity refetch hint so open clients show the paused state live.
- `POST /api/admin/audit` runs `audit_all_chains()` on demand.

### 4.5 Jobs (in-process)

- A small scheduler in the API process. Each run takes `pg_try_advisory_lock(job)`, so a second instance would skip it.
- **Oversell check** every 5 minutes: read `v_oversell`, set gauge `oversell_activities`, and log `oversell_detected` with the count only. The existing per-booking assertion stays.
- **Attribution audit** nightly at 02:00 UTC and on demand: `audit_all_chains()`, gauge `audit_chain_failures`, last result kept in memory and in a log line.
- Purge: dropped (§2, Q7 amended).

### 4.6 Web admin page

`/admin` (not linked from anywhere, `noindex`): a token form, with the token kept in `sessionStorage` and sent in a header by client-side fetches (never in URLs). The page shows goal tiles with target and status, funnel tables per rail, K-factor, guardrail, holdout comparison, and an activities table with Pause/Resume behind a confirmation. It uses existing Velio components, is responsive at 360 px, and follows the `dataviz` guidance for tiles and tables.

### 4.7 Grafana dashboards and alerts

- `infra/grafana/dashboards/{goals,booking-realtime,host-db}.json` and `infra/grafana/alerts/*.json`, as in plan §4.12.
- Alerts, using the PRD triggers:
  - `oversell_activities > 0`, immediately;
  - booking success < 99.5% over 1 h (from `booking_attempts_total` by outcome);
  - realtime p95 > 2 s for 15 min;
  - `audit_chain_failures > 0`.
- Notifications go to the stack's default email contact point. The product triggers (7-day funnel targets) appear on the admin page, not as alerts.
- `bun run grafana:push` (`infra/grafana/push.ts`) upserts dashboards and alert rules through the Grafana HTTP API with `GRAFANA_URL` and `GRAFANA_SA_TOKEN` from the environment, which the owner creates. It is idempotent by UID. Verified in Chrome.

## 5. Architectural considerations

- **Correctness first:** new events are written inside the existing transactions (one extra insert) or best-effort after. The booking path's lock order and the concurrency tests are unchanged.
- **Single instance (S10):** the in-process scheduler and the rolling p95 window are per process. Advisory locks keep jobs correct if a second instance ever appears; the p95 would then be per instance, and Grafana is the fleet-wide view.
- **Privacy:** admin responses are aggregates only. No names, contacts, codes or notes. Telemetry labels stay low-cardinality (CLAUDE.md).
- **Cardinality:** `web_vitals_seconds` labels are 5 metrics × 4 pages × ≤ 5 connection types.

## 6. Components and files affected

- `apps/api/migrations/<new>_metrics_views.sql`, `apps/api/src/db/types.ts` (codegen)
- `apps/api/src/config.ts` (`ADMIN_TOKEN`, `HOLDOUT_PERCENT`)
- New `apps/api/src/modules/flags/`, `modules/events/`, `modules/admin/`, `src/jobs/`
- `modules/plans/service.ts` (canInvite + exposure), `modules/invites/service.ts` (403, exposure), `modules/invites/claims.ts` (`invite_claimed`), `modules/bookings/engine.ts` (`booking_failed`), `modules/realtime` (ack window)
- `packages/contracts/src/{admin,events}.ts`, `openapi.json`, Dart client (regenerated; additive)
- `apps/web/app/admin/`, `apps/web/components/admin/`, a web-vitals reporter in the root layout, and `activity_viewed` on activity and invite pages
- `infra/grafana/**`, root `package.json` script `grafana:push`
- `infra/aws/lib/app-stack.ts` (admin-token secret), prod Compose env
- Tests in `apps/api/test/{flags,events,admin,jobs}/`, `apps/web/test/admin*.test.tsx`
- `README.md` (admin token, grafana push), `ROADMAP.md`, `CHANGELOG.md`

## 7. Implementation phases and ordered tasks

1. Config, `armOf` with unit tests, exposure logging, holdout enforcement and tests.
2. Events: `invite_claimed`, `booking_failed`, `POST /api/events`, tests.
3. Migration with views, codegen, view tests against seeded scenarios.
4. Admin API (token guard, metrics, activities, pause/resume, audit), contracts, OpenAPI and Dart regeneration, tests.
5. Jobs and gauges, with tests that call the job functions directly.
6. Web: `/admin` page, web-vitals reporter, `activity_viewed`, tests.
7. Grafana JSON and push script.
8. Local verification: full `bun test`, web tests, lint, types, format, mobile tests (client regeneration).
9. **Deployment (separate authorization at that point):** CDK secret, deploy API and web (this also ships the map-preview `summary`), push Grafana, check in Chrome.
10. VALIDATION Part B, CHANGELOG, ROADMAP.

## 8. Dependencies and prerequisites

- Owner: a Grafana Cloud service-account token with dashboard and alerting write access, for task 7/9.
- No new runtime dependencies (Next's `useReportWebVitals` is built in; `node:crypto` for hashing).

## 9. Risks and mitigations

| Risk                                                                          | Mitigation                                                                                                                  |
| ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Holdout breaks existing tests and k6 seeds (10% of random users lose invites) | `HOLDOUT_PERCENT=0` in tests. The k6 seeds use the deployed config, so S9 seeds set users or tolerate `403` (noted for S9). |
| Event writes slow the hot booking path                                        | One insert in an existing transaction. The concurrency test and `load:smoke` are re-run.                                    |
| `POST /api/events` abused to fill the table                                   | Allow-listed names, rate limit, `activity_viewed` only for existing activities, web vitals not stored.                      |
| Admin token leaked                                                            | Generated secret, header only, rate-limited failures, rotate by regenerating the secret.                                    |
| Grafana metric names differ from OTel names (suffixes, units)                 | Names checked in Grafana Explore before writing queries.                                                                    |
| The view definitions drift from the PRD wording                               | Each view is tested with a hand-computed seeded scenario.                                                                   |

## 10. Alternatives considered

- **Flag service (Unleash, GrowthBook):** an extra service on one EC2, for a single flag. Rejected.
- **Storing every ack as `availability_rendered`:** exact, but 5,000 writes per booking at load. Metrics instead.
- **Allow-listed admin users or an open admin page:** rejected by the owner (2026-11-05) in favour of a shared token.

## 11. Assumptions and open questions

- [Assumption] "Bookers exposed to the feature" means exposed-arm users with an exposure row and a confirmed booking. The 24 h window runs from their first booking.
- [Assumption] A "new user from a claimed invite" is a user whose first attribution row came from that claim (generation ≥ 1).
- [Assumption] Alerts go to the Grafana stack's default email contact point (the owner's account email).
- [Assumption] The nightly audit time (02:00 UTC) and the 7-day default window are engineering choices, not product rules.
- Open: none blocking. The owner decided admin access, Grafana delivery, Flutter scope (holdout only, no app change needed) and the full scope on 2026-11-05.

## 12. Estimated complexity

Medium: about 2 migrations' worth of SQL, 4 API modules, one web page and the Grafana JSON.

## 13. Related specs and PRD sections

PRD: Problem and goals, Success metrics and tracking (funnel events, holdout design), Operations and admin, Release plan, R1, R3, R9, R11, R12. MVP plan §4.8, §4.9, §4.12. S9 consumes the admin metrics in `last_spot_race` (plan §4.13).

## 14. Change log

- 2026-11-05: created. Owner decisions taken the same day: shared admin token, Grafana JSON plus push script, Flutter holdout only, full S8 scope.
- 2026-11-05: approved for implementation by the owner ("go ahead approved"), then implemented. Deviations from §4, each kept small:
  - **Views are row-level** (one fact per row with the timestamp a window applies to); `GET /api/admin/metrics` aggregates them per window. Aggregated views couldn't take the `days` window. Definitions are unchanged.
  - **Booking success** counts successes ÷ (successes + `booking_failed`). Every `booking_rejected` is a typed refusal (sold out, paused, rate limited, …) and none counts as a failure; this replaces the enumerated list in §4.3 and matches the PRD's "attempts on available spots".
  - **No live push for the kill switch.** §4.4 assumed an "activity refetch hint" existed; the protocol has none (`spots`, `plan`, `attendance`, `resync`). Pausing takes effect at once for every booking and claim (the conditional UPDATE checks the flag); open pages show the paused state on their next load or attempt. Adding an event would mean protocol and client changes, outside S8.
  - `invite_claimed` already existed (S4, with `is_new_user`); FR-004 is verified, not added.
  - The admin page's realtime p95 is the `availability_live` goal tile (value and sample), not a separate block.
  - Wrong admin tokens: at most 10 per IP per minute, then `429` (SEC-001's figure, an engineering choice).
  - `activity_viewed` is also sent from the invite page (the funnel's first step for invited people).
  - Existing tests adjusted: the engine's rollback tests now expect one `booking_failed` row (written after the rollback, by design), and the CDK test counts eight secrets (`admin-token`).
