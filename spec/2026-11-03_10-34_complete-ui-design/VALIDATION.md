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
| FR-013–FR-016 | Overflow harness at the listed widths, plus a 200% text-scale pass on Flutter frames |
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

| Check | Date | Procedure | Result | Covers |
| --- | --- | --- | --- | --- |
| Component render smoke test | 2026-11-03 | Ran every design-system preview through `bundle.js` with a stub React in Node (`node smoke.js`), plus `node --check bundle.js` | Pass: 29/29 previews rendered, no exceptions | FR-001 |
| Contrast audit | 2026-11-03 | WCAG 2.1 relative-luminance script over every text, mark and boundary pair used in the components and screens (31 pairs) | Pass: all text pairs ≥ 4.5:1 (lowest danger on cream 5.57); all marks and boundaries ≥ 3:1 (lowest field border on surface 3.45) | NFR-001, AC-003 |
| Inventory audit | 2026-11-03 | Compared the 41 canvas artboards and their Tweaks states against PLANNING §5.3 | Pass with notes: every screen and listed state is present. B5 is a state of B1; X2 and X3 are covered by components on every screen, not separate artboards | FR-003, FR-004, FR-006, FR-011, AC-001 |
| Copy audit | 2026-11-03 | Listed every string not in the UX copy deck in PLANNING §5.5 as screens were built | Done: batches 1–2 approved; batches 3–5 strings await approval | FR-008, AC-004 |
| Overflow and clipping audit | 2026-11-03 | Local harness: each artboard's template rendered with the real `bundle.js` and `bundle.css` in headless Chrome, every Tweaks state, at frame width (and 390px for desktop pages); flags horizontal overflow, elements outside the frame, and content taller than the frame | First run: 22 of 41 artboards failed (6 causes, see PLANNING change log). After fixes: 41 of 41 pass | NFR-002 (partial), FR-004 |
| Responsive check (UI-D5) | 2026-11-03 | Same harness, extended for embedded screens (`dc-import`), forced widths and text scaling. Web fluid pages (21) at 360, 390, 768, 1024, 1280px; fixed-width phone web screens (11) squeezed to 360px; Flutter (9) at 360px and at 390px with text ×2 (avatar initials exempt by rule); admin at 768, 1024, 1440px | Web: 105/105 and 11/11 pass. Admin: 3/3 pass. Flutter 360px: 9/9 pass. Flutter 200% text: first run 5/9 failed (avatar initials, claim summary row); after the fixes 9/9 pass | FR-013, FR-014, FR-015, FR-016 |
| Archived canvas | 2026-11-03 | Retitled the first prototype "(archived)" and added a note linking both new artifacts | Pass | FR-012 |

**Checks not run:**
- **Visual review of the live canvas:** the Chrome extension was not connected, so the live canvas was not opened. The local harness approximates the canvas runtime; small differences are possible.
- **Click-through of the five flows (AC-002):** links are wired, but not exercised by me.
- **Touch-target measurement (NFR-002):** components use the 44px `touch-min` token, but rendered sizes were not measured.
- **Source copy into `prototype/` (FR-010):** waits for final approval.
- **Owner approval (AC-005):** pending.

**Known deviations:** listed in the PLANNING change log (B5 folded into B1, X2/X3 via components, scope removals of drafts and duplicate, guest search on phone attendance for review).

**Final validation status:** Not run (pending the owner's review and approval).
