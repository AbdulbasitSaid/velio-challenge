# Planning: Google Maps locations

- **Spec ID:** 2026-11-03_10-34_google-maps-locations
- **Created:** 2026-11-03 10:34 (local)
- **Status:** Approved (2026-11-03). Implementation not yet authorized.
- **Phase:** 0 (Decide and design), reworked on 2026-11-03
- **Depends on:** `Velio Group Bookings PRD.md` (A1, Business rules, Q2, Q11), `spec/2026-11-03_07-42_group-bookings-mvp-plan/`
- **Affects:** `spec/2026-11-03_09-29_s1-foundations/` (schema), `spec/2026-11-03_10-34_complete-ui-design/` (screens)

Claims are tagged **[Verified]**, **[Assumption]** or **[Proposal]**.

## 1. Problem statement

An activity's location is a free-text field (PRD A1). Guests travelling to an unfamiliar place, such as Tunde planning Nairobi from London, cannot see where an activity is or how to get there, and hosts cannot point to a precise meeting spot. The product owner asked on 2026-11-03 for Google Maps "where necessary".

## 2. Context and current behavior

- [Verified] PRD A1: the host enters "location" as one field. No coordinates, map or directions exist anywhere in the PRD, MVP plan or UX spec.
- [Verified] PRD Business rules: date, time and location are locked once an activity has a booking (Q2).
- [Verified] PRD Business rules: communities span countries (Explore Kenya, The Tanzania Experience, The Medina Collective), and each has a page listing upcoming activities (Q11).
- [Verified] MVP plan §4.10: the invite page must show first content in under 1.5 s on mid-range Android over 3G, with claim-page JS ≤ 100 kB gzipped.
- [Verified] S1 Foundations (in review) creates the `activities` table with a text `location` column.
- [Verified, Google Maps Platform pricing page, checked 2026-11-03] Essentials SKUs, including Dynamic Maps, Static Maps and Autocomplete Requests, each have 10,000 free requests per month.
- [Verified, Google Maps Platform service specific terms, checked 2026-11-03] A Places `place_id` may be stored indefinitely. Latitude and longitude from Google services may be cached for at most 30 consecutive days.

## 3. Product decisions (owner, 2026-11-03)

| # | Decision |
| --- | --- |
| MAP-D1 | Maps appear in four places: the host's location picker, a map with directions on every activity surface, an optional meeting-point note, and a map view on community pages. |
| MAP-D2 | The exact location is public: any visitor to an activity or invite page sees the exact pin and address. |
| MAP-D3 | The Flutter app embeds an interactive native map (`google_maps_flutter`), not a static image. |
| MAP-D4 | Locations are stored as host-confirmed fields: `place_id` plus the pin, venue name and address the host confirmed or edited, treated as host content (§5.1). No 30-day refresh job. |
| MAP-D5 | Spending above Google's free caps is allowed for the prototype. A Google Cloud budget alert emails the owner at **$10 per month**. |
| MAP-D6 | No Google Cloud project exists. The owner creates the project and billing account when S10 starts; S10 lists the APIs to enable and the key restrictions. |

## 4. Desired outcome

Every activity has a precise, host-confirmed location. Every person who can see the activity can see where it is and open directions in one tap. Community pages can be browsed on a map. The invite page keeps its 3G budget.

## 5. Proposed solution and rationale

### 5.1 Data model [Proposal]

Replace `activities.location` with:

| Column | Type | Source | Notes |
| --- | --- | --- | --- |
| `place_id` | text, nullable | Google Places | Stored indefinitely (terms allow). Null when the host drops a pin with no place. |
| `venue_name` | text | Host | Prefilled from the selected place, editable. Host-authored content. |
| `address_text` | text | Host | Prefilled from the selected place, editable. Host-authored content. |
| `lat`, `lng` | `numeric(9,6)` | Host | The pin the host confirmed, after dragging or accepting. `CHECK` on valid ranges. |
| `meeting_point` | text, nullable, ≤ 140 chars | Host | For example "Meet at the blue gate by the jetty". |

**Why host-confirmed fields (MAP-D4):** the 30-day cache limit applies to Google's coordinates. The host confirms the pin and edits the text before publishing, and the stored values are the host's statement of where to meet, not a cache of Google data. This is the owner's accepted reading; it has not been checked with Google or legal counsel (risk in §11). If it is ever challenged, the fallback keeps only `place_id` permanently and refreshes coordinates from Place Details within 30 days by a scheduled job.

