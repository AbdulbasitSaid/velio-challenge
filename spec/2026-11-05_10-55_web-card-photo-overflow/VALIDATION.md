# Validation: web card photo overflow on phones

## Part A: Planned checks

### Spec review checklist

- [x] All three documents exist; each requirement maps to a check.

### Traceability

| Requirement | Check |
| --- | --- |
| FR-001, AC-001, NFR-001 | V-1 browser measurement |
| FR-002, FR-003 | V-1 (computed styles), V-2 |
| FR-004, AC-002 | V-2 |

### Checks

- **V-1 (manual, browser):** on a page with real photos, constrain the card list to 335 px, show the phone card, and measure the `img` box against `.vl-activity-photo`; check the computed `object-fit` of thumbnails.
- **V-2 (automated):** `bun run lint`, `bun run typecheck` (or equivalent) and `bun run test` in `apps/web`.

### Preconditions and test data

Production (`/communities/explore-kenya`) has real photos; locally the seed has none, so V-1 injects the patched rules into the production page, or uses a local activity with a photo.

### Known limitations

The browser window can't be resized below desktop width here, so phone width is simulated by constraining the container width.

## Part B: Executed checks

| Check | Command / procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-1 before | Production `/communities/explore-kenya`, list constrained to 335 px, phone card shown: measured the `img` against `.vl-activity-photo` | 2026-11-05 | Reproduced: image 320×480 in a 335×188 box, covering the title and the next card | baseline |
| V-1 after | Same page with the patched rules injected | 2026-11-05 | Pass: image 335×188 = box, title visible, no horizontal scroll (screenshot checked) | FR-001, AC-001, NFR-001 |
| V-2 format | `bun x prettier --check apps/web/components/velio.css` | 2026-11-05 | Pass | AC-002 |
| V-2 tests | `bun run test` in `apps/web` | 2026-11-05 | Pass: 18 files, 226 tests | FR-004, AC-002 |

**Not run:** lint and typecheck (CSS-only change, no TS or JS touched). FR-002 and FR-003 weren't measured separately: the thumbnails are fixed-size boxes with `overflow: hidden`, and the new rules match the existing SVG rules plus `object-fit: cover`. The fix is not deployed; production still shows the bug until the next deploy.

**Final status:** Passed with exceptions (lint and typecheck not run; not deployed).
