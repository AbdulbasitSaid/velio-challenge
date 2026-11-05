# Web card photo overflow on phones

- **Spec ID:** `2026-11-05_10-55_web-card-photo-overflow`
- **Created:** 2026-11-05 10:55
- **Status:** Implemented

## 1. Problem statement

On the web app at phone width, activity cards with a real uploaded photo break their layout: the photo spills out of its 16:10 box, covers the card's title and details, runs into the next card and leaves a gap on the right. The user reported it from production ("event card ui overflow on web mobile"), where real photos exist.

## 2. Context and current behavior

- **Verified** (`apps/web/components/primitives.tsx` `Photo`): with a `photoUrl`, `Photo` renders an `<img>`; without one it renders the SVG scene art (`PhotoArt`).
- **Verified** (`apps/web/components/velio.css`): `.vl-activity-photo`, `.vl-plan-thumb` and `.vl-next-thumb` style only `svg` children (absolute fill or `100%` size). A real `<img>` gets only Tailwind preflight (`max-width: 100%; height: auto`), so it sits in flow at its natural size.
- **Verified** (production, `/communities/explore-kenya`, 2026-11-05): the phone card (`ActivityCard compact`, shown below 768 px) holds a 320×480 portrait photo. With the list forced to 335 px, the image measures 320×480 inside a 335×188 photo box.
- **Verified**: locally, seeded activities have no photo, so only SVG art renders and the bug does not show. That's why it wasn't caught.
- **Verified**: every other `Photo` container (`community-live`, `activity-live`, `invite/parts`, `share-link`, `host-list`, `activity-form`, claim page) already sizes `img` with Tailwind (`[&>img]:size-full [&>img]:object-cover`).

## 3. Desired outcome

Real photos fill their card's photo box and are cropped to it (`object-fit: cover`), exactly as the SVG art does, at every width.

## 4. Proposed solution and rationale

**Proposal:** extend the three CSS rules to cover `img` as well as `svg`, and add `object-fit: cover`. For `.vl-activity-photo`, `img` is positioned absolutely like the art so the `aspect-ratio` box sets the height. CSS-only and confined to the design-system stylesheet, it matches how the Tailwind containers already handle photos.

## 5. Architectural considerations

None. No component, API or markup changes.

## 6. Components and files affected

- `apps/web/components/velio.css`: `.vl-activity-photo`, `.vl-plan-thumb`, `.vl-next-thumb` image rules.

## 7. Implementation phases and ordered tasks

1. Update the three selectors in `velio.css`.
2. Run web lint, typecheck and tests.
3. Check in the browser with a real image at phone width.

## 8. Dependencies and prerequisites

None.

## 9. Risks and mitigations

- Cropping portrait photos hides their top and bottom. This is intended and matches the hero and desktop list, which already crop with `object-cover`.

## 10. Alternatives considered

- Tailwind arbitrary variants on each JSX container: they would duplicate the rule at every call site and leave the shared CSS inconsistent.

## 11. Assumptions and open questions

- **Assumption:** "event card" means the activity cards that show a photo. The user asked to check every place in production that shows real images; §2 lists them all.

## 12. Estimated complexity

Trivial.

## 13. Related specs and PRD sections

- `spec/2026-11-04_12-50_s5-web-host-booker/` (web app, "layouts hold from 360 px to desktop").

## 14. Change log

- 2026-11-05: created and implemented on the user's request ("do a responsive design fix").
