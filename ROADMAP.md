# Roadmap

High-level direction for Velio Group Bookings. Detailed scope lives in `Velio Group Bookings PRD.md` and in specs under `spec/`. This document makes no date commitments.

**Status key:** ✅ Done · 🔄 In progress · 📋 Planned (in the PRD) · 🔍 Exploratory or conditional · ❓ Undecided

## Vision and purpose

Make booking a group activity social, so a group goes from "we should do this together" to "we're booked" in one flow, and every booking can recruit the next. (PRD: TL;DR, Context)

## Problem

Group activities on Velio are agreed socially but booked alone. Hosts cannot trust spot counts, bookers cannot reliably bring friends, invited friends hit friction at the moment they are most willing to say yes, and Velio cannot tell which invites bring in people who stay. (PRD: Problem and goals)

## Users and stakeholders

- **Host:** lists activities, needs a count they can trust and live attendance.
- **Booker:** reserves a spot and invites friends.
- **Vouched guest:** claims a spot from a personal invite.
- **Public-link visitor:** claims a spot from a shared link.
- **Velio (product and growth):** needs trustworthy attribution and metrics (K-factor, plans that happen).

## Core capabilities (PRD P0)

- Activity creation with live spots-left and sold-out state (A1–A3).
- Google Maps locations: host picker, map with directions, community map, meeting point (A4–A7).
- Booking with no overselling, idempotent retries and Plan creation (B1–B3).
- Plans showing members and invite status, and a My plans list (L1, L2).
- Vouch and public invites with codes, deep links and immutable attribution (I1–I6).
- Host attendance view with removal and attended or no-show marking (H1–H2).
- Responsive web app with a Host / Booker role toggle (W1).
- Flutter mobile claim flow with a mobile-web fallback, offline-safe caching and haptics (M1–M3); since S7b, also the web's booker and host flows (owner decision, 2026-11-04).
- Metrics endpoint, admin page and feature flag with holdout.

## Current status

- ✅ PRD written, enriched and confirmed by the owner.
- ✅ Development process established (`CLAUDE.md`, spec workflow, changelog).
- ✅ MVP plan (system design, stack, structure) approved.
- ✅ UX design spec and prototype approved.
- ✅ Phase 0 done (2026-11-03): Google Maps locations specified and the PRD amended; Velio design system and all 42 screens designed in Claude Design, responsive rules set, and approved.
- 🔄 Phase 1 in progress: S1 Foundations implemented (2026-11-03): Bun workspace, full schema with integrity enforced in Postgres, lightweight sessions, contracts with OpenAPI, telemetry to a local collector and a CI workflow. S10a (app stack on AWS) is written and checked locally (CDK stack, images, prod Compose, deploy workflow), and deployed: the stack is up in eu-west-2 and the API serves through CloudFront, with telemetry reaching Grafana Cloud (2026-11-04); backups verified, including a restore (the $20 budget alert is set).
- ✅ Phase 2 done (2026-11-04): S2 Booking core implemented (2026-11-03). It covers the activities API, direct booking, host removal, capacity edits and booking metrics. The concurrency test and the k6 `last_spot_race` smoke pass locally, and CI passed on GitHub.
- ✅ Phase 3 done (2026-11-04), CI green on GitHub. S3 Realtime: the public activity snapshot, the WebSocket gateway with versioned events and Plan and attendance hints, the database listener with resync, and render acknowledgements for latency; the k6 `viewers` smoke passes locally (250 sockets, p95 47 ms). S4 Invites, attribution and read APIs: vouch and public invites, the open beacon, claims through the booking engine with immutable, hash-chained attribution, code-guessing and public-link limits with pause and auto-pause, and every read API the clients need.
- ✅ Phase 4 closed by the owner (2026-11-05), with exceptions accepted: the API and web are deployed; the Flutter app is not distributed and was tested by the owner on a real phone; deep links stay as built (verified App Links on Android, code entry on iOS). Open S6 findings (beacon `503`, hero photo budget) stay recorded in its VALIDATION. The app was also rebuilt on `flutter_bloc`, and its community map gained a preview carousel.
- 🔄 Phase 5 started (2026-11-05): S8 (metrics, flags and admin) implemented locally and verified, passed with exceptions. Dashboards and alerts are pushed to Grafana Cloud; deployment is outstanding. S9 is next.

## Milestones

### M0: Decisions ✅

All decided on 2026-11-03 and recorded in the [MVP plan](spec/2026-11-03_07-42_group-bookings-mvp-plan/PLANNING.md), §10:

- **Stack:** Bun + Hono API, Next.js web, Flutter mobile, PostgreSQL, in a Bun-workspaces monorepo.
- **Realtime:** Postgres `NOTIFY` with WebSockets.
- **Hosting:** AWS eu-west-2, a single EC2 instance with Docker Compose behind CloudFront, on the free `cloudfront.net` hostname.
- **Repository:** git + GitHub + Actions.
- **Observability:** OpenTelemetry → Grafana Cloud free tier.
- **Load testing:** k6, with full runs from a temporary spot EC2 in eu-west-2.
- **Product:** PRD decisions D1–D5 and Q1–Q7 confirmed by the owner; standalone prototype.

