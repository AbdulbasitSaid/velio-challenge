# Requirements: S5 Web app: foundation, host and booker

## Purpose and scope

The Next.js web app's shared foundation (tokens, fonts, components, API and realtime clients, session pages, app shell, production wiring), photo upload, Google Maps on web, and every web screen except the invite and claim pages (S6): C1, B1–B4, B6, P1, H1–H3, X1, X3, X4. Parent IDs refer to `spec/2026-11-03_07-42_group-bookings-mvp-plan/REQUIREMENTS.md`; screen IDs and copy keys to `spec/2026-11-03_10-34_complete-ui-design/` and the UX spec copy deck. Design: `PLANNING.md` in this directory.

## Goals and non-goals

- **Goals:** every host and booker P0 flow works end to end in a browser against the deployed stack; the screens match the approved design in every listed state; spots are always live and never decided by the client; S6 and S7 can reuse the foundation.
- **Non-goals:** the invite and claim pages and deep-link files (S6); Static Maps URL signing (S6); the Flutter app (S7); admin metrics page A1, holdout gating, web-vitals RUM and client analytics events (S8); Playwright suites, full accessibility audit and load tests (S9); waitlist, cancellation, notifications, payments (PRD Next, Non-goals); dark theme, localisation, marketing pages (UI design non-goals).

## Functional requirements

### Foundation

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | `packages/design-tokens` holds the approved `tokens.json` as the only source and generates CSS variables, a Tailwind theme and a Dart tokens file; generated files are committed. | UX FR-008; UI design NFR-004 |
| FR-002 | The avatar colour is chosen by one specified hash of `avatarSeed` over the five avatar colour tokens, with shared test fixtures that S7 also passes. | MVP plan §4.8 |
| FR-003 | `apps/web` is a Next.js App Router app in the Bun workspace, run on Node, importing only `@velio/contracts` and `@velio/design-tokens` from the repository. | MVP plan §5, §6 |
| FR-004 | Fonts are self-hosted, subset and `font-display: swap`: DM Sans for body text and Sora for display, both SIL OFL (PLANNING §12 Q1 and §4.3, decided 2026-11-04). | MVP plan §5; design-system README |
| FR-005 | Every component in the approved design system is available as a React component with the props its README documents. | UI design FR-001 |
| FR-006 | A web device ID is kept in a first-party cookie and sent as `X-Device-Id` on API calls from the browser and from server rendering. | S4 §4.5, §4.7 |
| FR-007 | Server-rendered pages call the API on the internal network, forwarding the viewer's cookie, device ID, client IP and `traceparent`, and sending `X-Origin-Verify` in production. | S4 §4.4, §4.7; S10 |
| FR-008 | API errors are mapped to the typed error codes, and each code shown to a user has its copy-deck message; no raw error reaches the screen. | PRD Edge cases ("never a raw error") |
| FR-009 | The realtime client follows the six contract rules: subscribe before fetching the snapshot; ignore `spots` with `version ≤` the shown version; poll the snapshot every 10 s while disconnected and show the stale state; refetch on `resync`; refetch the Plan on `plan` and attendance on `attendance`; send `rendered` after painting a version. | `packages/contracts/src/realtime.ts`; PRD A2, R3; parent NFR-006 |
| FR-010 | X1 sign-in creates a session from name and phone or email and returns to the requested page; pages that need a session redirect signed-out visitors to X1. Sign-out ends the session. | MVP plan §4.6; UI design X1; PRD Q14 |
| FR-011 | X3 app shell: web header with a Host / Booker role toggle that changes the interface only; host navigation appears in Host mode; the choice persists across visits. | PRD W1, Business rules (Identity) |
| FR-012 | X4: unknown routes show the not-found screen and server errors the error screen with a reference ID. | UI design X4 |

### Photos and Maps

