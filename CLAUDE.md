# Project Constitution

This file is the authoritative source of development rules for this project. If another document conflicts with it, this file wins; flag the conflict to the user.

**Core principle: Plan first. Document everything. Validate before implementation. Implement only with explicit authorization.**

## Project facts (verified 2026-11-03)

- **Product:** Velio Group Bookings. Hosts list activities with fixed spots, bookers reserve and invite friends into a shared Plan, guests claim spots from a link or code. Source of truth for product intent: `Velio Group Bookings PRD.md`.
- **Code:** none yet. No application, tests, build tooling or dependencies exist.
- **Version control:** the directory is not a git repository.
- **Stack named in the PRD:** responsive web app, Flutter mobile app, SQL database (Postgres-style queries), Redis pub/sub, WebSockets. Backend language, web framework, database engine and hosting are **not decided**. See open questions in `ROADMAP.md`. Do not assume them.

## Documents

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | Development rules (this file). |
| `Velio Group Bookings PRD.md` | Product requirements: what to build and why. |
| `ROADMAP.md` | High-level direction, milestones and status. |
| `CHANGELOG.md` | History of completed, meaningful changes. Maintained with the `changelog` skill. |
| `spec/` | One timestamped directory per non-trivial task. |
| `.claude/skills/changelog/SKILL.md` | How to update `CHANGELOG.md`. |

Feature specs derive from the PRD. If a spec needs to depart from the PRD, record the departure in the spec's `PLANNING.md` and raise it with the user. Do not silently edit the PRD to match an implementation.

## 1. Authorization boundary (mandatory)

**Never implement code or execute implementation actions until the user explicitly tells you to.**

Allowed without implementation authorization:

- Reading, searching and inspecting the repository.
- Creating and editing specification documents under `spec/`.
- Proposing designs, listing files that may change, designing tests and acceptance criteria.
- Reviewing plans; reporting risks, dependencies and open questions.
- Documentation-only edits the user asked for.

Requires explicit implementation authorization:

- Writing or modifying application code, business logic or runtime configuration.
- Creating or changing database schemas or migrations.
- Installing dependencies or changing versions.
- Running commands that modify application state or external resources.
- Deploying, publishing or releasing.
- Infrastructure or data mutations.
- Any change outside an approved scope.

A request to discuss, investigate, design, plan, specify or review is **not** authorization to implement. When authorization is unclear, stop and ask.

### Approval policy

Approving a spec and authorizing implementation are separate steps.

| User says | What it authorizes |
| --- | --- |
| "Plan X" / "Spec X" | Planning and spec documents only. |
| "Review the X spec" | Review only. Report findings; edit the spec only if asked. |
| "Approve the X spec" | The spec is accepted as the plan. **No implementation.** Ask whether to implement. |
| "Implement the approved spec in `spec/<dir>`" | Implementation of that spec's scope only. |
| "Plan and implement X" | Write the spec first, confirm the scope is clear, then implement within it. If the spec raises open questions that affect scope, stop and ask before implementing. |
| "Fix the failing test" | Investigate and plan first. Present the fix and wait for authorization to change code. |

Silence, urgency, "continue", or approval given for a different task never authorize implementation. Authorization covers only the identified scope; it does not carry over to the next task.

## 2. Mandatory workflow

Applies to all non-trivial features, architectural changes, refactors, infrastructure changes and bug fixes.

1. **Understand.** Inspect the relevant code, docs, tests and the PRD. Establish current behavior, constraints, dependencies, risks and unknowns. Ask when critical information is missing.
2. **Plan.** Define the solution before changing anything. Identify affected components, files, interfaces and dependencies. Explain design decisions and alternatives where relevant. Cover security, performance, maintainability, accessibility and operations where applicable. Break the work into small, ordered, verifiable tasks. Define how success is measured.
3. **Specify.** Create a new directory under `spec/` (naming below) containing `PLANNING.md`, `REQUIREMENTS.md` and `VALIDATION.md`. All three must exist before implementation is authorized.
4. **Review.** Check the spec for completeness, consistency, feasibility and ambiguity. Confirm every requirement is testable and mapped to a check. List open questions and assumptions. Present the spec path and a summary to the user, then **wait for explicit authorization**.
5. **Implement** (only after authorization). Follow the approved plan, work incrementally, make no unrelated changes and do not silently expand scope. If a significant design change or new requirement appears, stop and ask. When the approved plan changes, update the spec and add an entry to its change log section; never rewrite history silently.
6. **Verify.** Run the relevant tests, static analysis, formatters and other checks. Compare the result against every requirement. Record actual outcomes in `VALIDATION.md`. Never report a check as passed unless it actually ran and passed. Record incomplete work, limitations and deviations.
7. **Record and report.** Update `CHANGELOG.md` using the `changelog` skill when the change is user- or developer-relevant. Report work done, files changed, verification results, outstanding issues and the spec path.