### M1: Prototype 📋

The PRD sizes this at 48 hours. That is an estimate, not a deadline.

All PRD P0 requirements, plus the concurrent last-spot test, metrics endpoint and admin page, SQL views for invite rate, open-to-claim and K-factor by rail, and the `group_invites` flag with holdout assignment. (PRD: Release plan)

Highest-risk items to prove first: no overselling, live counts, trustworthy attribution. Delivered through Phases 1–5 below (delivery specs S1–S10 from the MVP plan, §7).

### M2: Staged rollout 📋

Internal → one community (Explore Kenya) → general availability with a 10% holdout → keep, iterate or remove based on the holdout result. Exit criteria are in the PRD's release plan.

### M3: Next 📋 / 🔍

In PRD order:

1. 📋 Waitlist and booker cancellation together (X1, X3), with 24 h reminders and a one-tap "can't make it".
2. 🔍 Vouch spot hold (X2), only if sell-out loss exceeds 10% of vouch opens (D2).
3. 📋 Push notifications when a friend claims.
4. 🔍 Host payouts, once payments are in scope.

## Phases

Phases group the delivery specs from the [MVP plan](spec/2026-11-03_07-42_group-bookings-mvp-plan/PLANNING.md), §7, by risk: correctness first, polish last. A phase starts when the previous phase meets its exit criteria. Each delivery spec inside a phase still needs its own authorization before implementation.

| Phase | Milestone | Delivery specs | Goal | Exit criteria | Status |
| --- | --- | --- | --- | --- | --- |
| 0. Decide and design | M0 | PRD, constitution, MVP plan, UX, Google Maps, complete UI design | Agree what to build and how, and design all of it | PRD confirmed with the Google Maps amendments; MVP plan, UX and Google Maps specs approved; Velio design system and every screen and state designed at high fidelity in Claude Design and approved | ✅ Done 2026-11-03 |
| 1. Foundations | M1 | S1, S10 (app stack) | A tested, deployable, observable empty system | CI green; all migrations apply (including the location columns from the Google Maps spec); append-only grants and triggers enforced; contracts package generates OpenAPI (the Dart client follows in S7); telemetry reaches Grafana Cloud; a health endpoint serves through the `cloudfront.net` hostname | 🔄 S1 implemented, CI green on GitHub; S10 app stack deployed and serving `/api/healthz` through `cloudfront.net`; telemetry reaches Grafana Cloud (2026-11-04) |
| 2. Correctness core | M1 | S2 | Prove overselling is impossible (R1) | Concurrency test passes in CI against real Postgres; k6 `last_spot_race` smoke returns exactly N successes; idempotent retries, removal and capacity edit covered | ✅ Done 2026-11-04: S2 implemented; all exits met, CI green on GitHub |
| 3. Realtime and invites | M1 | S3, S4 (in parallel) | Live counts and trustworthy attribution | Versioned events with snapshot and poll fallback; commit-to-render latency measured; vouch double-claim race never double-claims; attribution and hash chain are append-only and audit clean; rate limits and pause work | ✅ Done 2026-11-04: S3 and S4 implemented; all exits met, CI green on GitHub |
| 4. Clients | M1 | S5, S6, S7 (in parallel) | Every P0 flow usable on web and mobile | **Gate:** complete UI design approved (Phase 0) ✅. **Exit:** host, booker and guest flows work end to end against the deployed stack; deep links open the app on Android with the web fallback otherwise (iOS uses code entry: no Apple Developer account, decided 2026-11-04) | 🔄 S5 implemented and verified on the deployed stack (2026-11-04, passed with exceptions: no accessibility pass, left to S9; two small defects found, fixed and checked on the deployed stack). S6 checked on the deployed stack (2026-11-04): flows, live states, previews and Lighthouse pass (FCP 0.8–0.9 s); open: real-photo hero weight, a beacon 503, the live member line, and the owner's real-phone checks. S7 implemented (2026-11-04): the app completes the claim flow against the deployed stack on the iOS simulator and an Android phone; verified App Links open invites in the app on Android; native maps need the mobile keys. S7b (2026-11-05): the Flutter app reaches web parity (communities, activity pages and booking, Host / Booker toggle, My activities, create and edit with photo and location, live attendance), verified on the iOS simulator against the local API. ✅ Closed by the owner 2026-11-05 with exceptions accepted (see Current status) |
| 5. Measure and harden | M1 | S8, S9, S10 (load-runner stack) | Prototype complete and verified | Admin page shows the five PRD goals; holdout assignment and exposures recorded; dashboards and alerts live; full k6 suite at 10× assumed peak passes with a recorded baseline; Lighthouse invite-page budget met; accessibility pass; Playwright and Flutter E2E green | 🔄 S8 implemented locally and Grafana pushed (2026-11-05); deployment outstanding |
| 6. Staged rollout | M2 | Not yet specified | Earn a keep / iterate / remove decision | PRD release-plan exits: internal → Explore Kenya → GA with 10% holdout → decide. **Before GA:** real authentication (SEC-008) and an encrypted origin hop (SEC-009) | 📋 |
| 7. Next | M3 | Not yet specified | Growth levers, in PRD order | Waitlist and cancellation (X1, X3); vouch hold (X2) only if D2's trigger fires; push notifications; host payouts | 📋 / 🔍 |

