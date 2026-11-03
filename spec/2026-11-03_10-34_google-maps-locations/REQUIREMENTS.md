# Requirements: Google Maps locations

## Purpose and scope

Give every activity a precise location shown on a map with directions, a host picker to set it, and a community map view. This spec defines the requirements; code lands in S1, S5, S6, S7 and S10.

## Goals and non-goals

- **Goals:** a precise host-confirmed location; maps with directions wherever an activity is shown; a community map; no regression on the invite page's performance budget.
- **Non-goals:** search by distance or "near me"; the user's current location; in-app turn-by-turn navigation; travel-time estimates; maps in the host attendance view.

## Functional requirements

| ID | Requirement |
| --- | --- |
| FR-001 (PRD A4) | The host sets the location in create and edit activity by searching Google Places (Autocomplete) and confirming a draggable pin. Venue name and address are prefilled from the place and editable. |
| FR-002 (PRD A4) | The host can drop a pin without choosing a place (`place_id` null), then must enter a venue name and address. |
| FR-003 (PRD A4) | The host can add an optional meeting-point note of at most 140 characters. |
| FR-004 | Publishing requires a pin, venue name and address. |
| FR-005 (PRD Q2, amended) | Once an activity has a booking, `place_id`, venue name, address, coordinates and meeting point cannot change. The API rejects such edits with a typed error. |
| FR-006 (PRD A5) | The web activity page (B1) shows a static map, the venue name, the address, the meeting point (if any) and "Get directions". Tapping the map loads an interactive map. |
| FR-007 (PRD A5) | The web invite pages (G1, G2) show a lazy-loaded static map below the fold with the address and "Get directions", and load no Maps JavaScript. |
| FR-008 (PRD A5) | "You're in" (G4) and Plan (B4) show the map, address, meeting point and "Get directions" on web and Flutter. |
| FR-009 (MAP-D3) | Flutter shows an interactive native map (`google_maps_flutter`) with a single marker on G1, G2, G4 and B4. |
| FR-010 (PRD A6) | The community page (C1) has List and Map views. The map shows one marker per upcoming activity with spots left, clusters nearby markers, and opens a summary card (title, date, spots left) that links to the activity. |
| FR-011 | "Get directions" opens Google Maps directions to the activity's coordinates and `place_id`. On iOS the Flutter app offers Apple Maps or Google Maps. |
| FR-012 (PRD A7) | If a map fails to load, the address, meeting point and "Get directions" still render, and booking and claiming are unaffected. |
| FR-013 (PRD M2) | The Flutter offline cache includes venue name, address, meeting point and coordinates; offline, the map area shows a "Map unavailable offline" placeholder. |
| FR-014 | The activity snapshot returns `location { placeId, venueName, addressText, lat, lng, meetingPoint, staticMapUrl, directionsUrl }`. |
| FR-015 | The static map URL is signed by the server. |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-001 (PRD performance NFR) | The invite page still meets first content < 1.5 s on mid-range Android over 3G, with claim-page JS ≤ 100 kB gzipped (MVP plan §4.10). |
| NFR-002 | The static map image has fixed dimensions and causes no layout shift. |
| NFR-003 | The Maps JavaScript API loads only after user interaction on B1, or when Map is selected on C1. |
| NFR-004 (UX NFR-001–004) | Map surfaces meet the UX spec's accessibility rules: the address is always present as text; map images have alt text; the picker works by keyboard. |
| NFR-005 | Latest stable versions of the Maps libraries, pinned exactly (CLAUDE.md). |

## Security and privacy

| ID | Requirement |
| --- | --- |
| SEC-M01 | Each API key is restricted by platform (referrer, Android package and SHA-1, iOS bundle ID) and to only the APIs it uses. |
| SEC-M02 | The Static Maps signing secret and server key are only on the server, never in a client bundle or the repository. |
| SEC-M03 | The privacy note says that maps are provided by Google and that loading one shares the viewer's IP address with Google. |
| SEC-M04 | Coordinates, addresses and place IDs never appear as metric labels (CLAUDE.md telemetry rule). |
| SEC-M05 | The host picker states that the pin and address are public (MAP-D2). |

## Acceptance criteria

- **AC-001:** a host searches "Nairobi National Park", picks it, drags the pin, adds a meeting point and publishes; the activity page shows that pin, text and a working directions link.
- **AC-002:** a host drops a pin without a place, fills venue and address, and publishes.
- **AC-003:** after one booking, an edit to any location field is rejected and the UI shows `host.locked` copy.
- **AC-004:** a Lighthouse run of the invite page under the MVP plan's 3G profile meets NFR-001, and the page makes no request to the Maps JavaScript API.
- **AC-005:** with Google's map domains blocked, every surface still shows address and directions, and booking succeeds.
- **AC-006:** the Explore Kenya community page shows markers for each upcoming activity with spots; a sold-out activity has no marker.
- **AC-007:** the Flutter app shows a native map on G1, G2, G4 and B4 on iOS and Android, and offline shows the placeholder with the cached address.
- **AC-008:** a client build contains no signing secret or server key.

## Business rules and edge cases

- Location fields lock with date and time once an activity is booked (FR-005).
- An activity removed from the community list (sold out or started) also leaves the community map.
- Activities at the same coordinates cluster into one marker with a count.
- A place with no address from Google: the host must type one (FR-004).

## Error handling and failure behavior

- Autocomplete unavailable: the host can still drop a pin on the map; if the map is also unavailable, the form explains that location can't be set right now and saves a draft.
- Static map image fails: the image area collapses to the address block (FR-012).
- Locked edit attempted: typed error `location_locked`.

## Performance and reliability

NFR-001–003. Maps are never on the booking critical path.

## Compatibility constraints

Supported browsers per S5/S6; iOS and Android minimums as set in S7, checked against `google_maps_flutter` requirements.

## Data and migration

There is no data yet, so S1's migration creates the new columns directly (MVP plan §4.3 amended). No backfill.

## Dependencies and integrations

Google Maps Platform: Maps JavaScript API, Places API (New) Autocomplete and Details, Maps Static API, Maps SDK for Android and iOS. Google Cloud billing account (OQ-3).

## Explicitly excluded

Distance search, "near me", geolocation permission prompts, in-app navigation, travel time, map styling beyond Velio tokens, maps on the attendance (H1) and admin (A1) screens.
