# Requirements: Establish the spec-driven development constitution

## Purpose and scope

Set up the documents and skill that govern all future work. Documentation and process only.

## Goals and non-goals

- **Goals:** a clear workflow, an unambiguous authorization boundary, consistent spec structure, an honest roadmap and changelog.
- **Non-goals:** any application code, dependencies, tooling, scripts, CI or git setup.

## Functional requirements

- **FR-001:** `CLAUDE.md` exists at the root and defines the seven-phase workflow (understand, plan, specify, review, implement, verify, record).
- **FR-002:** `CLAUDE.md` defines the authorization boundary, listing permitted planning activities and activities that need explicit implementation authorization.
- **FR-003:** `CLAUDE.md` defines the approval policy with examples, including that spec approval alone does not authorize implementation.
- **FR-004:** `CLAUDE.md` defines the spec directory naming rule (`YYYY-MM-DD_HH-mm_<kebab-name>`, creation time, no overwrite, collision suffix).
- **FR-005:** `CLAUDE.md` defines the required contents of `PLANNING.md`, `REQUIREMENTS.md` and `VALIDATION.md`, including requirement IDs and separate planned and executed checks.
- **FR-006:** `CLAUDE.md` defines proportionality rules for trivial, documentation-only and urgent work.
- **FR-007:** `ROADMAP.md` covers vision, problem, users, capabilities, status, milestones, constraints, out-of-scope items, open questions and spec links, using only PRD facts or marked proposals.
- **FR-008:** `.claude/skills/changelog/SKILL.md` covers purpose, when to update, format, accuracy rules and the maintenance procedure.
- **FR-009:** `CHANGELOG.md` exists with an `Unreleased` section and no fabricated release.
- **FR-010:** `spec/` exists.

## Non-functional requirements

- **NFR-001:** documents are concise enough to read in one sitting, with no duplicated rule sets.
- **NFR-002:** no contradictions between `CLAUDE.md`, `ROADMAP.md`, the skill and the PRD.

## Acceptance criteria

- **AC-001:** all files in FR-001 to FR-010 exist at the stated paths.
- **AC-002:** no file other than documentation and the skill was created or modified, and the PRD is unchanged.
- **AC-003:** the review in `VALIDATION.md` finds no contradictory rules.

## Excluded

Feature planning for Group Bookings, stack decisions, git initialization.
