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
- Booking with no overselling, idempotent retries and Plan creation (B1–B3).
- Plans showing members and invite status (L1).
- Vouch and public invites with codes, deep links and immutable attribution (I1–I6).
- Host attendance view with removal and attended or no-show marking (H1–H2).
- Responsive web app with a Host / Booker role toggle (W1).
- Flutter mobile claim flow with a mobile-web fallback, offline-safe caching and haptics (M1–M3).
- Metrics endpoint, admin page and feature flag with holdout.

## Current status

- ✅ PRD written, enriched and confirmed by the owner.
- ✅ Development process established (`CLAUDE.md`, spec workflow, changelog).
- 🔄 MVP plan (system design, stack, structure) in review.
- No application code, repository (git) or infrastructure exists yet.

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

Highest-risk items to prove first: no overselling, live counts, trustworthy attribution. The delivery order is S1 Foundations → S2 Booking core → S3 Realtime and S4 Invites → S5–S7 Web and mobile → S8 Metrics → S9 Hardening, with S10 AWS deployment alongside from S1 (see the MVP plan).

### M2: Staged rollout 📋

Internal → one community (Explore Kenya) → general availability with a 10% holdout → keep, iterate or remove based on the holdout result. Exit criteria are in the PRD's release plan.

### M3: Next 📋 / 🔍

In PRD order:

1. 📋 Waitlist and booker cancellation together (X1, X3), with 24 h reminders and a one-tap "can't make it".
2. 🔍 Vouch spot hold (X2), only if sell-out loss exceeds 10% of vouch opens (D2).
3. 📋 Push notifications when a friend claims.
4. 🔍 Host payouts, once payments are in scope.

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
| [2026-11-03_07-42_group-bookings-mvp-plan](spec/2026-11-03_07-42_group-bookings-mvp-plan/) | M0, M1 | In review |
