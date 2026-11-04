# Requirements: S6 Web invite and claim page

## Purpose and scope

The server-rendered web invite page at `/i/<code>` with link previews and the open beacon, the claim step and "You're in", every invite outcome screen, live spots on the page, the deep-link association files, and Static Maps URL signing in the API. Screen IDs and copy keys refer to `spec/2026-11-03_10-34_complete-ui-design/` and the UX spec copy deck; S4 IDs to `spec/2026-11-04_11-42_s4-invites-attribution/REQUIREMENTS.md`. Design: `PLANNING.md` in this directory.

## Goals and non-goals

- **Goals:** a guest goes from link to claimed in one flow without the app; the page meets the 3G budget; previews don't count as opens; every outcome has a next step; installed apps open from the same link.
- **Non-goals:** the Flutter screens (S7); the web app shell, components and clients (S5 Phase A); B4 Plan (S5); web vitals RUM and analytics events (S8); Playwright (S9); vouch holds (PRD X2).

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | `/i/<code>` is server-rendered from `GET /api/invites/:code`, fetched with the viewer's cookie, device ID, client IP and the origin header. A non-canonical code in the path redirects to the canonical upper-case form. | PRD M1; S4 §4.4, §4.7 |
| FR-002 | The page chooses its screen from the invite view as PLANNING §4.3 lists: G1 vouch (inviter lead and note), G2 public (community chip and "Shared by"), G5 sold out, G6 expired or started, G7 already claimed (own or other), G9 not found or rate-limited, the paused state, and the already-going, host and bookings-paused variants. | PRD Flows, Edge cases, Lifecycles; UX FR-004 |
| FR-003 | G1 and G2 show the activity photo, title, date and time in the activity's zone with the zone named, price with "pay the host on the day", host, avatar stack of who's going (`PublicPerson`), live spots-left, "Spots aren't held. Claim while they last.", and the location block. | PRD Flows (Zainab 2, Kofi 2), Scope challenge 4; UX-1 |
| FR-004 | Spots update live on the page by the S3 client rules, and the page moves between G1/G2 and G5 as spots reach zero or free up, without reload. | PRD A2, A3, Lifecycles |
| FR-005 | After first paint in a browser, the page sends one `POST /api/invites/:code/opens` with the device ID and `platform: 'web'`. Server rendering never sends it. | PRD Scope challenge 2, R9; S4 FR-006 |
| FR-006 | The page has Open Graph and Twitter card metadata: title naming the inviter and activity, description with date and spots, the activity photo, canonical URL. Invite pages are `noindex`. | MVP plan §4.7 |
| FR-007 | G3 claim: signed out, exactly two fields (display name, phone or email) with help text and the rail-specific disclosure; signed in, no fields, "Claiming as {Name}" with "Not you?". | PRD Flows (Zainab 3), Identity; UX FR-006 |
| FR-008 | A claim attempt uses one idempotency key, reused on retry and after a reload during the attempt. The button shows "Confirming…" until the API answers. | PRD Edge cases (server error), B2 |
| FR-009 | Claim responses map to screens: `201`/own `200` → G4; `sold_out` → G5; `invite_expired` → G6; `invite_paused` → paused; `already_claimed` → G7 other; `already_booked` → already going with the Plan link; `booking_removed` → removed copy with next steps; `forbidden` (host) → attendance link; `bookings_paused` → paused bookings; `rate_limited` → `claim.rateLimited`; `validation_failed` → field errors; other errors → retry state. | S4 FR-010; PRD Edge cases |
| FR-010 | G4 shows "You're in, {FirstName}.", the booking reference with `youreIn.ref`, the activity summary, members, the location block with "Get directions", "See the plan", and "Invite a friend" when the Plan allows it. | PRD Flows (Zainab 4–5), A5; UX-2 |
| FR-011 | G5 and G6 show next steps from `GET /api/activities/:id/next-steps`: "Tell {Inviter}" (share sheet or WhatsApp with a prefilled reply), the host's other dates, "More in {Community}", hiding empty blocks; G6 links to the inviter's profile. Opens on these screens are still recorded. | PRD Edge cases, Q9; UX FR-007 |
| FR-012 | G9 keeps a code field so the guest can fix a mistyped code; the rate-limited state says "Try again in an hour. Your invite still works." | PRD Edge cases (invalid code), R10 |
| FR-013 | Offline after load, Claim is disabled with "Reconnect to claim"; nothing is queued. | PRD Edge cases (offline), M2 |
| FR-014 (Maps FR-007) | The location block shows a lazy-loaded static map below the fold with fixed dimensions, the venue, address, meeting point and "Get directions"; invite routes load no Maps JavaScript. | PRD A5 |
| FR-015 (Maps FR-012) | If the static map is missing or fails, the address, meeting point and directions still show. | PRD A7 |
| FR-016 (Maps FR-015) | The API signs `staticMapUrl` with the server key and URL-signing secret when both are configured, and returns null otherwise. | Maps FR-015; S3 Q1 |
| FR-017 | `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` are served as JSON with no redirect, associating `/i/*` with the app identifiers set in configuration; with none set they return `404`. | PRD M1; MVP plan §4.7 |
| FR-018 | Invalid codes respond `404` and rate-limited lookups `429`; every valid invite state responds `200`. | PLANNING §12 Q1 (decided 2026-11-04) |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | First content < 1.5 s on a mid-range Android profile over 3G for G1 and G2 (Lighthouse mobile with throttling, on the deployed stack). | PRD NFR Performance; MVP plan §4.10; Maps NFR-001 |
| ~~NFR-002~~ | ~~All JavaScript loaded on `/i/[code]` totals ≤ 100 kB gzipped.~~ Amended 2026-11-04 by the owner: **≤ 200 kB gzipped**, of which ~157 kB is the React and Next.js runtime every App Router page loads (measured at T9). No Zod or other contract schemas in browser bundles. NFR-001 (first content < 1.5 s on 3G) is the governing target. | MVP plan §4.10; PLANNING change log |
| NFR-003 | The hero image is ≤ ~60 kB at mobile width. | MVP plan §4.10 |
| NFR-004 | No layout shift from the photo or map (fixed dimensions). | Maps NFR-002 |
| NFR-005 | WCAG 2.1 AA; touch targets ≥ 44 px; spots changes announced politely at most once per 5 s; focus moves to the outcome heading after a claim. | UX NFR-001–004; PRD Accessibility |
| NFR-006 | No horizontal overflow at 360, 390, 768, 1024 and 1280 px; phone-first screens in a centred 480 px column on wide screens. | UI design FR-013, FR-014 |
| NFR-007 | Lint, typecheck, format and tests pass in CI. | CLAUDE.md |

