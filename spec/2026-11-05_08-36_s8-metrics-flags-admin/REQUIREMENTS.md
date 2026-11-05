# Requirements: S8 Metrics, flags and admin

Spec: `spec/2026-11-05_08-36_s8-metrics-flags-admin/`

## 1. Purpose and scope

Make the PRD's goals readable and the system operable: funnel events, SQL views, the `group_invites` holdout, an admin metrics page with a kill switch, scheduled oversell and audit checks, Web Vitals, and Grafana dashboards and alerts.

## 2. Goals and non-goals

- **Goals:** every PRD success metric is computable and shown; the holdout is enforced by the server; on-call is paged on oversell.
- **Non-goals:** rollout stages (Phase 6), a flag service, mobile client events, real admin authentication, the full k6 suite (S9).

## 3. Functional requirements

### Holdout

- **FR-001 (PRD Holdout design)** `armOf(userId)` is deterministic: `holdout` when `uint32be(sha256('group_invites:' + id)[0..4]) mod 100 < HOLDOUT_PERCENT`, else `exposed`. `HOLDOUT_PERCENT` defaults to 10.
- **FR-002** The first time a user reaches an invite surface (a `PlanView` as a confirmed member before the start, or an invite create), one `exposures` row `(user, 'group_invites', arm)` is stored. Later visits add nothing, and the arm never changes.
- **FR-003** For holdout users, `PlanView.viewer.canInvite` is `false`, and `POST /api/plans/:id/invites` returns `403 invites_unavailable`. Claiming others' invites is unaffected.

### Events

- **FR-004 (PRD funnel events)** A claim writes `invite_claimed` (user, activity, invite, rail, generation, platform) in its transaction.
- **FR-005** A booking or claim that fails with a server error writes `booking_failed` with reason `error`, best-effort.
- **FR-006** `POST /api/events` accepts only `activity_viewed` (stored) and `web_vital` (metric only), validated by a contract. Unknown names or bad payloads → `400`. More than 60 per device per minute → `429`.
- **FR-007** The web app sends `activity_viewed` once per activity or invite page load, and `web_vital` for FCP, LCP, TTFB, CLS and INP.

### Views and metrics

- **FR-008** Migration adds `v_oversell`, `v_booking_success`, `v_invite_rate`, `v_open_to_claim_by_rail`, `v_k_factor_by_rail`, `v_plans_happened`, `v_guardrail` and `v_holdout`, per PLANNING §4.3.
- **FR-009** `GET /api/admin/metrics?days=N` (1 ≤ N ≤ 90, default 7) returns the five goals (value, target, triggered), funnel per rail, K-factor per rail, guardrail, holdout split, oversell count, last audit result, and realtime p95 with its sample count.

### Admin and kill switch

- **FR-010 (PRD Operations)** `/api/admin/*` needs `Authorization: Bearer <ADMIN_TOKEN>`: missing or wrong → `401`; `ADMIN_TOKEN` unset → `404`.
- **FR-011 (PRD kill switch, R1)** `POST /api/admin/activities/:id/pause` and `/resume` set `bookings_paused`. Bookings and claims then fail with `bookings_paused` (or succeed again), and open clients receive the activity refetch hint.
- **FR-012** `GET /api/admin/activities` lists upcoming activities: title, start, spots left, capacity, paused.
- **FR-013** `POST /api/admin/audit` runs the attribution audit and returns its result.
- **FR-014** `/admin` on the web: token entry, the metrics of FR-009, and the activities list with Pause/Resume behind a confirmation.

### Jobs and alerts

- **FR-015 (PRD oversell check)** Every 5 minutes the API sets the gauge `oversell_activities` from `v_oversell` and logs any hit.
- **FR-016 (PRD attribution audit)** Nightly (02:00 UTC) and on demand, `audit_all_chains()` runs and sets the gauge `audit_chain_failures`.
- **FR-017** Three dashboards (Goals; Booking and realtime; Host and database) and four alert rules live in `infra/grafana/`: oversell > 0 immediately; booking success < 99.5% over 1 h; realtime p95 > 2 s for 15 min; audit failures > 0.
- **FR-018** `bun run grafana:push` upserts them idempotently from `GRAFANA_URL` and `GRAFANA_SA_TOKEN`.