**Deployment track:** S10 starts in Phase 1 so deep links can be tested on real devices during Phase 4, and finishes with the load-runner stack in Phase 5.

**Critical path:** S1 → S2 → S3 / S4 → S5 / S6 / S7 → S8 → S9.

## Constraints and risks

- Zero oversold bookings is a hard requirement; correctness is enforced in the database (PRD R1).
- Guests arrive mostly on mobile with weak connections (PRD performance NFR).
- Attribution must be append-only and auditable (PRD I5, R11).
- The full risk register is in the PRD (R1–R12).

- The prototype runs on one EC2 instance: a single point of failure, accepted for now, with Fargate + RDS as the upgrade path.

## Out of scope

Payments (prices shown, not charged), full authentication, trust scores, host verification, activity cancellation by hosts (PRD Q1), integration with Velio's production systems (PRD Q6). (PRD: Non-goals)

## Open questions

None blocking. The remaining assumptions are listed in the MVP plan, §10: the assumed peak load, mobile OS minimums, `Bun.sql` `LISTEN` support, and CloudFront VPC origins for EC2.

## Specifications

| Spec | Milestone | Status |
| --- | --- | --- |
| [2026-11-03_07-25_establish-sdd-constitution](spec/2026-11-03_07-25_establish-sdd-constitution/) | Process | Implemented |
| [2026-11-03_07-42_group-bookings-mvp-plan](spec/2026-11-03_07-42_group-bookings-mvp-plan/) | M0, M1 | Approved |
| [2026-11-03_09-09_ux-design](spec/2026-11-03_09-09_ux-design/) ([archived prototype](https://claude.ai/artifact/NirxnmSocq3eaLLrAwxjBe)) | Phase 0 | Approved; screens superseded by the complete UI design |
| [2026-11-03_09-29_s1-foundations](spec/2026-11-03_09-29_s1-foundations/) | M1 · S1 | Implemented |
| [2026-11-03_10-34_google-maps-locations](spec/2026-11-03_10-34_google-maps-locations/) | Phase 0 | Approved |
| [2026-11-03_10-34_complete-ui-design](spec/2026-11-03_10-34_complete-ui-design/) ([design system](https://claude.ai/artifact/HVyi155enP8ug5BVzdg8qz), [screens](https://claude.ai/artifact/9hFK2e2AhKVGMsrwPMei48)) | Phase 0 | Implemented |
| [2026-11-03_16-15_s10-aws-app-stack](spec/2026-11-03_16-15_s10-aws-app-stack/) | M1 · S10 (app stack) | Approved for implementation; deployed and serving, budget alert set, telemetry in Grafana Cloud, backups, restore and rollback verified |
| [2026-11-03_22-30_s2-booking-core](spec/2026-11-03_22-30_s2-booking-core/) | M1 · S2 (Phase 2) | Implemented |
| [2026-11-04_11-42_s3-realtime](spec/2026-11-04_11-42_s3-realtime/) | M1 · S3 (Phase 3) | Implemented |
| [2026-11-04_11-42_s4-invites-attribution](spec/2026-11-04_11-42_s4-invites-attribution/) | M1 · S4 (Phase 3, includes the read APIs) | Implemented |
| [2026-11-04_12-50_s5-web-host-booker](spec/2026-11-04_12-50_s5-web-host-booker/) | M1 · S5 (Phase 4, includes the shared web foundation) | Implemented |
| [2026-11-04_12-50_s6-web-invite-claim](spec/2026-11-04_12-50_s6-web-invite-claim/) | M1 · S6 (Phase 4) | Approved for implementation |
| [2026-11-04_12-50_s7-flutter-app](spec/2026-11-04_12-50_s7-flutter-app/) | M1 · S7 (Phase 4) | Implemented |
| [2026-11-04_23-59_s7b-flutter-web-parity](spec/2026-11-04_23-59_s7b-flutter-web-parity/) | M1 · S7b (Phase 4; departs from PRD M1, owner-approved) | Implemented |
| [2026-11-05_00-40_flutter-bloc-refactor](spec/2026-11-05_00-40_flutter-bloc-refactor/) | M1 · Phase 4 (internal) | Implemented |
| [2026-11-05_08-02_explore-map-preview](spec/2026-11-05_08-02_explore-map-preview/) | M1 · Phase 4 (A6 polish) | Implemented; API change not yet deployed |
| [2026-11-05_08-36_s8-metrics-flags-admin](spec/2026-11-05_08-36_s8-metrics-flags-admin/) | M1 · S8 (Phase 5) | Implemented locally, Grafana pushed; deployment outstanding |
