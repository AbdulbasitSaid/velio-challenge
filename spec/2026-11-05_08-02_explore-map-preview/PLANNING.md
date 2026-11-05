# Planning: Explore map preview carousel

- **Spec ID:** 2026-11-05_08-02_explore-map-preview
- **Created:** 2026-11-05 08:02 (local)
- **Status:** Implemented (2026-11-05; approved for implementation by the owner, 2026-11-05: "Spec, then implement")
- **Parents:** `spec/2026-11-04_23-59_s7b-flutter-web-parity/` (C1 map, FR-003), `spec/2026-11-05_00-40_flutter-bloc-refactor/` (bloc layout).

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The owner said on 2026-11-05 that the map preview needs work. A pin should show a proper preview of its activity, with photo, name and a short description, and the preview should be interactive. The owner suggested a horizontally scrollable row of activities linked to the pins.

## 2. Context and current behavior

- [Verified, `apps/mobile/lib/explore/widgets/explore_map.dart`] The C1 map is a `GoogleMap` (3:4) with one marker per bookable activity (`ExploreState.open`). Tapping a marker opens Google's native info window with the title and "N spots left · View activity". Tapping the info window opens `/activities/:id`. There is no photo and no description, and nothing links the list to the pins. The camera starts at zoom 9 on the first open activity.
- [Verified, `packages/contracts/src/activities.ts` `ActivityCard`] Cards carry the id, title, start time, time zone, price, photo URL, capacity, spots, status, community, `location {venueName, lat, lng}` and members. They have **no description**.
- [Verified, `apps/api/src/modules/activities/snapshot.ts` `buildCards`] One function builds every `ActivityCard` (community page, My plans, profile, next steps, host lists via `HostActivityItem = ActivityCard.extend`).
- [Verified, `apps/api/migrations/20261103140100_schema.sql:109`] `activities.description text NOT NULL DEFAULT ''`, at most 5,000 characters (`ActivityCreate`).
- [Verified, `packages/api-client-dart/generate.sh`] The Dart client is generated from `openapi.json` with openapi-generator in Docker. CI fails on any diff.
- [Verified, `explore_bloc.dart`] `ExploreBloc` holds `showMap`. Live spot counts update `ExploreState.counts`, and `open` is derived from them, so a sold-out activity drops off the map live.

## 3. Desired outcome

In Map view, the map shows a horizontal carousel of preview cards over its lower edge, one card per pin. Each card shows the activity's photo, title, date and time, venue, a short summary of the description, price and live spots. Tapping a pin highlights it and scrolls the carousel to its card. Swiping the carousel highlights the matching pin and moves the camera to it. Tapping a card opens the activity. The first view frames all the pins.

## 4. Proposed solution [Proposal]

### 4.1 API: `summary` on `ActivityCard` (owner's choice, 2026-11-05)

- Contract: add `summary: z.string()` to `ActivityCard`. It is the description with whitespace collapsed, cut to at most 140 characters at a word boundary, with `…` added when cut. It is `''` when there is no description.
- `buildCards` selects `left(a.description, 400)` (so lists never read 5,000-character descriptions) and passes it through an exported pure function `summarise(text)`.
- Regenerate `openapi.json` (`bun run contracts:openapi`) and the Dart client (`bun run contracts:dart`, needs Docker). Web gets the field in its types and ignores it; no web UI change.

### 4.2 Mobile

- `ExploreState.selectedId` (nullable) plus a `selected` getter. It returns the open card with `selectedId`, or the first open card when that id is missing or no longer open (for example, it sold out live).
- New event `ExploreMapSelected(id)`. Pins and the carousel both send it.
- `ExploreMap` becomes a `StatefulWidget` that owns the `GoogleMapController` and a `PageController` (view-only controllers; selection stays in the bloc). A `BlocListener` on `selected` animates the carousel page and the camera when the selection changes from either side.
  - Markers: the selected one uses the brand-coloured hue and a higher `zIndex`. The others use the default marker. The native info window is removed, because the card replaces it.
  - Camera: on `onMapCreated`, fit bounds of all open pins with padding (one pin: zoom 12). On selection, `animateCamera(newLatLng)` keeps the zoom.
  - Carousel: a `PageView` (`viewportFraction` ≈ 0.86) positioned over the bottom of the map. The map height grows from 3:4 to 4:5 so the cards leave room for pins.