## 4. Non-functional requirements

- **NFR-001** The concurrency tests (`apps/api/test/concurrency`) and the booking engine's lock order are unchanged and still pass.
- **NFR-002** Metric labels are low-cardinality only: no entity IDs, codes or user data (CLAUDE.md).
- **NFR-003** `GET /api/admin/metrics` answers in under 1 s on the local seeded data set. [Assumption: an engineering budget, not a PRD figure]
- **NFR-004** No new runtime dependencies. Lint, types, format, web tests, mobile tests and client regeneration are clean.

## 5. Use cases

- The operator checks the Goals tiles each morning and pauses an activity that shows an oversell.
- The analyst reads the holdout split after 4 weeks (Phase 6).

## 6. Acceptance criteria

- **AC-001** Over 10,000 random UUIDs, the holdout share is 10% ± 1%, and `armOf` gives the same arm across calls.
- **AC-002** With `HOLDOUT_PERCENT=100`, a booker's PlanView has `canInvite: false`, invite create returns `403`, and exactly one exposure row exists after two PlanView reads. With 0, `canInvite` is true and the exposure arm is `exposed`.
- **AC-003** A claim writes exactly one `invite_claimed` event.
- **AC-004** `POST /api/events` stores `activity_viewed`, records `web_vital` without a row, rejects unknown names (`400`) and limits (`429`).
- **AC-005** On a seeded scenario, every view's figures equal hand-computed values.
- **AC-006** Admin routes: `404` without a configured token, `401` with a wrong one, `200` with the right one. Pause makes a booking fail with `bookings_paused`; resume lets it succeed.
- **AC-007** Calling the oversell job on a clean DB sets the gauge to 0. The audit job reports 0 failures on an intact chain.
- **AC-008** The web `/admin` page test: the token form, rendered goal tiles from a fixture, and Pause with confirmation calling the API.
- **AC-009** Dashboards and alerts appear in Grafana Cloud after `grafana:push`, checked in Chrome. A second push changes nothing.
- **AC-010** Deployed: `/admin` shows real figures through CloudFront, and the oversell gauge is visible in Grafana.

## 7. Business rules and edge cases

- Ratios with a zero denominator are shown as "—" (null), never 0% or an error.
- The public rail has no target (D1). The admin page shows its week-1 baseline value with "target set after week 1".
- The blended open-to-claim rate is shown for context only and never flagged (D1).
- A holdout user who is invited by someone else can claim, and their own Plan still shows no invite tools.
- Pausing an already paused activity is a no-op `200`.

## 8. Error handling and failure behavior

- If a job fails (database error), it logs and retries at the next tick; the gauge keeps its last value.
- `booking_failed` insert failures are logged and swallowed. They never change the booking response.
- If the admin metrics query fails, the endpoint returns `500` with the standard envelope, and the page shows an error with Try again.

## 9. Security and privacy

- **SEC-001** The admin token is never logged, never put in URLs, compared in constant time, and failed attempts are rate-limited per IP.
- **SEC-002** Admin responses contain aggregates and activity titles only: no person names, contacts, codes or notes.
- **SEC-003** `POST /api/events` stores no personal data beyond the session user ID it already knows.
- **SEC-004** Telemetry follows CLAUDE.md: no personal data, codes or tokens, and no entity-ID labels.

## 10. Performance and reliability

The booking path adds at most one insert. Event volume is bounded by the rate limit and by not storing web vitals. Jobs hold an advisory lock.

## 11. Compatibility constraints

New contract fields and endpoints are additive. The Dart client is regenerated, with no app code change.

## 12. Data and migration

One forward-only migration with the views and grants. No table changes are needed beyond what S1 created. [Assumption: confirmed during implementation; any index added for view speed is recorded in the change log]

## 13. Dependencies and integrations

Grafana Cloud HTTP API (owner-created service-account token), Secrets Manager (`admin-token`), the existing OTel pipeline.

## 14. Explicitly excluded

Rollout stage switching, per-community flags, Flutter events and timings (`mobile_timing_seconds`), the raw-contact purge (moot since Q7 was amended), real admin auth, and alert channels other than email.