| ID | Requirement | Source |
| --- | --- | --- |
| FR-013 | `POST /api/uploads/photos` (signed in) returns a presigned S3 POST limited to 2 MB and image types WebP, JPEG and AVIF, under a prefix for the caller, valid for 10 minutes. | PRD A1, Q5; PLANNING §4.9 [Proposal: limits] |
| FR-014 | `ActivityCreate` and `ActivityPatch` accept `photoKey`; the API rejects a key that doesn't exist or isn't under the caller's prefix (`400 validation_failed`). Photo stays editable after bookings. | PRD A1, Q2 |
| FR-015 | `PublicActivity.photoUrl` and `ActivityCard.photoUrl` return the photo's URL (CloudFront `/photos/…` in production, MinIO locally) when a photo is set. | S4 §4.12 ("null until S5") |
| FR-016 | Before upload the browser produces WebP variants at 1280 px and 640 px wide; if it can't, it uploads the original when it meets FR-013's limits. | PLANNING §4.9, §12 Q3; MVP plan §4.10 |
| FR-017 (Maps FR-001, FR-002, FR-003, FR-004) | H2's location picker: Places search prefills venue name, address and a draggable pin; a pin can be dropped without a place; an optional meeting point ≤ 140 characters; publishing needs a pin, venue name and address; the "pin is public" note shows. | PRD A4, Q13 |
| FR-018 (Maps FR-006) | B1 shows the static map (when the snapshot provides one), venue, address, meeting point and "Get directions"; tapping the map loads the interactive map. | PRD A5 |
| FR-019 (Maps FR-008) | B4 shows the map, address, meeting point and "Get directions". | PRD A5 |
| FR-020 (Maps FR-010) | C1 offers List and Map views; the map shows one marker per upcoming activity with spots, clusters nearby markers and opens a summary card linking to the activity. | PRD A6 |
| FR-021 (Maps FR-012) | When maps fail, the key is missing or `staticMapUrl` is null, the address, meeting point and directions link still show and booking is unaffected; C1 offers "Show the list instead"; H2 offers venue, address and coordinates fields. | PRD A7 |

### Booker screens

| ID | Requirement | Source |
| --- | --- | --- |
| FR-022 | C1 community page lists upcoming activities with live spots and the community header, in list and map views, with the empty and map-failed states. | PRD Q11, A6; UI design C1 |
| FR-023 | B1 activity page shows photo, host (`PublicPerson`), date and time in the activity's zone with the zone named, price with "pay the host on the day", avatar stack, live spots-left and the location block. | PRD A2, Flows (Booker 1), Business rules; UX-1 |
| FR-024 | Booking from B1 shows "Booking…" at once, sends one idempotency key per attempt and reuses it on retry, and shows success only after the API confirms. | PRD B1, B2, Flows (Booker 2) |
| FR-025 | B1 shows each designed state: available, last spots, sold out (on every client the moment spots reach zero), sold out mid-checkout with the host's other dates and "More in [community]", already booked with a link to the Plan, activity started, bookings paused, server error with "Try again" (B5), and the host's own activity with a link to attendance instead of booking. | PRD A3, B1, Edge cases, Business rules ("A host cannot book their own activity") |
| FR-026 | A successful booking leads to B2: "You're going to …" with the invite step first (Invite a friend, Share link), shown once per booking and dismissable. | PRD Flows (Booker 3–4), R6 |
| FR-027 | B3 vouch: name (required), phone or email (optional), note (optional, ≤ 280), the no-hold line with the live count; on creation, send through WhatsApp, text message, the Web Share API where available, or copy link, with the prefilled `vouch.message`. | PRD I1, I3, Notifications; S4 FR-001 |
| FR-028 | B3b public link: shows the caller's link with copy and share, and the paused state with resume for its creator. | PRD I2, R7; S4 FR-002, FR-019 |
| FR-029 | B4 Plan shows members with full names, how each joined and who invited them, invite statuses (created, opened, claimed, expired) updating live, the viewer's booking reference, the location block, the only-me state and the removed-by-host state with next steps. Invite tools show only when `viewer.canInvite` is true. | PRD L1, Host removal, Q12; S4 FR-020 |
| FR-030 | B6 My plans lists upcoming and past Plans with activity, date, booking reference, members and live spots; removed, empty and loading states. | PRD L2, Q14 |
| FR-031 | P1 profile shows the public name, avatar, "On Velio since", upcoming hosted activities and the privacy line; never bookings or Plans. | PRD Q10 |

### Host screens

