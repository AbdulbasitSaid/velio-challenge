# Validation: Establish the spec-driven development constitution

## Part A: Planned checks

| Check | Method | Covers | Expected |
| --- | --- | --- | --- |
| V1 | List the directory tree | FR-001, FR-007–FR-010, AC-001 | All files present at stated paths |
| V2 | Read `CLAUDE.md` against the request's sections 3 and 4 | FR-001–FR-006 | Every required element present |
| V3 | Read the skill against the request's section 6 | FR-008 | Every required element present |
| V4 | Cross-read `CLAUDE.md`, the skill, `ROADMAP.md` and the PRD for conflicts | NFR-002, AC-003 | No contradictions |
| V5 | Confirm only documentation files exist besides the PRD | AC-002 | No code or config created |
| V6 | Check roadmap claims against the PRD | FR-007 | Every item traces to the PRD or is marked ❓/🔍 |

No automated tests apply; there is no code.

## Part B: Executed checks

Executed 2026-11-03.

| Check | Procedure | Result | Notes |
| --- | --- | --- | --- |
| V1 | `find . -type f` from the project root | Pass | 8 files: PRD, `CLAUDE.md`, `ROADMAP.md`, `CHANGELOG.md`, skill, 3 spec documents |
| V2 | Manual read | Pass | Workflow, boundary, approval table, naming, three templates and proportionality present |
| V3 | Manual read | Pass | Purpose, triggers, format, accuracy rules and procedure present |
| V4 | Manual cross-read | Pass | Skill defers to `CLAUDE.md` section 1; the changelog entry records process setup only, not features |
| V5 | Same listing as V1 | Pass | No code, dependency or config files; PRD not edited in this task |
| V6 | Manual comparison | Pass | Stack and deadline items are marked ❓ rather than asserted |

**Known limitations:** none of the rules can be enforced automatically; they rely on Claude following `CLAUDE.md`.

**Final status:** Passed.