### Proportionality

- Questions, explanations, read-only investigation and documentation-only requests: no spec needed. Answer or make the documentation change directly.
- Small but non-trivial code changes still need a spec, but it may be short. Do not skip the workflow because a change looks small.
- Bug fixes, security fixes and urgent production issues: planning may be concise; the authorization boundary still applies.
- If the user explicitly grants an exception, apply it only within its stated scope.

## 3. Specification directories

Format: `spec/YYYY-MM-DD_HH-mm_<spec-name>/`

- Use the actual local date and time at creation (24-hour clock). Get it from `date '+%Y-%m-%d_%H-%M'`; do not guess.
- `<spec-name>` is descriptive, lowercase kebab-case.
- The timestamp is the creation time, not the implementation time.
- Never overwrite an existing spec directory. On collision, append seconds (`_HH-mm-ss`).
- Each spec is self-contained: a reader should understand it without the conversation that produced it.
- Every spec contains exactly the three documents below. Supporting files (diagrams, fixtures) may sit alongside them.

### `PLANNING.md`: how the work will be approached

Required sections:

1. Title, spec ID (directory name), created timestamp, status (`Draft` / `In review` / `Approved` / `Approved for implementation` / `Implemented` / `Abandoned`).
2. Problem statement.
3. Context and current behavior.
4. Desired outcome.
5. Proposed solution and rationale.
6. Architectural considerations.
7. Components and files affected.
8. Implementation phases and ordered tasks.
9. Dependencies and prerequisites.
10. Risks and mitigations.
11. Alternatives considered (where useful).
12. Assumptions and open questions.
13. Estimated complexity (where useful).
14. Related specs and PRD sections.
15. Change log (dated amendments after approval).

Mark every claim as one of **Verified** (checked in code or docs, with reference), **Assumption**, or **Proposal**. Never present an unverified assumption as fact.

### `REQUIREMENTS.md`: what the implementation must achieve

Required sections: purpose and scope; goals and non-goals; functional requirements; non-functional requirements; user stories or use cases (where useful); acceptance criteria; business rules and edge cases; error handling and failure behavior; security and privacy; performance and reliability; compatibility constraints; data and migration; dependencies and integrations; explicitly excluded functionality.

Use stable IDs that never get renumbered: `FR-001` functional, `NFR-001` non-functional, `SEC-001` security and privacy, `AC-001` acceptance criteria. Removed requirements are struck through, not deleted. Where a requirement comes from the PRD, cite its PRD ID (for example, `FR-003 (PRD B1)`).

Every requirement must be specific enough to verify. Do not invent numeric targets or business rules. Use the PRD's figures where they exist; otherwise record an open question.

### `VALIDATION.md`: how conformance is checked

**Part A: Planned checks** (written before implementation):

- Spec review checklist.
- Requirement-to-check traceability table (every FR/NFR/SEC/AC maps to at least one check, or states why not).
- Proposed unit, integration and end-to-end tests.
- Static analysis and formatting checks.
- Security and performance checks (where relevant).
- Manual verification procedures.
- Preconditions and test data.
- Expected results.
- Known limitations and open questions.

**Part B: Executed checks** (filled in only after implementation):

- Each check actually run: exact command or procedure, date, pass/fail, requirements covered, result or failure summary.
- Checks not run, and why.
- Known defects and deviations from the plan.
- Final validation status: `Passed` / `Passed with exceptions` / `Failed` / `Not run`.

Keep Part A and Part B separate. A proposed check is never marked as passed.

## 4. General rules

- Preserve existing useful documentation. Do not overwrite it without reading it first.
- Keep `ROADMAP.md` consistent with specs and the PRD. Update it when milestones or strategic decisions change.
- Do not add scripts, automation, agents, dependencies or extra docs unless a task needs them.
- If a key architectural decision is unclear, document the uncertainty and ask. Do not invent one.
- Implementation reports always reference the spec directory.