| ID | Requirement | Source |
| --- | --- | --- |
| FR-032 | H3 lists the host's activities, upcoming and past, with spots and booked counts, sold-out state, a "Mark attendance" status after start, and the empty state. | UI design H3; PRD W1 |
| FR-033 | H2 create: community, title, description, photo, date, time, IANA time zone, location (FR-017), price and currency, capacity; field validation with copy-deck errors and a summary; preview card; lock warning; publish leads to the published state with a link to attendance. | PRD A1, Flows (Host 1–3); UI design H2 |
| FR-034 | H2 edit: after the first booking, date, time, zone and location are shown locked with the copy-deck explanation; title, description, photo and capacity stay editable; capacity can't go below the booked count; API rejections (`location_locked`, `capacity_below_bookings`) show inline. | PRD Q2, Business rules (Capacity) |
| FR-035 | H1 attendance shows spots left and each booking live as it lands, with full name, booking time, source ("Direct", "via {Name}", "Public link"), booking reference and the groups summary; never contact details. | PRD H1, D5, Flows (Host 4–5); UX-3 |
| FR-036 | H1 removal asks for confirmation with the copy that the spot goes to whoever books next, then removes; the list and spots update. | PRD H1, D3, Host removal |
| FR-037 | H1 after start offers attended or no-show per attendee; a later mark replaces the shown mark; removed bookings can't be marked. | PRD H2; S4 FR-025 |
| FR-038 | H1 on phone offers guest search by name or booking reference. | UI design H1 (approved addition) |

### Production

| ID | Requirement | Source |
| --- | --- | --- |
| FR-039 | The web app runs as a container in the production Compose file, built and deployed by the existing workflows, behind CloudFront's default behavior, with `/_next/static/*` cached. | MVP plan §4.11; S10 §4 |
| FR-040 | In production the web container rejects requests without the correct `X-Origin-Verify`, except its health route. | MVP plan §4.11 (origin lockdown) |
| FR-041 | The photos bucket accepts presigned POSTs from the distribution origin, and photos are served through `/photos/*`. | S10 §4; PRD Q5 |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | Every page renders without horizontal overflow at 360, 390, 768, 1024 and 1280 px in every state; layouts follow UI-D5. | UI design FR-013, FR-014, §5.6 |
| NFR-002 | WCAG 2.1 AA contrast; touch targets ≥ 44 × 44 px; visible focus; real buttons, links and inputs; reduced-motion respected. | UX NFR-001–004 |
| NFR-003 | Spots-left changes are announced through a polite live region at most once per 5 s. | PRD Accessibility; UX NFR-003 |
| NFR-004 | The Maps JavaScript API loads only after interaction on B1, when Map is chosen on C1, or on H2. | Maps NFR-003 |
| NFR-005 | Latest stable release of every new dependency and image, pinned exactly. | CLAUDE.md |
| NFR-006 | Web telemetry uses route templates only and carries no personal data, codes or tokens. | CLAUDE.md; parent SEC-011 |
| NFR-007 | `bun run lint`, `typecheck`, `format:check` and the web tests pass in CI. | CLAUDE.md §2.6 |
| NFR-008 | The web container has a memory limit and the instance keeps headroom with both Node and Bun processes running. | PLANNING §9 |

## Use cases

- **Amara publishes Sunset Kayaking:** signs in, switches to Host, creates with a photo and a searched place, publishes, opens attendance.
- **Tunde books and invites:** opens Explore Kenya on the map, opens the activity, books, vouches for Zainab on WhatsApp, shares the public link, watches "Opened" then "Claimed".
- **Last-spot race:** Tunde taps Book as the last spot goes → "Someone just took the last spot. We didn't book or charge you." with next steps.
- **Morning of:** Amara searches "VLO-48213" on her phone at the jetty; after start she marks attendance.

## Acceptance criteria

