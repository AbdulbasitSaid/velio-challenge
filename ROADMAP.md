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

- ✅ PRD written and refined.
- ✅ Development process established (`CLAUDE.md`, spec workflow, changelog).
- No application code, repository (git) or infrastructure exists yet.

## Milestones

### M0: Foundations ❓

Decisions needed before any feature spec can be implemented. None are made yet.

- Backend language and framework.
- Web frontend framework.
- Database engine. The PRD's queries are Postgres-style; not confirmed.
- Real-time transport and Redis setup.
- Hosting and environments for the prototype.
- Repository setup: git, layout (monorepo or separate repos), CI, test tooling.

### M1: 48-hour prototype 📋

All PRD P0 requirements, plus the concurrent last-spot test, metrics endpoint and admin page, SQL views for invite rate, open-to-claim and K-factor by rail, and the `group_invites` flag with holdout assignment. (PRD: Release plan)

Depends on M0. Highest-risk items to prove first: no overselling, live counts, trustworthy attribution.

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

## Out of scope

Payments (prices shown, not charged), full authentication, trust scores, host verification. (PRD: Non-goals)

## Open questions

- All M0 decisions above.
- Is the "48-hour build" a hard deadline for this project, or the PRD's sizing of the prototype?
- Who is the PRD author or product owner who confirms decisions D1–D5? (The byline reads `@Someone`.)

## Specifications

| Spec | Milestone | Status |
| --- | --- | --- |
| [2026-11-03_07-25_establish-sdd-constitution](spec/2026-11-03_07-25_establish-sdd-constitution/) | Process | Implemented |
