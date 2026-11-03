# Validation: UX design for Group Bookings MVP

## Part A: Planned checks

| ID | Check | Covers | Expected |
| --- | --- | --- | --- |
| UX-V1 | Walk the PRD Edge cases table row by row against the canvas and the S screens | FR-002 | Every row has a state and copy |
| UX-V2 | Play each prototype artboard through every scenario tweak | AC-001–AC-003 | Flows complete; no dead ends |
| UX-V3 | Compute contrast for every text/background pair in the tokens | NFR-001 | All ≥ 4.5:1 (or 3:1 where allowed) |
| UX-V4 | Keyboard-only pass through the prototype | NFR-004 | Every control reachable, focus visible |
| UX-V5 | Review by the product owner on a phone (share the canvas link) | FR-001, FR-004–FR-007 | Approved or change list |
| UX-V6 | Wireframes exist for G8, H2, H3, C1, P1, A1 and X1 before S5–S7 | AC-004, FR-001 | Present |
| UX-V7 | In S5 and S7: tokens package consumed by both apps; avatar colours match for the same seed | FR-008 | Identical output |

## Part B: Executed checks

| ID | Procedure | Result | Notes |
| --- | --- | --- | --- |
| UX-V3 | Python WCAG contrast calculation over 20 palette pairs, 2026-11-03 | Pass (with fix) | Velio's `#818181` on cream = 3.51:1, so it's replaced by `#4A4A4A` (7.98:1). Lime on cream = 1.07:1, so it's restricted to fills. Every other pair used is ≥ 5.5:1. Input border `#8A8A8A` on white = 3.45:1, which passes the 3:1 limit for UI components. |
| UX-V1, UX-V2, UX-V4–UX-V7 | — | Not run | Awaiting review. The prototype was published but not play-tested in a browser by me. |

**Final validation status:** In progress.
