# Planning: Establish the spec-driven development constitution

- **Spec ID:** 2026-11-03_07-25_establish-sdd-constitution
- **Created:** 2026-11-03 07:25 (local)
- **Status:** Implemented (documentation and process only, authorized by the user's constitution request)

## Problem statement

The project has a PRD but no agreed rules for how work is planned, specified, authorized, verified and recorded. Without them, implementation could start before decisions are made, and it would be unclear what has been done.

## Context and current behavior

- **Verified:** the project root contains only `Velio Group Bookings PRD.md`. There is no code, no git repository, no `CLAUDE.md` and no `.claude/` directory.
- **Verified:** the PRD names a responsive web app, a Flutter app, a SQL database, Redis pub/sub and WebSockets, but no backend language, framework or hosting.

## Desired outcome

A constitution that every future task follows: plan, then spec, then review, then explicit authorization, then implementation, verification and changelog.

## Proposed solution and rationale

Create `CLAUDE.md` as the single authoritative rule set, since no other agent-instruction convention exists. Add `ROADMAP.md` derived only from the PRD, `CHANGELOG.md` in Keep a Changelog format, a `changelog` skill, and `spec/` with this spec as its first entry.

Templates for the three spec documents live as section lists in `CLAUDE.md` rather than as separate template files, to avoid extra documents.

## Components and files affected

Created: `CLAUDE.md`, `ROADMAP.md`, `CHANGELOG.md`, `.claude/skills/changelog/SKILL.md` and this spec directory. Unchanged: `Velio Group Bookings PRD.md`.

## Tasks

1. Inspect the repository. ✅
2. Write `CLAUDE.md`. ✅
3. Write the changelog skill and `CHANGELOG.md`. ✅
4. Write `ROADMAP.md` from the PRD. ✅
5. Record this spec. ✅
6. Review for contradictions. See `VALIDATION.md`.

## Decisions

- **Proposal, adopted:** approving a spec does not authorize implementation. Implementation needs a separate, explicit instruction naming the scope. This is the stricter of the two options in the request and can be relaxed by the user.
- **Proposal, adopted:** the PRD stays the product source of truth; specs cite PRD IDs rather than copying them.

## Risks and mitigations

- *Process overhead on small tasks.* Mitigated by the proportionality rules in `CLAUDE.md`, section 2.
- *Roadmap drifting into invented commitments.* Mitigated by limiting it to PRD content and marking undecided items ❓.

## Assumptions and open questions

- **Assumption:** the local clock is correct (timestamp taken from `date`).
- **Open:** tech stack decisions (M0 in `ROADMAP.md`).
- **Open:** whether the 48-hour build is a deadline.
- **Open:** should git be initialized? Not done, because it was not requested.

## Related

`Velio Group Bookings PRD.md`, `ROADMAP.md`.

## Change log

- 2026-11-03 07:25: created.
