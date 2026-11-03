# Requirements: Complete UI and UX design in Claude Design

## Purpose and scope

The design deliverables Phase 0 must produce before any client work (S5–S7). No application code. The UX spec's requirements (`spec/2026-11-03_09-09_ux-design/REQUIREMENTS.md`) still apply; this spec adds to them.

## Goals and non-goals

- **Goals:** a Velio design system and a complete, high-fidelity, partly clickable design of every MVP screen and state, including Google Maps.
- **Non-goals:** marketing pages; dark theme; localisation; final photography and illustration; pixel-perfect admin visuals beyond functional clarity.

## Functional requirements

| ID | Requirement |
| --- | --- |
| FR-001 | A Velio design system exists in Claude Design, containing the foundations and every component listed in PLANNING §5.2. |
| FR-002 | A screens design exists in Claude Design, built on that design system. |
| FR-003 | Every screen in PLANNING §5.3 is designed at high fidelity in every state listed there. |
| FR-004 | Web screens marked "both sizes" are designed at 390 and 1280 px wide; other web screens at 390 px; Flutter screens at phone size. |
| FR-005 | The five flows in PLANNING §5.4 are clickable. |
| FR-006 (Maps FR-001–FR-013) | Every map surface and state from the Google Maps spec is designed: picker, location block, interactive and native maps, community map, failure and offline placeholders. |
| FR-007 (UX FR-002) | Every PRD edge case maps to a designed state with its copy. |
| FR-008 (UX FR-009) | All UI strings come from the copy deck; new strings are added to the copy deck in this spec before use. |
| FR-009 | Every screen is labelled with its inventory ID and the PRD requirements it serves. |
| FR-010 | Artifact links are recorded in PLANNING.md, and a source copy is saved in `prototype/`. |
| FR-011 (PRD L2, proposed) | My plans (B6) is designed on web and Flutter in every state in PLANNING §5.3. |
| FR-012 (UI-D4) | The existing canvas is labelled as archived and links to the new artifacts; its content is not changed otherwise. |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-001 (UX NFR-001) | WCAG 2.1 AA contrast on every screen and component. |
| NFR-002 (UX NFR-002) | Touch targets ≥ 44 × 44 px. |
| NFR-003 (UX NFR-003, NFR-004) | Reduced-motion and focus states are designed for interactive components. |
| NFR-004 | The design system introduces no colour, size or radius outside the token set without amending the tokens. |

## Acceptance criteria

- **AC-001:** an inventory audit finds every screen and state in PLANNING §5.3 on the canvas.
- **AC-002:** each of the five flows can be clicked through end to end.
- **AC-003:** a contrast audit of every text and boundary colour pair passes NFR-001.
- **AC-004:** a copy audit finds no UI string missing from the copy deck.
- **AC-005:** the owner approves the design system and the screens.

## Business rules and edge cases

The PRD's Business rules and Edge cases tables are normative. Designs follow names by audience (PRD Q12), the price line (UX-1), the booking reference (UX-2) and the location lock (Maps FR-005).

## Error handling and failure behavior

Every network-dependent screen shows its loading, error and offline states (G3, B1, B5, C1, X2, X4, map placeholders).

## Security and privacy

- Public surfaces never show full names or contact details (PRD Q12, D5).
- Claim disclosure copy is shown as designed (UX FR-006).
- The location picker states the pin is public (Maps SEC-M05); the privacy note mentions Google Maps (Maps SEC-M03).

## Performance and reliability

The G1 and G2 designs fit the invite-page budget (MVP plan §4.10): map below the fold, no extra web fonts, hero image sized for ≤ ~60 kB.

## Compatibility constraints

Web phone and desktop; Flutter on iOS and Android with platform conventions noted where they differ (back navigation, share sheet, maps app choice).

## Data and migration

None.

## Dependencies and integrations

Claude Design (Design and Design System types); the Google Maps spec.

## Explicitly excluded

Any screen not in PLANNING §5.3 unless the owner adds it; marketing, dark theme, localisation.