- New public widget `MapPreviewCard` in `explore/widgets/`: an 88-pixel square photo (dimmed when no spots), the title (1 line), "date · venue" (1 line), the summary (2 lines, ellipsis; hidden when empty), and a footer with price and the live `SpotsBadge`. The selected card shows a forest border. The whole card has `InkWell` → `/activities/:id`, with a semantics label of the title.

## 5. Architectural considerations

- Adding a required field is additive on the wire. Old clients ignore unknown fields (json_serializable default; web Zod objects strip). The web and mobile ship from this repo together. [Verified, CI regenerates the client]
- Truncating in SQL plus TS keeps list payloads small: at most about 141 characters per card.
- Selection lives in the bloc, matching `showMap`, so it is testable with `bloc_test`. Map and page controllers stay in the widget because they are UI handles.
- `summary` is public data, because the description is already public on `PublicActivity`. No privacy impact.

## 6. Components and files affected

- `packages/contracts/src/activities.ts`, `packages/contracts/openapi.json`
- `apps/api/src/modules/activities/snapshot.ts`, `apps/api/test/activities/snapshot.test.ts` (or `read-apis.test.ts`)
- `packages/api-client-dart/lib/**` (generated)
- Web test fixtures typed as `ActivityCard`, if typecheck requires the field
- `apps/mobile/lib/explore/bloc/explore_{event,state,bloc}.dart`, `explore/widgets/explore_map.dart`, new `explore/widgets/map_preview_card.dart`
- `apps/mobile/test/fixtures.dart` (add `summary`), `test/explore/explore_bloc_test.dart`, `test/widgets_test.dart` (preview card)
- `CHANGELOG.md`

## 7. Implementation phases and ordered tasks

1. Contract field, `summarise`, `buildCards` and API tests.
2. Regenerate `openapi.json` and the Dart client. Fix web fixtures if typecheck fails.
3. Bloc: state, event and tests.
4. `MapPreviewCard`, `ExploreMap` rewrite and widget test.
5. Verify (§ VALIDATION), CHANGELOG, report.

## 8. Dependencies and prerequisites

- Docker running, for client generation and the API test database. Flutter through fvm. No new packages.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Feedback loop: the camera moves on selection, and a page change selects again. | Only send `ExploreMapSelected` from `onPageChanged` when the id differs from the current selection. Animate the page only when it isn't already showing. |
| The `GoogleMap` can't run in widget tests. | Test the bloc and `MapPreviewCard` directly. The map is checked by hand on a simulator with `MAPS=true`. |
| The vertical page scroll fights the map's gestures. | Existing behaviour, unchanged. The carousel scrolls horizontally only. |

## 10. Alternatives considered

- Fetching the detail on selection: no contract change, but one request per swipe and late text. Rejected by the owner.
- A bottom sheet per pin: one card at a time, and you can't browse by swiping. The carousel matches the owner's suggestion.

## 11. Assumptions and open questions

- [Assumption] A 140-character cut and 2 visible lines are enough. Easy to tune.
- [Assumption] The carousel covers only the Map view. The List view is unchanged.
- No open questions block scope.

## 12. Estimated complexity

Small to medium: one contract field, one bloc event and two widgets.

## 13. Related specs and PRD sections

PRD A6 (community map of upcoming activities with spots) and A7 (maps never block booking). S7b FR-003. Google Maps spec `spec/2026-11-03_10-34_google-maps-locations/`.

## 14. Change log

- 2026-11-05: created.
- 2026-11-05: implemented. `ExploreMap` also takes `stale` for the badges. The spots badge scales down on narrow cards. **Deploy order:** `summary` is required in the generated Dart client, so app builds with this change fail to parse cards from an API without it. Deploy the API first (the app is not distributed, README).