- **AC-001:** the host flow (UI design flow 5) works end to end on the deployed stack.
- **AC-002:** the booker flow (UI design flow 4), including sold out mid-checkout, works end to end on the deployed stack.
- **AC-003:** with B1 open in two browsers, a booking in one updates spots in the other without refresh, and the sold-out state appears in both when spots reach zero.
- **AC-004:** a Plan open in one browser shows a vouch move from created to opened to claimed live as another browser opens and claims it (with S6's page, or the API directly before S6 lands).
- **AC-005:** with the socket blocked, the page shows "Reconnecting", polls, and recovers to live without a reload.
- **AC-006:** every state listed for B1, B4, B6, H1, H2, H3, C1, P1, X1 and X4 in UI design §5.3 is reachable and matches the canvas.
- **AC-007:** no horizontal overflow at the five widths (NFR-001).
- **AC-008:** a removed attendee's spot frees immediately on every open client and the removed person's Plan shows the removed state.
- **AC-009:** a photo uploaded in H2 shows on B1, C1 cards and My plans, from `/photos/` in production.
- **AC-010:** with the Maps key absent, every map surface shows its fallback and booking and publishing still work.

## Business rules and edge cases

The PRD's Business rules and Edge cases tables are normative. In particular: names by audience (Q12); times in the activity's zone with the zone named; prices in the activity's currency with "pay the host on the day" (UX-1); booking reference shown in the Plan and to the host (UX-2); a host can't book their own activity; removed people can't rebook the same activity; date, time and location lock after the first booking; capacity never below bookings; bookings close at start; invites don't hold spots (copy `vouch.noHold`).

## Error handling and failure behavior

- Every typed booking error maps to its designed state (FR-025); `internal` and network errors show the retry state and keep the idempotency key.
- Lost socket → stale badge, polling, reconnect (FR-009); spots never shown as live while stale.
- Upload failure → field error with the copy deck's message; the form keeps its other values.
- Maps failure → FR-021.
- SSR fetch failure → X4 with a reference, except public pages that can render from a cached response [Proposal: none cached in MVP].

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | Public pages (C1, B1, P1) render people only as `PublicPerson`; full names only on B4 (members) and host pages (host). | PRD Q12, D5 |
| SEC-002 | Contact details never appear in URLs, query strings, telemetry or client storage; the vouch contact is sent only in the request body. | PRD Privacy; S4 |
| SEC-003 | The session cookie stays httpOnly and first-party; the device cookie holds only a random ID. | MVP plan §4.6 |
| SEC-004 | A Content Security Policy limits scripts, images and connections to the app, the photos origin and Google Maps domains; `frame-ancestors 'none'`. | Maps §6 |
| SEC-005 | The Maps browser key is restricted to the distribution hostname and `localhost` and to the Maps JavaScript and Places APIs; no server key or signing secret reaches the browser. | Maps §5.5 |
| SEC-006 | Presigned uploads are limited in size, type, prefix and lifetime (FR-013), and only the caller's own keys can be attached (FR-014). | PRD Q5 |
| SEC-007 | Where maps load, the privacy note says loading a map shares the viewer's IP address with Google. | PRD Privacy; Maps SEC-M03 |
| SEC-008 | Host pages are reached only for the user's own activities; the API's `403` shows the not-found state. | PRD Identity |

## Performance and reliability

- B1, C1 and P1 render on the server; maps and the interactive map load lazily (NFR-004).
- The invite-page budget is S6's; S5 keeps the shared layout, fonts and CSS small enough for it [Proposal: S6 measures the shared bundle].
- A web container restart doesn't affect the API or bookings.

## Compatibility constraints

- Evergreen browsers (latest two versions of Chrome, Safari, Firefox, Edge; iOS Safari and Android Chrome) [Assumption: no older targets were set].
- Runs on Node (Next.js's supported runtime); dependencies managed by Bun.
- ARM64 image for `t4g.small`.

## Data and migration

No schema migration: `activities.photo_key` exists. Contracts gain `photoKey` and `PhotoUploadResponse`; `openapi.json` is regenerated. MinIO gets a `photos` bucket locally.

## Dependencies and integrations

S1–S4, S10; Google Maps Platform (owner's project and browser key); S3 (photos bucket); GHCR; CloudFront (CDK change).

## Explicitly excluded functionality

Invite and claim pages, deep-link files, Static Maps signing (S6); Flutter (S7); A1 admin, holdout, RUM, analytics events (S8); Playwright, Lighthouse for non-invite pages, load tests (S9); waitlist, cancellation, notifications, payments; drafts or duplicating activities (removed from the design because the PRD has neither).
