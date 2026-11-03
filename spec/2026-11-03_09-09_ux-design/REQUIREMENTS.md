# Requirements: UX design for Group Bookings MVP

## Purpose and scope

The design deliverables that must exist before S5–S7 are implemented, and the UX rules the built screens must follow. No application code.

## Goals and non-goals

- **Goals:** screens, states, tokens, components and copy for every MVP surface; a clickable prototype of the guest, booker and host flows.
- **Non-goals:** pixel-final visuals for the admin page; brand work beyond Velio's existing palette; marketing pages.

## Functional requirements

| ID | Requirement |
| --- | --- |
| FR-001 | Every screen in the PLANNING inventory has a design at status P or S, or a wireframe (W) before its delivery spec starts. |
| FR-002 | Every PRD edge case maps to a designed state with its copy. |
| FR-003 | The spots badge has defined states (normal, just changed, last 2, sold out, stale) and is used on every screen that can book. |
| FR-004 | Vouch and public invite pages differ as designed: inviter lead and note for vouch; community chip and "Shared by" for public. |
| FR-005 | Public surfaces show people as "First L." with initials avatars; Plan and host views show full names (PRD Q12). |
| FR-006 | The claim form asks for exactly two fields (name, phone or email) and shows the rail-specific disclosure. |
| FR-007 | Sold-out and expired screens offer "Tell [inviter]", the host's other dates and "More in [community]", hiding empty blocks. |
| FR-008 | Tokens are defined once in `packages/design-tokens` and consumed by both Tailwind (web) and Dart (Flutter). |
| FR-009 | The canonical copy deck is the source for UI strings. A change to the copy goes through this spec. |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-001 | All text meets WCAG 2.1 AA contrast (4.5:1 body, 3:1 for 24 px and larger, and for UI boundaries). Lime is never text or a sole boundary on cream. |
| NFR-002 | Touch targets are at least 44 × 44 px. |
| NFR-003 | Live changes respect `prefers-reduced-motion` (fade instead of flash) and are announced politely to screen readers, at most once per 5 s. |
| NFR-004 | Every interactive element is a real button, link or input with a visible focus style. |

## Acceptance criteria

- **AC-001:** the prototype runs the guest flow (open → claim → you're in), all four scenarios (available, sold out, offline, expired) and both rails.
- **AC-002:** the prototype runs the booker flow (book → invite prompt → vouch → Plan) and the sold-out-mid-checkout outcome.
- **AC-003:** the host prototype shows a live arrival, remove with confirmation (spots go up by 1), and attendance marking after start.
- **AC-004:** every W screen has a wireframe before its delivery spec is approved.

## Excluded

Final illustration and photography, a dark theme (not in the PRD), localisation (English only).
