# Validation: Complete UI and UX design in Claude Design

## Part A: Planned checks

### Spec review checklist

- [ ] Inventory covers every PRD user-facing requirement (A1–A7, B1–B3, L1–L2, I1–I3, H1–H2, W1, M1–M3) and every Edge case.
- [ ] Map screens match the Google Maps spec.
- [x] OQ-1 and OQ-2 answered (UI-D3, UI-D4, 2026-11-03).
- [ ] PRD amendment L2 approved before B6 is treated as final.

### Traceability

| Requirement | Check |
| --- | --- |
| FR-001, NFR-004 | Design system review: foundations and component list against PLANNING §5.2; token diff against the UX spec token set |
| FR-002, FR-009 | Canvas review: screens use design-system components; each labelled with ID and PRD refs |
| FR-003, FR-004, FR-006, FR-007 | Inventory audit (AC-001): table of screen × state × size, ticked on the canvas |
| FR-005 | Click-through of the five flows (AC-002) |
| FR-008 | Copy audit (AC-004) |
| FR-010 | Links in PLANNING.md; files present in `prototype/` |
| FR-011 | Inventory audit includes B6 on web and Flutter |
| FR-012 | Open the old canvas link: archived label and links to the new artifacts present |
| NFR-001 | Contrast audit with the WCAG 2.1 formula on every colour pair used (AC-003) |
| NFR-002 | Measure interactive elements on the canvas |
| NFR-003 | Review focus and reduced-motion variants of interactive components |
| AC-005 | Owner approval recorded in PLANNING change log |

### Proposed tests

Design reviews only; there is no code. Real behavior (maps, 3G, haptics, deep links) is tested in S5–S7.

### Static analysis

Not applicable.

### Manual verification

Owner review per flow, through comments on the artifacts.

### Preconditions and test data

Sample data from the PRD personas: Amara (host), Tunde (booker), Zainab (vouched guest), Kofi (public visitor); Sunset Kayaking and activities in the three seeded communities with real place names.

### Expected results

All ACs met; owner approval.

### Known limitations

Stand-in fonts; representative map imagery instead of live Google Maps; no real performance measurement.

## Part B: Executed checks

Not run.

**Final validation status:** Not run.