## Use cases

- **Zainab on the bus:** taps Tunde's WhatsApp link → page in under 1.5 s → Claim → name and number → "You're in, Zainab." → screenshots `VLO-48213`.
- **Kofi from a thread:** public link → sees "+6 going" and spots counting down → claims.
- **Too late:** the last spot goes while Zainab reads → the page turns into "This one filled up before you got here." with "Tell Tunde".
- **Mistyped link:** `/i/K7PQ2` → G9 with the code in a field to fix.
- **App installed:** the same link opens the Flutter app (S7).

## Acceptance criteria

- **AC-001:** UI design flows 1 and 2 (guest, vouch and public rails, including sold out, expired and offline) complete on web phone against the deployed stack.
- **AC-002:** a `curl` with a WhatsApp user agent gets the OG tags and records no open; a browser visit records exactly one open per device.
- **AC-003:** Lighthouse on the deployed G1 meets NFR-001 and NFR-002, and the page requests no Maps JavaScript (Maps AC-004).
- **AC-004:** with two browsers, a claim in one moves the other from G1 to G5 live when it took the last spot.
- **AC-005:** with S7's identifiers configured, Android verifies the App Link. iOS Universal Links are out of scope (no Apple Developer account, decided 2026-11-04); with `APPLE_APP_IDS` unset the AASA route returns `404`.
- **AC-006:** with the Google secret configured, invite, B1 and B4 pages show a signed static map; without it, the address block alone.

## Business rules and edge cases

PRD Edge cases and Lifecycles are normative: invites don't hold spots; sold out isn't an invite state; a vouch is single-use, and a guest's own claim shows their booking; invites expire at the start time; invalid codes are rate-limited per device; offline claims are never queued; the wrong recipient's claim succeeds (code is the credential); a host can't claim on their own activity; a removed person can't rebook.

## Error handling and failure behavior

- API unreachable during SSR → X4 server error with a reference and a retry link.
- Claim network failure → retry state with the same key (FR-008).
- Socket failure → stale badge and polling (S5 client).
- Static map failure → address block (FR-015).
- Missing association config → `404` on the files; the web page still works.

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | Before a claim the page shows people only as `PublicPerson`; never the invitee's name or contact; the vouch note only on that vouch's page. | PRD Q12, D5; S4 §4.4 |
| SEC-002 | Contact details go only in the claim POST body, never in URLs, storage or telemetry. | PRD Privacy |
| SEC-003 | Invite routes load no third-party scripts, are `noindex`, and send no referrer with the static map request. | PLANNING §5 |
| SEC-004 | The Static Maps signing secret and server key stay in the API's configuration (Secrets Manager in production); neither reaches a client except as the signed URL's `key` and `signature`. | Maps §5.5 |
| SEC-005 | SSR forwards the viewer's device ID and IP, so rate limits apply to the viewer, not to the web server. | S4 §4.7 |
| SEC-006 | The claim disclosure tells the guest the host sees their name and how they joined. | PRD D5; UX FR-006 |

## Performance and reliability

NFR-001–NFR-004. Invite pages are not cached at CloudFront. The page works with JavaScript disabled up to showing the invite and the outcome [Proposal: claim needs JS].

## Compatibility constraints

Mobile Safari, Android Chrome, and the WhatsApp, Instagram and Facebook in-app browsers [Assumption: latest versions]; desktop evergreen browsers.

## Data and migration

None. API config gains two optional values; web config gains three.

## Dependencies and integrations

S5 Phase A; S4; Google Maps Static API (owner's key and secret); S7 identifiers for association files; Secrets Manager (CDK change).

## Explicitly excluded functionality

Flutter screens; RUM and analytics events; Playwright; interactive maps on invite routes; any paid domain or link shortener.
