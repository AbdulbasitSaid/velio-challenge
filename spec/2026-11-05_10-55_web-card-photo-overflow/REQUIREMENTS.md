# Requirements: web card photo overflow on phones

## Purpose and scope

Make real activity photos stay inside their card photo boxes on the web app. Scope: `apps/web/components/velio.css` only.

## Goals and non-goals

- Goal: photos fill and are clipped to their box at every width.
- Non-goal: changing card design, image sizes, `srcset`/`sizes`, or the Flutter app.

## Functional requirements

- **FR-001:** In `.vl-activity-photo` (ActivityCard, full and compact), a real `<img>` fills the photo box exactly, keeps the box's aspect ratio (16:10, compact 16:9), and is cropped with `object-fit: cover`.
- **FR-002:** In `.vl-plan-thumb` (PlanCard, including the community map popup), a real `<img>` fills the 72×72 thumbnail with `object-fit: cover`.
- **FR-003:** In `.vl-next-thumb` (next steps), a real `<img>` fills the 44×44 thumbnail with `object-fit: cover`.
- **FR-004:** SVG scene art renders as before.

## Non-functional requirements

- **NFR-001:** No horizontal page scroll and no card content overlap at 360 px wide or wider (the S5 layout range).

## Acceptance criteria

- **AC-001:** With a 320×480 photo in a 335 px wide compact card, the image's box equals the photo box (335×188) and the title is visible below it.
- **AC-002:** Existing web tests, lint and typecheck pass.

## Business rules and edge cases

Portrait, landscape and small images all cover the box; none leave gaps.

## Error handling and failure behavior

A failed image load shows the box's `--forest` background, as before.

## Security and privacy

None affected.

## Performance and reliability

No change: same image files and `sizes`.

## Compatibility constraints

`object-fit` and `inset` are supported in all target browsers.

## Data and migration

None.

## Dependencies and integrations

None.

## Explicitly excluded functionality

Image cropping or focal points chosen by the host.
