# Requirements: Explore map preview carousel

Spec: `spec/2026-11-05_08-02_explore-map-preview/`

## 1. Purpose and scope

Give each pin on the Flutter community map (C1, Map view) a rich, interactive preview, using a horizontal carousel linked to the pins. Add the short `summary` the preview needs to `ActivityCard`.

## 2. Goals and non-goals

- Goals: show photo, title and summary for each pin; link pins and cards both ways; open the activity from a card.
- Non-goals: web map changes, clustering, filtering, and showing sold-out or started activities on the map.

## 3. Functional requirements

- **FR-001** `ActivityCard` has `summary: string`: the description with runs of whitespace collapsed to one space and trimmed. When it is longer than 140 characters, it is cut at the last space at or before 140 characters (or hard-cut at 140 if there is none), trailing whitespace and punctuation are removed, and `…` is appended. It is `''` for an empty description.
- **FR-002** Every API response that contains an `ActivityCard` (or `HostActivityItem`) includes `summary`.
- **FR-003** In Map view, a horizontally scrollable carousel shows one preview card per pin (`ExploreState.open`), in the same order as the list.
- **FR-004** A preview card shows the photo (placeholder art when there is none), title, "date, time · venue", the summary (at most 2 lines; omitted when empty), price, and the live spots badge.
- **FR-005** Tapping a pin selects its activity: the pin is highlighted and the carousel scrolls to its card.
- **FR-006** Swiping the carousel selects the card's activity: its pin is highlighted and the camera pans to it.
- **FR-007** Tapping a preview card opens `/activities/:id`.
- **FR-008** When the selected activity leaves the map (sold out or started, live), the first remaining open activity becomes the selection.
- **FR-009** The first map view frames every open pin.

## 4. Non-functional requirements

- **NFR-001** No new dependencies. Bloc architecture: selection lives in `ExploreBloc`, and widgets hold only view controllers.
- **NFR-002** `dart format`, `flutter analyze`, `bun run lint`, `typecheck` and `format:check` are clean. The generated client matches `generate.sh` output.

## 5. Acceptance criteria

- **AC-001** The API test shows `summary` on community-page cards, collapsed and truncated per FR-001.
- **AC-002** Unit tests cover `summarise` for empty, short, whitespace-heavy, long with spaces, and long without spaces.
- **AC-003** A bloc test shows that `ExploreMapSelected` sets the selection and that `selected` falls back when the selected activity sells out.
- **AC-004** A widget test shows that `MapPreviewCard` renders title, summary and spots, and that tapping it calls back.
- **AC-005** Manual check on a simulator with `MAPS=true`: pins and cards stay in sync both ways, and a tap opens the activity.

## 6. Business rules and edge cases

- One open activity: the carousel has one card and the camera is at zoom 12.
- No open activities: there is no map content to preview. Existing behaviour stays (the map centres on the first activity, and the carousel is hidden).
- Pins at the same location: the carousel still reaches each one.

## 7. Error handling and failure behavior

Missing photo → placeholder art. If the map fails to load, the carousel cards still open activities (PRD A7).

## 8. Security and privacy

- **SEC-001** `summary` is derived only from the public description. No personal data is added, and nothing goes into telemetry.

## 9. Performance and reliability

The API reads at most 400 characters of the description per card. The selection is one bloc emit, and no network call happens per swipe.

## 10. Compatibility constraints

Additive field. Older clients ignore it.

## 11. Data and migration

No schema change.

## 12. Dependencies and integrations

Google Maps (existing). openapi-generator via Docker (existing).

## 13. Explicitly excluded

Web map UI, marker clustering, custom bitmap markers.