All five fields are locked once the activity has a booking, extending PRD Q2 (`meeting_point` included, since members can't be told of a change).

### 5.2 Surfaces [Proposal]

| Surface | Web | Flutter |
| --- | --- | --- |
| H2 Create and edit activity | Places Autocomplete (new) search, plus an interactive map with a draggable pin; venue name, address and meeting point fields | Not in Flutter (hosting is web-only, PRD W1) |
| B1 Activity page | Static map image; tap to load the interactive map; "Get directions" | Not in Flutter (M1 scope) |
| G1, G2 Invite pages | **Static map image only**, lazy-loaded below the fold, with "Get directions" | Interactive native map |
| G4 You're in, B4 Plan | Static map plus "Get directions" | Interactive native map |
| C1 Community page | List / Map toggle; Map uses the Maps JavaScript API with one marker per upcoming activity with spots, clustered | Not in Flutter (C1 is web-only) |

- **"Get directions"** opens a Google Maps URL (`https://www.google.com/maps/dir/?api=1&destination=…&destination_place_id=…`). This needs no API key and is not billed [Assumption: verify in S5]. On iOS, Flutter offers Apple Maps or Google Maps.
- **Address text is always shown** next to any map, so the map is never the only way to learn the location (accessibility, offline).
- **Static maps** are signed with a URL-signing secret on the server, and the signed URL is returned in the activity snapshot.

### 5.3 Performance [Proposal]

- The invite page loads no Maps JavaScript. It renders a static map `<img>` with fixed dimensions (no layout shift), `loading="lazy"` and below the fold, so the 1.5 s first-content budget and the 100 kB JS budget are unchanged.
- The activity page and community map load the Maps JavaScript API only on interaction or when the Map tab is chosen.

### 5.4 Offline (PRD M2) [Proposal]

The Flutter app's offline cache stores venue name, address, meeting point and coordinates. Offline, the map area shows the address and a "Map unavailable offline" placeholder instead of blank tiles. Directions still open in the device's maps app, which may have its own offline maps.

### 5.5 Keys and secrets [Proposal]

| Key | Used by | Restriction |
| --- | --- | --- |
| Browser key | Web: Maps JavaScript API, Places Autocomplete | HTTP referrer: the `cloudfront.net` hostname and `localhost` |
| Android key | Flutter: Maps SDK for Android | Package name + signing certificate SHA-1 |
| iOS key | Flutter: Maps SDK for iOS | Bundle ID |
| Server key + URL-signing secret | API: signing Static Maps URLs | API restriction to Static Maps; stored in the server's secret store, never in a client |

Each key is restricted to only the APIs it needs. A Google Cloud budget alert emails the owner at $10 per month (MAP-D5).

### 5.6 API and contracts [Proposal]

- `POST /activities` and `PATCH /activities/:id` accept `{ placeId?, venueName, addressText, lat, lng, meetingPoint? }`.
- The activity snapshot returns a `location` object with those fields, plus `staticMapUrl` and `directionsUrl`.
- `GET /communities/:slug` returns the coordinates of each listed activity for the map view.

## 6. Architectural considerations

- **Security:** keys are restricted per platform. The signing secret stays server-side. CSP adds Google's map and image domains (S5, S6).
- **Privacy:** loading Google Maps sends the viewer's IP address and the map location to Google. The privacy note must say so (SEC-M03). Coordinates are activity data, not personal data, but telemetry rules still apply: coordinates never become metric labels.
- **Cost:** a static map image is requested on each view of an invite, activity, success or Plan page. Free caps are per SKU per month (10,000 each). Over-cap spend is allowed, with a $10 monthly alert (MAP-D5).
- **Operations:** if Google is unreachable, every surface still shows the address and the directions link. Maps never block booking or claiming.
- **Accessibility:** the pin picker can be used by keyboard (search result selection sets the pin, and arrow keys nudge it). Map images have alt text with the venue name.

## 7. Components and files affected

**Documents** (after approval):
- PRD: amend A1, add A4–A7 (§8 below), extend Business rules (location lock) and Non-goals.
- MVP plan: §4.3 data model, §4.8 API, §4.10 performance, §5 stack (Google Maps Platform, `google_maps_flutter`), §8 risks, change log.
- S1 Foundations spec: `activities` columns (§5.1) and the server key and signing-secret configuration.
- UX: the complete UI design spec covers all map screens and states.
- `ROADMAP.md`: Phase 0 and core capabilities.

**Code** (in later delivery specs, not here): S1 migration; S5 picker, activity page and community map; S6 invite-page static map; S7 native map; S10 secrets and CSP.

## 8. Proposed PRD amendments (need owner approval)

| ID | Requirement | Priority |
| --- | --- | --- |
| A1 (amended) | Location becomes a place chosen with search and a confirmed map pin, plus an editable venue name and address. | P0 |
| A4 | Host picks the location with Google Places search and adjusts a draggable pin; can add an optional meeting-point note (≤ 140 characters). | P0 |
| A5 | Activity, invite, "You're in" and Plan screens show the location on a map with the address and a one-tap "Get directions". | P0 |
| A6 | Community pages offer a map of upcoming activities with spots left, beside the list. | P0 |
| A7 | Maps never block booking: if maps fail to load, the address and directions link still show. | P0 |

Business rule change: the location lock (Q2) covers pin, venue name, address and meeting point.

## 9. Implementation phases and tasks

1. Owner approves this spec and the PRD amendments; amend PRD, MVP plan and ROADMAP.
2. Amend S1 (schema and configuration) before it is approved.
3. Design every map screen and state in the complete UI design spec.
4. Implementation lands in S1, S5, S6, S7 and S10 under their own authorization.
5. Google Cloud project setup, keys and budget alert happen in S10 (needs owner action: a billing account).

## 10. Dependencies and prerequisites

- A Google Cloud project with billing enabled, created by the owner when S10 starts (MAP-D6). Local development before then can use the address and directions fallback (A7).
- Current Google Maps Platform terms and pricing, rechecked at implementation time.
- `google_maps_flutter` latest stable, pinned (checked in S7).

## 11. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Storing coordinates breaches the 30-day cache term | Host-confirmed fields (MAP-D4, accepted by the owner); fallback refresh job designed if challenged |
| Bills over the free cap during a load test or a viral link | k6 scenarios don't request map images; budget alert; static map lazy-loaded so bots and quick bounces don't fetch it |
| Invite page misses its 3G budget | No Maps JS on the invite page; static image lazy and sized; Lighthouse check in S6 |
| Native map adds weight and setup to the Flutter app | Map widget built only on screens that show it; keys per platform documented in S7 |
| Pin on the wrong spot | The host confirms the pin on a preview before publishing; lock after the first booking |
| Exact public location at a private home (MAP-D2) | Owner decision; hosts see a note in H2 that the pin is public |
| Google outage | A7 fallback: address and directions link always render |

## 12. Alternatives considered

- **OpenStreetMap / Mapbox:** cheaper or open, but the owner asked for Google Maps, and Google gives the best place search for the target regions.
- **Static map in Flutter:** lighter and offline-friendly, rejected by the owner (MAP-D3).
- **Approximate area until booking:** safer for private homes, rejected by the owner (MAP-D2).
- **Store Google's formatted address and coordinates as a cache:** simpler, but it would need refresh within 30 days.

## 13. Assumptions and open questions

- ~~**OQ-1:** Is storing host-confirmed coordinates and text outside the 30-day limit?~~ Resolved 2026-11-03: MAP-D4.
- ~~**OQ-2:** Is spending above the free cap acceptable, and at what monthly budget should the alert fire?~~ Resolved 2026-11-03: MAP-D5.
- ~~**OQ-3:** Does the Google Cloud project and billing account exist?~~ Resolved 2026-11-03: MAP-D6.
- [Assumption] Directions URLs need no key and are not billed.
- [Assumption] Native mobile map loads are billed or free at the rate shown on the current pricing page; verify in S7.

## 14. Estimated complexity

Medium: one schema change, one picker, a reusable map block on three clients, one community map view, and key management.

## 15. Related

- PRD: A1, Business rules (Q2, Q11), Non-goals, performance NFR.
- MVP plan §4.3, §4.8, §4.10, §4.11, §5.
- `spec/2026-11-03_10-34_complete-ui-design/`, `spec/2026-11-03_09-29_s1-foundations/`.

## 16. Change log

- 2026-11-03 10:34: created after the owner asked to rework Phase 0 with Google Maps. MAP-D1–D3 decided by the owner in the same session.
- 2026-11-03: OQ-1 to OQ-3 answered by the owner (MAP-D4 to MAP-D6): host-confirmed location fields, $10 monthly budget alert with overage allowed, owner creates the Google Cloud project at S10.
- 2026-11-03: **approved by the product owner**, with the PRD amendments (A1 amended, A4–A7, Q13). PRD, MVP plan and S1 spec updated to match. Code lands only in delivery specs under their own authorization.
