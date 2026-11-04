# Planning: S5 Web app: foundation, host and booker

- **Spec ID:** 2026-11-04_12-50_s5-web-host-booker
- **Created:** 2026-11-04 12:50 (local)
- **Status:** Implemented
- **Phase:** 4, Clients (`ROADMAP.md`), alongside S6 and S7
- **Parent:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (approved), delivery step S5
- **Builds on:** S1 (contracts, sessions), S2 (activities, bookings), S3 (snapshot, realtime protocol), S4 (invites and read APIs), S10 (AWS app stack)
- **Design:** `spec/2026-11-03_10-34_complete-ui-design/` (approved; source in `prototype/`), `spec/2026-11-03_09-09_ux-design/` (tokens, copy deck, UX-1–UX-5), `spec/2026-11-03_10-34_google-maps-locations/` (approved)
- **Siblings:** `spec/2026-11-04_12-50_s6-web-invite-claim/` (builds on this spec's Phase A), `spec/2026-11-04_12-50_s7-flutter-app/` (uses `packages/design-tokens`)

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The API serves every P0 flow, but no person can use it: there is no web app. Amara can't publish an activity or watch attendance, and Tunde can't book, invite or find his Plans (PRD W1, A1–A7, B1–B3, L1, L2, H1, H2). The production CloudFront default behavior still points at the API and returns `not_found`, activity photos can't be uploaded (`photoUrl` is always null), and the Google Maps keys don't exist. S6 (invite page) needs the same Next.js app, design components, API client and realtime client, so they should be built once.

## 2. Context and current behavior

- [Verified, `package.json`] Bun workspace with `apps/api`, `packages/*`, `infra/aws`. No `apps/web`, no `packages/design-tokens`.
- [Verified, `apps/api/src/modules/*/routes.ts`] Endpoints exist for sessions (`POST /sessions`, `GET/DELETE /sessions/current`, `GET /me`), activities (create, patch, snapshot, next-steps), bookings, host removal, attendance and marks, host activity list, Plans, My plans, invites (create, view, opens, claims, pause), communities and profiles, and `GET /api/ws`.
- [Verified, `packages/contracts/src/activities.ts`] `ActivityCreate` has no photo field; `PublicActivity.photoUrl` and `ActivityCard.photoUrl` are "null until photo upload exists (S5)". `PublicLocation.staticMapUrl` is null until signing exists (S6).
- [Verified, `packages/contracts/src/realtime.ts`] The six client rules for realtime (subscribe before snapshot, version gate, 10 s poll while disconnected, resync, `plan`/`attendance` refetch hints, `rendered` acks) are normative for S5–S7.
- [Verified, S10 PLANNING §4] CloudFront: `/api/*` → instance port 3001; `/photos/*` → photos bucket via OAC (bucket empty "until S5"); default behavior → port 3001 "until S5 adds the web origin; S5 changes only this behavior". Deep-link files and Google Maps keys are deferred to S5/S6.
- [Verified, S3 PLANNING §12 Q1] Static Maps signing moves to S6, or S5 if S5 starts first.
- [Verified, MVP plan §5] Next.js App Router + Tailwind with Velio tokens, managed by Bun, run on Node. Vitest for web units; Playwright and Lighthouse are S9 (Lighthouse for the invite page is S6).
- [Verified, MVP plan §6] `apps/*` never import each other; shared code goes through `packages/*`.
- [Verified, complete UI design §5.6] Responsive rules UI-D5: fluid 360 → 1440+, `content-max` 1120px, columns stack below ~900px, header nav hides below 720px; phone-first screens in a centred 480px column.
- [Verified, design-system README] Canvas fonts are stand-ins (Sora display, DM Sans body); production body is Satoshi; display is Nohemi if licensed, otherwise a free face chosen in S5.
- [Verified, `infra/docker-compose.yml`] MinIO (Chainguard image, pinned) runs locally as the S3 stand-in.
- [Verified, local toolchain 2026-11-04] Node 26.11.1 and Bun 1.4.4 installed.

## 3. Desired outcome

A responsive Next.js web app, deployed behind the existing CloudFront distribution, in which:

- Amara signs in, creates an activity with a photo and a Google Maps location, publishes it, sees her list, watches attendance live, removes an attendee and marks attendance after start.
- Tunde browses a community (list and map), opens an activity with live spots and a map, books, lands on the invite prompt, creates a vouch or public link and shares it, follows invite status live in his Plan, and finds every Plan again in My plans.
- Every booking edge case in the PRD ends in its designed state.
- S6 and S7 reuse the tokens, and S6 reuses the app shell, components, API client and realtime client.

## 4. Proposed solution

### 4.1 Phases and ownership with S6 [Proposal, §12 Q4]

| Phase | Contents | Unblocks |
| --- | --- | --- |
| **A. Web foundation** | `apps/web` scaffold, `packages/design-tokens`, fonts, design components, API client, session handling, realtime client, app shell, X1 sign-in, X4 errors, production wiring (image, Compose, CloudFront default → web, `/_next/static/*` cached), CSP | S6 starts here |
| **B. Photos and Maps API** | Photo upload API and contracts; Google Maps keys and secrets wiring (shared with S6's static-map signing) | H2, B1, C1 |
| **C. Booker** | C1 community (list + map), B1 activity page, B2 booked + invite prompt, B3 vouch, B3b public link, B4 Plan, B6 My plans, P1 profile | |
| **D. Host** | H3 activity list, H2 create and edit with the location picker, H1 attendance with removal and marks, role toggle | |

S6 owns `/i/[code]` and every G-screen; S5 owns everything else in the web app. G4 "You're in" links to B4 (S5).

### 4.2 Workspace layout [Proposal]

```text
apps/web/                         # Next.js App Router, run on Node, deps managed by Bun
  app/
    layout.tsx                    # fonts, tokens CSS, app shell
    (app)/communities/[slug]/     # C1
    (app)/activities/[id]/        # B1 (+ booked state = B2)
    (app)/plans/[id]/             # B4 (+ invite step: B3, B3b as dialogs/sheets)
    (app)/me/plans/               # B6
    (app)/users/[id]/             # P1
    (app)/host/activities/        # H3
    (app)/host/activities/new/    # H2 create
    (app)/host/activities/[id]/edit/        # H2 edit
    (app)/host/activities/[id]/attendance/  # H1
    signin/                       # X1
    i/[code]/                     # S6
    not-found.tsx, error.tsx      # X4
    page.tsx                      # home: redirect to the first community (no landing page in the design)
  components/                     # ported design-system components (§4.4)
  lib/api/                        # typed fetch client (§4.5)
  lib/realtime/                   # socket client implementing the six rules (§4.7)
  lib/format/                     # money, time-in-zone, short names, avatar colour
  test/                           # Vitest + Testing Library
packages/design-tokens/
  tokens.json                     # copied from the approved design system, the one source
  build.ts                        # → css/tokens.css (CSS variables + Tailwind theme), dart/velio_tokens.dart
```

- `packages/design-tokens` generates CSS variables plus a Tailwind 4 `@theme` block for web, and a Dart file for S7 (UX FR-008). Generated files are committed so Flutter doesn't need Bun [Proposal].
- `apps/web` imports `@velio/contracts` for types and Zod schemas, and `@velio/design-tokens`. It never imports `apps/api`.

### 4.3 Fonts [Decided 2026-11-04, §12 Q1]

- Body: **DM Sans** (SIL OFL), as on the approved canvas [Decided by the owner, 2026-11-04]. Satoshi was dropped: its ITF Free Font License forbids redistribution through a repository or public server and forbids subsetting or format conversion [Verified, FFL text downloaded from Fontshare at T3], and this repository is public.
- Display: Nohemi has no licence available (MVP plan §5). **Sora** (SIL OFL), which the approved canvas already uses, so the shipped app matches what the owner approved [Decided by the owner, 2026-11-04].
- `next/font/local`, Latin subset, `font-display: swap`, preloaded. The same files go to S7's app bundle.

### 4.4 Components [Proposal]

Port the design system's components (`prototype/design-system/components/*`, 29 components with READMEs and `index.d.ts`) to React Server/Client Components styled with Tailwind on the tokens. The ported set keeps the props documented in each README so screens match the canvas. Map components are client components that load the Maps JavaScript API only on interaction (Maps NFR-003).

Rules carried from the design:

- `SpotsBadge` states: normal, just changed (flash; fade under `prefers-reduced-motion`), last 2, sold out, stale (UX FR-003, NFR-003).
- Spots changes are announced through one polite live region, at most once per 5 s (UX NFR-003; PRD Accessibility).
- `Avatar` colour from a hash of `avatarSeed` over the five-colour token palette (MVP plan §4.8). The hash function is specified in `packages/design-tokens` so Flutter matches (S7) [Verified at T2: the approved prototype uses djb2 over UTF-16 code units, unsigned 32-bit, mod 5 (`prototype/design-system/components/bundle.js` `avatarIndex`); production keeps it so colours match the canvas, replacing the FNV-1a proposal].
- Touch targets ≥ 44 px, visible focus ring in `forest`, real buttons and links (UX NFR-002, NFR-004).

### 4.5 API access [Proposal]

- **Browser → API:** same origin, `/api/*`. In production CloudFront routes it; locally Next.js `rewrites` proxy `/api/*` (and the socket) to `http://localhost:3001`. Session cookie stays first-party (MVP plan §4.11).
- **Server components → API:** `API_INTERNAL_URL` (`http://api:3001` on the Compose network in production, `http://localhost:3001` locally). The server forwards the viewer's `Cookie`, `X-Device-Id`, `X-Forwarded-For` and `traceparent`, and adds `X-Origin-Verify` so the API's origin check passes [Verified, `apps/api/src/app.ts`: the API enforces the header on every request in production].
- **Client:** a thin `apiFetch<T>(route, init)` that parses responses with the contract's Zod schema in development and tests and trusts the type in production builds (bundle size), and maps the error envelope to the typed error codes in `@velio/contracts/errors`. No generated client: the contracts package already exports every request and response schema.
- **Idempotency:** each booking attempt creates one `Idempotency-Key` (UUID v4) when the button is first pressed and reuses it for every retry of that attempt (PRD Edge cases: server error; B5 copy `booking.retry`).
- **Device ID:** a random ID in a first-party cookie `velio_device` (1 year, `SameSite=Lax`, not httpOnly so the client can send it as `X-Device-Id`), set by middleware on first visit [Proposal; shared with S6, which needs it for opens and rate limits].

### 4.6 Session and identity [Proposal]

- X1 "Continue to Velio": name + phone or email → `POST /api/sessions`; the API sets the httpOnly cookie. `GET /api/me` drives the header.
- Pages that need a session (B4, B6, H1–H3, the booking action on B1) redirect to `/signin?next=…` when signed out. Public pages (C1, B1 view, P1) render signed out.
- Sign out: `DELETE /api/sessions/current`.
- SEC-008 (no verification) is unchanged; the X1 copy already says "No password".

### 4.7 Realtime client [Proposal]

One module used by every live screen (and by S6):

1. Open `wss://<host>/api/ws?platform=web` (`resume=1` on reconnect). Send `subscribe` for the screen's topics, then fetch the REST snapshot, then apply events (contract rule 1).
2. Keep the highest `version` per activity; drop events with `version ≤` it (rule 2).
3. While disconnected: show the `LivePill` "Reconnecting" state, mark the badge stale, poll the snapshot every 10 s, reconnect with backoff (1 s doubling to 30 s, with jitter) (rule 3; PRD Edge cases: live connection drops).
4. `resync` → refetch all snapshots on screen; `plan` → refetch the Plan; `attendance` → refetch the attendance list (rules 4, 5).
5. After a `spots` version paints (`requestAnimationFrame` after the state update), send `rendered` (rule 6).
6. Pause the socket when the tab is hidden for more than 60 s and resume on visibility (saves sockets; resume follows rule 1) [Proposal].

### 4.8 Screens

| Screen | Route | Data | Key behavior | PRD |
| --- | --- | --- | --- | --- |
| X1 Sign in | `/signin` | `POST /sessions` | Empty, filled, invalid contact, submitting, server error; `next` redirect | Non-goals; Q14 |
| X3 App shell | layout | `GET /me` | Header with Host / Booker toggle (W1: switches the interface, not permissions; remembered in a cookie), nav hides below 720px, toasts | W1 |
| X4 Errors | `not-found`, `error` | — | 404 and 500 with request reference | Edge cases |
| C1 Community | `/communities/[slug]` | `GET /communities/:slug` | List / Map toggle; map loads Maps JS only when Map is chosen; markers only for activities with spots, clustered (`@googlemaps/markerclusterer`); selected marker shows a summary card; map failure → "Show the list instead"; empty state; live spots on visible cards | A6, Q11 |
| B1 Activity | `/activities/[id]` | snapshot (SSR) + socket | Live `SpotsBadge`; static map, tap loads the interactive map; address, meeting point and "Get directions" always shown (A7); states: available, last spots, sold out, booking (optimistic), sold out mid-checkout (with next steps from `GET /activities/:id/next-steps`), already booked (link to Plan), started, paused, server error with retry (B5); host viewing own activity sees a link to attendance instead of Book | A2, A3, A5, B1, B2, Edge cases |
| B2 Booked + invite prompt | `/activities/[id]` after booking → `/plans/[id]?welcome=1` | booking response | "You're going to …", invite step first: Invite a friend / Share link, dismissable once and not repeated (R6) | B3, Flows |
| B3 Vouch | dialog on B4 (bottom sheet on phone) | `POST /plans/:id/invites` | Empty, filled, validation, creating, created → send via WhatsApp (`https://wa.me/?text=`), SMS (`sms:?&body=`), copy; Web Share API where available; `vouch.noHold` with live count | I1, I3, Notifications |
| B3b Public link | dialog on B4 | same, `rail: public` | Created, copied, paused (owner may resume: `DELETE /invites/:code/pause`) | I2, R7 |
| B4 Plan | `/plans/[id]` | `GET /plans/:id` + `plan:<id>` and `activity:<id>` topics | Members with sources and full names, invite statuses live, viewer's ref, location block, removed-by-host state with next steps, only-me state; invite tools only when `viewer.canInvite` (S8's holdout sets it) | L1, A5, Host removal |
| B6 My plans | `/me/plans` | `GET /me/plans` | Upcoming / past, Plan cards with ref, members and live spots, removed state, empty, loading | L2, Q14 |
| P1 Profile | `/users/[id]` | `GET /users/:id/profile` | Host with upcoming activities; guest with none; privacy line | Q10 |
| H3 Host list | `/host/activities` | `GET /host/activities` | Desktop table, phone cards; upcoming, past, sold out, empty; "Mark attendance" status after start | W1 |
| H2 Create / edit | `/host/activities/new`, `/[id]/edit` | `POST /activities`, `PATCH /activities/:id`, photo upload (§4.9) | Every field with copy-deck validation; community select; date, time and IANA zone (default from the browser, editable); price + currency; capacity stepper (never below booked); location picker (§4.10); preview card; publish; lock warning; locked fields after the first booking (`location_locked` from the API shown inline) | A1, A4, Q2, Q13 |
| H1 Attendance | `/host/activities/[id]/attendance` | `GET /host/activities/:id/attendance` + `host:<id>` topic | Live arrivals; groups summary (UX-3); remove with confirm dialog (spot freed, copy from the deck); after start: attended / no-show per row (latest wins); phone guest search by name or ref; empty | H1, H2, D3, D5 |

### 4.9 Photo upload [Proposal, §12 Q3]

The MVP plan names `POST /activities/:id/photo-upload`, but H2 requires the photo **before** the activity exists. So:

- **API:** `POST /api/uploads/photos` (signed in) → `{ key, upload: { url, fields }, expiresAt }`: an S3 presigned **POST** with policy conditions `content-length-range` 1 B–2 MB and `Content-Type` in `image/webp`, `image/jpeg`, `image/avif`, key `photos/<uuid>.<ext>` under a per-user prefix, 10-minute expiry. `ActivityCreate` and `ActivityPatch` gain `photoKey`; the API checks the object exists and belongs to the caller's prefix (`HeadObject`) and stores `activities.photo_key` (column exists [Verified, `apps/api/migrations/20261103140100_schema.sql`]).
- **Client:** before upload, the browser resizes and encodes the photo to WebP at 1280 px wide (quality ~0.8) with `createImageBitmap` + `OffscreenCanvas`/canvas, so the API stays out of the byte path (PRD Q5) and S6's ~60 kB hero budget can be met with a second 640 px variant [Proposal: upload two objects, `<key>.webp` and `<key>-640.webp`].
- **Serving:** `photoUrl` = `PHOTO_BASE_URL/<key>`: `https://<cloudfront>/photos/...` in production (OAC), the MinIO URL locally. The snapshot and `ActivityCard` start returning it.
- **Library:** `@aws-sdk/client-s3` and `@aws-sdk/s3-presigned-post`, latest stable, pinned [Proposal]. Bun's built-in S3 client presigns PUT only, which can't enforce a size limit, and the MVP plan keeps Bun-only APIs inside `modules/realtime` and `index.ts`.
- **Infra:** instance role gets `s3:PutObject`/`GetObject` on `photos/*` of the photos bucket (CDK change); bucket CORS allows POST from the distribution origin; local Compose creates the MinIO bucket on start.

### 4.10 Google Maps on web [Proposal, §12 Q2]

- **Location picker (H2):** Places Autocomplete (New) through the Maps JavaScript API `places` library; selecting a place prefills venue name, address and pin; the pin drags; arrow keys nudge it by ~10 m when the map has focus (Maps NFR-004); "drop a pin without a place" path (Maps FR-002); "pin is public" note (Maps SEC-M05); no-results and maps-unavailable states. Fallback when the key is missing or Maps fails: venue name, address and manual coordinates fields, so local development and outages still allow publishing [Proposal; Maps FR-004 still requires a pin].
- **Activity page (B1) and Plan (B4):** static map image (from the snapshot's `staticMapUrl`, signed by S6's code) with fixed size and alt text; on B1 a tap loads the interactive map. When `staticMapUrl` is null, the address block shows alone (A7).
- **Community map (C1):** Maps JavaScript API with markers and clustering, loaded when Map is chosen.
- **Loader:** `@googlemaps/js-api-loader`, latest stable, pinned; one shared loader so the script loads once.
- **Keys:** a browser key restricted by HTTP referrer to the `cloudfront.net` hostname and `localhost`, and to Maps JavaScript API + Places API (New). It is public by nature; it reaches the browser as `NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY` at build time. The server key and URL-signing secret are S6's (static maps). Map ID for advanced markers if needed [Assumption: decide at implementation].
- **Directions:** `directionsUrl` from the snapshot (Maps FR-011).
- **CSP** adds `maps.googleapis.com`, `maps.gstatic.com`, `*.googleapis.com` for scripts, images and connections (Maps §6).

### 4.11 Production wiring [Proposal]

- **Image:** `apps/web/Dockerfile`, Next.js `output: 'standalone'`, Node LTS image (latest LTS, pinned by digest), non-root, ARM64 (the instance is `t4g.small`). Built and pushed to GHCR by the existing deploy workflow next to the API image.
- **Compose (`infra/docker-compose.prod.yml`):** a `web` service on port 3000 with `API_INTERNAL_URL=http://api:3001`, `ORIGIN_VERIFY_SECRET`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `NODE_ENV=production`, healthcheck on `/healthz` (a Next route handler, exempt from the origin check), memory limit.
- **Origin check:** Next.js middleware rejects requests without the correct `X-Origin-Verify` in production (as the API does), except `/healthz`.
- **CloudFront (CDK, `infra/aws/lib/app-stack.ts`):** default behavior → instance port 3000, caching disabled, all viewer headers except `Host`, cookies and query strings forwarded (as `/api/*`); new `/_next/static/*` behavior → port 3000 with the managed `CachingOptimized` policy; security group adds port 3000 from the CloudFront prefix list. The unused `/ws` behavior from S10 is removed (S3 moved the socket to `/api/ws`).
- **Telemetry:** Next.js built-in OpenTelemetry (`instrumentation.ts`, `@vercel/otel` or the OTel SDK [Assumption: pick whichever works on Next's Node runtime at implementation]) exporting OTLP to the collector; route templates only; no personal data, codes or tokens (CLAUDE.md, SEC-011). Web vitals RUM is S8.
- **Security headers:** CSP (self + Google Maps + photos origin), `Referrer-Policy: strict-origin-when-cross-origin`, `X-Content-Type-Options: nosniff`, `Permissions-Policy` minimal, `frame-ancestors 'none'`.

### 4.12 Tests [Proposal]

- **Vitest + Testing Library + jsdom** for components and logic: `SpotsBadge` states, the realtime client (version gate, poll fallback, resync, subscribe-before-fetch ordering, `rendered` acks) against a fake socket, `apiFetch` error mapping, idempotency key reuse on retry, formatters (time in zone, money, short names), avatar colour hash (shared fixtures with S7), H2 validation, invite share URLs.
- **API tests** (`bun test`) for the photo upload endpoint and `photoKey` validation against MinIO.
- **Manual end-to-end** in Chrome (Claude in Chrome, per memory) against local Compose and the deployed stack, for the host and booker flows, at 360, 390, 768, 1024 and 1280 px, recorded in VALIDATION Part B. Automated Playwright suites belong to S9 [§12 Q5].

## 5. Architectural considerations

- **Correctness:** the web never decides availability. Optimistic "Booking…" state is rolled back on any typed error; spots come only from snapshots and versioned events (MVP plan §4.1, principle 3).
- **Security:** session cookie httpOnly and first-party; device cookie holds only a random ID; no contact details in URLs (PRD Privacy); vouch contact sent only in the POST body; CSP; origin lockdown extended to the web container; Maps browser key restricted by referrer and API.
- **Privacy:** public pages render only `PublicPerson`; Plan and host pages render `MemberPerson` exactly as the API returns it. The privacy note for Google Maps is shown where maps load (Maps SEC-M03) [Assumption: as a line under the map and in the footer].
- **Performance:** SSR for B1, C1 and P1; maps lazy; images via `next/image` with the photo origin allowed; Tailwind purged CSS. The 1.5 s budget is S6's (invite page), but B1 follows the same habits.
- **Accessibility:** UX NFR-001–004 and Maps NFR-004; polite throttled live region; text scales without overflow.
- **Operations:** one more container on the `t4g.small` (memory checked during deploy; Next standalone on Node idles at roughly 100–150 MB [Assumption]).

## 6. Components and files affected

| Path | Change |
| --- | --- |
| `apps/web/**` | New Next.js app |
| `packages/design-tokens/**` | New: tokens, build script, generated CSS and Dart |
| `package.json`, `bun.lock` | Workspace `apps/web`; scripts `web:dev`, `web:build`, `web:test`, `tokens:build`; `typecheck` and `lint` cover `apps/web` |
| `apps/api/src/modules/uploads/*` | New: presigned POST |
| `apps/api/src/modules/activities/*`, `snapshot.ts` | `photoKey` on create and patch; `photoUrl` from `PHOTO_BASE_URL` |
| `apps/api/src/config.ts`, `.env.example` | `S3_ENDPOINT`, `S3_REGION`, `PHOTOS_BUCKET`, `PHOTO_BASE_URL` |
| `packages/contracts/src/{activities,uploads,index}.ts`, `openapi.json` | `photoKey`; `PhotoUploadResponse` |
| `infra/docker-compose.yml` | MinIO bucket creation; web dev not containerised |
| `infra/docker-compose.prod.yml` | `web` service; API S3 env |
| `infra/aws/lib/app-stack.ts` | Default behavior → web, `/_next/static/*`, SG port 3000, photos bucket CORS and instance role S3 write, remove `/ws` |
| `.github/workflows/ci.yml`, `deploy.yml` | Web lint, typecheck, test, build; web image build and deploy |
| `README.md`, `CHANGELOG.md`, `ROADMAP.md` | Docs |

## 7. Implementation phases and ordered tasks

| # | Task | Phase | Verified by |
| --- | --- | --- | --- |
| T1 | Look up and pin latest stable Next.js, React, Tailwind, Vitest, Testing Library, AWS SDK v3, Maps loader, marker clusterer, Node LTS image; record in Part B | A | V-VER-1 |
| T2 | `packages/design-tokens` from the approved `tokens.json`; CSS, Tailwind theme and Dart outputs; avatar hash with fixtures | A | V-TOK-1, V-TOK-2 |
| T3 | `apps/web` scaffold, fonts, ESLint/Prettier/tsc wiring, Vitest | A | V-CI-1 |
| T4 | Component port (all 29, map components stubbed until T10) | A | V-CMP-1 |
| T5 | API client, device cookie, session pages (X1), app shell (X3), X4 | A | V-AUTH-1, V-ERR-1 |
| T6 | Realtime client | A | V-RT-1…3 |
| T7 | Production wiring: Dockerfile, prod Compose, origin check, CDK default and static behaviors, CSP, telemetry; deploy | A | V-DEP-1…4, V-SEC-3, V-OBS-1 |
| T8 | Photo upload API, contracts, MinIO bucket, CDK S3 permissions and CORS | B | V-PH-1, V-PH-2 |
| T9 | Google Maps browser key wiring (needs the owner's key, §12 Q2) | B | V-SEC-3, V-MAP-5 |
| T10 | Map components: picker, location block, interactive map, community map | B | V-MAP-2…6 |
| T11 | C1, B1 with all states, B2 | C | V-BK-1…5 |
| T12 | B4 with B3 and B3b, B6, P1 | C | V-PLAN-1, V-INV-1, V-INV-2, V-MY-1, V-PROF-1 |
| T13 | H3, H2 with picker and photo, lock handling | D | V-HOST-1…3 |
| T14 | H1 with live arrivals, removal and marks | D | V-ATT-1, V-ATT-2 |
| T15 | Accessibility and responsive pass at the five widths | All | V-A11Y-1, V-RESP-1 |
| T16 | Manual end-to-end flows locally and on the deployed stack; record Part B; CHANGELOG, ROADMAP | All | V-E2E-1, V-E2E-2 |

S6 may start after T7.

## 8. Dependencies and prerequisites

- S1–S4 implemented, S10 app stack deployed [Verified, ROADMAP].
- **Owner action:** a Google Cloud project (to be created under the owner's Google account, decided 2026-11-04) with billing, Maps JavaScript API and Places API (New) enabled, a referrer-restricted browser key, and the $10 monthly budget alert (MAP-D5, MAP-D6). Shared with S6 (Static Maps) and S7 (mobile SDKs). Until it exists, T9–T10 run against the A7 fallback only.
- **Owner action:** a CDK deploy for the CloudFront and IAM changes (`bun run aws:deploy`), unless the session is allowed to run it.
- Fonts: decided (§12 Q1).

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Shared web foundation becomes a bottleneck for S6 | Phase A first and kept small; S6 starts at T7 |
| Design-system components drift from the canvas during the port | Port component by component against each README and preview; screens checked side by side with the canvas in Chrome |
| The `t4g.small` runs out of memory with a second Node process | Compose memory limits; check `free`/container stats after deploy; the instance size is a CDK parameter |
| CloudFront change breaks `/api/*` routing | Only the default and a new static behavior change; `/api/healthz` checked after deploy; CDK diff reviewed first |
| Maps key missing during development | A7 fallback paths are real features, tested first |
| Client-side image resize fails on old browsers | Fall back to uploading the original if it's ≤ 2 MB and an accepted type; otherwise show the copy-deck error |
| Next.js server-side fetches miss the origin header | Covered by V-DEP-2 on the deployed stack |
| Optimistic booking UI shows a spot that wasn't booked | Rollback on every non-201; success shown only after the response |

## 10. Alternatives considered

- **Generated TypeScript client from OpenAPI (`openapi-fetch`):** another generator step when Zod schemas are already importable.
- **Hono `hc` typed client:** needs the API's route types, which would make `apps/web` import `apps/api` (MVP plan §6 forbids it).
- **A separate spec for the web foundation:** cleaner boundaries, more paperwork; a phase inside S5 is enough (§12 Q4).
- **Server-side image processing (`sharp`) in the API:** puts the API in the byte path (PRD Q5) and adds a native dependency on Bun.
- **Upload after create (`POST /activities/:id/photo-upload`):** the design requires the photo before publishing.

## 11. Estimated complexity

Large: about 15 screens with many states, 29 components, a realtime client, an upload path, Maps and production wiring.

## 12. Assumptions and open questions

**Open questions** (each with a recommendation):

1. ~~**Q1: Display font.**~~ **Answered 2026-11-04:** Sora (SIL OFL) for display, DM Sans (SIL OFL) for body text (Satoshi replaced the same day for licence reasons, §4.3).
2. **Q2: Google Cloud project.** **Answered 2026-11-04:** it doesn't exist yet and will be created under the owner's Google account, with Maps JavaScript API, Places API (New), Maps Static API and Maps SDK for Android (iOS SDK too, for the simulator); a billing account; per-platform restricted keys; the $10 budget alert. Claude creates it with the `gcloud` CLI on the owner's authenticated session (decided 2026-11-04), after checking for an existing billing account. Until it exists, the fallbacks are built and tested.
3. **Q3: Photo variants.** **Answered 2026-11-04, as recommended:** the browser uploads two WebP variants (1280 px and 640 px) through a presigned POST before the activity is created (§4.9). This departs from the MVP plan's `POST /activities/:id/photo-upload`.
4. **Q4: Order with S6.** **Answered 2026-11-04, as recommended:** S5 Phase A (T1–T7), then S6, then S5 Phases B–D; S7 in parallel throughout.
5. **Q5: End-to-end tests.** **Answered 2026-11-04, as recommended:** S5 and S6 verify flows manually in Chrome (local and deployed) and with Vitest; Playwright suites stay in S9 as the MVP plan says.

**Assumptions:**

- Next.js's current major supports `output: 'standalone'` and built-in OpenTelemetry on Node.
- The Fontshare licence allows self-hosting and app bundling.

## 13. Related specs and PRD sections

- PRD: W1, A1–A7, B1–B3, L1, L2, I1–I3, H1, H2, Business rules, Edge cases, Notifications, NFRs (Performance, Privacy, Accessibility), D3, D5, Q2, Q5, Q9–Q14.
- MVP plan §4.5, §4.6, §4.8, §4.10, §4.11, §5, §6, §7 (S5).
- UI design §5.3–§5.6; UX spec copy deck and UX-1–UX-5; Maps spec FR-001–FR-015, NFR-003, NFR-004, SEC-M03, SEC-M05.
- S3 client rules; S4 §4.3–§4.12; S10 §4 (CloudFront, photos bucket).
- Siblings S6 and S7; next S8 (holdout via `canInvite`, web vitals, admin A1), S9 (Playwright, accessibility pass, Lighthouse).

## 14. Change log

- 2026-11-04 12:50: created, together with S6 and S7.
- 2026-11-04: owner answers. Q1 Sora display font approved. Q2 Google Cloud project to be created under the owner's Google account by Claude with `gcloud`. Q3–Q5 accepted as recommended. All open questions answered.
- 2026-11-04: approved by the owner and authorized for implementation.
- 2026-11-04 (T2–T3): body font changed from Satoshi to DM Sans with the owner's approval (licence forbids public-repository redistribution and subsetting). Avatar hash is the prototype's djb2, not FNV-1a, so production matches the approved canvas.
- 2026-11-04 (T4–T7), implementation notes:
  - Components keep the prototype's `vl-` CSS (`apps/web/components/velio.css`, ported from the approved `bundle.css`) on the token variables, rather than restyling each in Tailwind: identical to the approved canvas and faster. Tailwind (on the same tokens) lays out screens. `packages/design-tokens` also emits the prototype's plain variable names (`--lime`, `--space-4`, …) for that CSS.
  - Next.js 16 renamed middleware to `proxy.ts`; the device cookie and origin check live there.
  - CSP allows `'unsafe-inline'` scripts for Next's hydration payload; nonces would force every page to render dynamically. Revisit in S9.
  - Server telemetry uses the API's OTel SDK versions, plus an exporting wrapper that templates span names and URL attributes (Next's built-in spans carry raw paths with codes and IDs).
  - `SpotsBadge` is not itself a live region; one throttled polite region per page announces changes (UX NFR-003).
  - The API Dockerfile now copies the two new workspace manifests so its frozen install still matches the lockfile.
- 2026-11-04 (T8), implementation notes and departures from §4.9:
  - `POST /api/uploads/photos` takes `{ contentType }` and returns **two** presigned POSTs, `uploads.large` and `uploads.small` (the `-640` sibling key), instead of one `upload`: a POST policy pins an exact key, and an S3 policy has no "one of these types" condition, so the requested type is pinned too (`Content-Type` eq). Keys are `<user id>/<uuid>.<ext>`; objects live at `photos/<key>` because CloudFront serves `/photos/*` unchanged.
  - No `PHOTO_BASE_URL`: `photoUrl` stays `/photos/<key>`, which the API already returned, on the app's origin. Locally the Next dev server rewrites `/photos/*` to MinIO. `HostActivity` gains `photoKey` for the edit form. `PATCH` accepts `photoKey: null` to remove the photo.
  - Config: `PHOTOS_BUCKET` (required in production), `S3_REGION`, `S3_ENDPOINT`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`; outside production they default to Compose's MinIO. The instance metadata hop limit is already 2 (checked on the live instance), so the API container gets the instance role's credentials.
  - Bucket CORS can't reference the distribution that fronts the bucket (a CloudFormation cycle), so the stack takes `appOrigin` (`https://depimls1pcvv4.cloudfront.net`, the stable hostname) as a prop. The instance role gets `PutObject` and `GetObject` on `photos/*` only.
  - Local Compose creates the bucket with two one-shot `mc` services (Chainguard's minio-client has no shell): `minio-bucket`, then `minio-photos-public` (anonymous read of `photos/`, as CloudFront serves it). CI starts MinIO and runs the second.
  - Passing the bucket name to production (approved by the owner 2026-11-04): the Deploy workflow reads the `PhotosBucket` stack output and calls `deploy.sh <sha> <bucket>`, which writes `PHOTOS_BUCKET` into `/opt/velio/.env` for the prod Compose file. Changing user data instead would restart the instance. A workflow rollback to a commit from before T8 still works: its `deploy.sh` ignores the extra argument.
- 2026-11-04 (T7 deploy fix, owner-authorized): the first `aws:deploy` of S5/S6 failed and rolled back cleanly (`UPDATE_ROLLBACK_COMPLETE`): adding the CloudFront rule for port 3000 exceeded the 60 rules per security group, because each use of the CloudFront origin-facing prefix list counts as ~55 rules. The S5 description change on `AppSg` would also have replaced the group and restarted the instance (`SecurityGroupIds` is "Some interruptions"). Fix: the live description is restored, the live 3001 rule is untouched, the 3000 rule is added to the same group, and the eu-west-2 quota L-0EA8095F is raised to 120 (README "AWS quotas"). Rejected: a port range on one rule (its replacement is created before the old rule is deleted, so the quota is exceeded mid-deploy), and a second security group (restarts the instance). The pipeline's `GetSecretValue` failure on `velio/prod/google-maps` had the same root cause: the S6 secret and its grant existed only in code until this deploy.

- 2026-11-04: owner decision. The Google Cloud project (§12 Q2) goes under abdulbasitsaeed619@gmail.com, not techsihir@gmail.com (that account can't take another billing setup).
- 2026-11-04 (§12 Q2, done with the owner's approval): Google Cloud project `velio-maps-5eb36a` ("Velio Maps") under abdulbasitsaeed619@gmail.com, billed to "Firebase Payment" (`01B69B-C43DF3-C27D85`). That account was at its 3-project limit, so at the owner's choice billing was disabled on `nayadigitalsolutions`. Enabled: Maps JavaScript, Places (New), Maps Static, Maps SDK for Android and iOS, API Keys, Billing Budgets. Keys: "Velio web (browser)" (referrers `https://depimls1pcvv4.cloudfront.net/*`, `http://localhost:3000/*`; Maps JavaScript + Places) and "Velio static maps (signed)" (Maps Static only; URLs are signed). Budget "Velio Maps monthly": **€10** (the billing account is in EUR; MAP-D6's $10 equivalent), scoped to the project, alerts at 50/90/100%. The browser key is in the GitHub variable `GOOGLE_MAPS_BROWSER_KEY` and the ignored `apps/web/.env.local`. Mobile keys wait for S7's package and signing certificate.
- 2026-11-04 (T9–T10), implementation notes and departures from §4.10:
  - No `@googlemaps/markerclusterer` and no Map ID. Advanced Markers need a Map ID, which is created only in the Console; the approved design's markers and pin are custom HTML anyway. Markers, clusters and the pin are drawn in one `OverlayView` pane with React portals, and clustering is a small greedy pixel clustering (`lib/maps/geo.ts`, tested). Activities at the same spot open the first one instead of zooming forever.
  - The picker's pin is fixed at the map's centre and the map drags under it (the design's "Drag the map to place the pin"); Google's own keyboard shortcuts are off and arrow keys nudge ~10 m, accumulating while a pan animates (a bug found in Chrome, now tested).
  - Live components live in `components/maps-live.tsx` (`'use client'`); `components/maps.tsx` stays server-renderable. `LocationBlock` gains `mapSlot` so B1 can put `ExploreMap` in it. The meeting point field stays with the H2 form (T13), not the picker.
  - New copy, not in the copy deck, for the no-Maps fallback: "Venue name", "Address", "Latitude", "Longitude", "Copy the pin's coordinates from any map app.", "Between -90 and 90" / "Between -180 and 180", and "Show the map" (B1 when there's no static image). Owner review at T13.
  - The key loads at build time from `NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY` (GitHub variable in deploys, `apps/web/.env.local` locally). `gm_authFailure` (a rejected key) switches every live map to its fallback.
- 2026-11-04 (T11), implementation notes and departures:
  - Routes sit directly under `app/` (`activities/[id]`, `communities/[slug]`, `plans/[id]`), not in an `(app)` group: each page renders `SiteHeader` with its own nav item, so a group layout adds nothing.
  - B2 is `/plans/<id>?welcome=1` as planned. "Shown once" is done by dropping `?welcome=1` from the address on mount (`history.replaceState`), so a reload or a return shows B4. Its invite choices go to `/plans/<id>?invite=vouch|public`, as S6's G4 does. Without `canInvite` (holdout) B2 shows only the confirmation and "Go to my plan". B4 itself is T12; until then `/plans/<id>` without `welcome` is a 404.
  - C1 on phone loads Maps only when Map is chosen (NFR-004). From 768 px the approved desktop canvas shows the list and map side by side, so the map loads there without a choice; below ~1100 px it wraps under the list, as the canvas's flex rules do.
  - B1 puts the `LivePill` in the header (`AppHeader` gains a `status` slot; `SiteHeader live`). New copy, not in the deck, for owner review at T16: "Reconnect to book" (B1 offline, after S6's "Reconnect to claim"); "Free. Velio doesn't take payment."; the removed-booking banner reuses the claim form's copy.
  - Bugs fixed outside T11's screens: `apiFetch` without a schema returned `undefined` even when the API sent JSON, so S6's invite page got nothing from its reconnect refresh and its live next-steps fetch (G5 reached live showed no suggestions). It now returns the unchecked body; `apiJson<T>` types it. Regression tests added. `CommunityMapLive` zoomed past the tiles (blank map) when every activity shares one pin; it now centres at street level. `useOnline` moved to `lib/online.ts`; the claim form's idempotency key helper moved to `lib/attempt-key.ts`, shared with booking.
- 2026-11-04 (T12), implementation notes and departures from §4.8:
  - B3 and B3b are full screens at `/plans/<id>?invite=vouch|public`, as the approved canvas draws them (back bar, no site header), not a dialog or bottom sheet. B2 and S6's G4 already link there, and a reload keeps the step. The query survives sign-in. Without `canInvite`, `?invite=` shows B4.
  - B3b fetches the caller's link with `POST /plans/:id/invites { rail: public }` (the API returns the existing one). Resume is offered for links paused by their creator or the auto-pause, not by the host (the API would allow it, but that would override the host). No pause button: FR-028 asks only for the paused state and resume.
  - B4 hides the invite tools when the activity is sold out, as B2 does; invite rows show "Paused" on a paused public link. Removed viewers see the banner, spots and next steps only.
  - B6 has no attendance data in `MyPlan`, so past cards show the design's default "Went"; "No-show" needs the API to return the host's mark (open for T14 or S8).
  - FR-011: the role toggle is remembered in a `velio_role` cookie (one year, first-party, not httpOnly); `/host/*` is always Host. Home doesn't redirect by role, because every "Communities" link points at `/`.
  - Sign-out is on B6 (V-AUTH-1 deferred it here): `DELETE /api/sessions/current`, then home.
  - New copy, not in the deck, for owner review at T16: "Share" (Web Share API on B3, where available); "Couldn't copy. Press and hold the link to copy it."; "Address copied"; B3 errors ("We couldn't create the invite." / "Check your connection and try again.", "You're offline" / "Reconnect to create an invite.", "This activity has started." / "Invites close at the start time."); B3b "You paused this link." / "Nobody can claim from it until you resume it. Bookings already made are safe.", "The host paused this link." / "Bookings already made are safe. Vouch invites still work.", "Resume link", "We couldn't get your link."; B6 "Nothing coming up." / "No past plans yet." (one tab empty), "Plans for {Name}." and "Sign out".
- 2026-11-04 (T13), implementation notes and departures from §4.8:
  - API addition: `GET /host/activities` items gain `markedCount` and `attendedCount` (latest mark per confirmed booking; one extra query for the whole list), contract `HostActivityItem`. H3 needs them for `host.markStatus` ("Mark attendance" until someone is marked, then "{n} attended"). OpenAPI regenerated.
  - The edit form loads from the public snapshot (`GET /activities/:id`), which already carries every field H2 shows; non-hosts (`viewer.isHost` false) get X4's not-found. No new host GET endpoint.
  - Price and community are set at creation only: `ActivityPatch` has neither, so in edit they show read-only. Communities carry no currency, so each prices in its country's (Explore Kenya KES, The Tanzania Experience TZS, The Medina Collective MAD; `lib/host-form.ts`), shown in the price label as on the canvas. The picker starts at the community's city.
  - The photo is required to publish (the canvas's validation state and `host.photoEmpty` error). The browser encodes WebP and falls back to JPEG where the canvas can't encode WebP (Safari); both variants use the same type.
  - Publish goes to `/host/activities/<id>/edit?published=1`: the published banner over the form in edit mode, so a reload keeps the state. Save shows a "Changes saved" toast and refreshes the server view.
  - The time zone field is a text field with the browser's zone list as suggestions (`<datalist>`), defaulting to the browser's zone after hydration.
  - Phone H2 keeps the site header and a "My activities" link instead of the canvas's back bar, so one layout serves every width. Phone H3 cards open attendance, as on the canvas; Edit is on the desktop table and will be on H1 (T14).
  - New copy, not in the deck, for owner review at T16: "Pick a start time.", "Pick a time zone from the list.", "Search for a place, or drop a pin on the map.", "Add the venue name.", "Add the address.", "Enter the price per person.", "At least 1 spot.", "{n} booked, so at least {n}.", "At most 100,000 spots.", "That's fewer spots than people have booked.", "Upload the photo again.", "We couldn't read that photo. Try a JPG or PNG.", "We couldn't upload the photo. Check your connection and try again.", "Uploading…", "We couldn't publish this." / "We couldn't save your changes." / "You can't edit this activity.", "Changes saved", "{n} things need fixing before you can save." (edit variant of `host.validationSummary`), "Meeting point (optional)" placeholder "Where exactly to find you", H3 "No bookings" (past, nobody booked), "Nothing coming up." / "No past activities yet." (one tab empty).
- 2026-11-04 (T14), implementation notes and departures from §4.8:
  - H1 loads `GET /host/activities/:id/attendance` and the public snapshot (title and venue, which the attendance view lacks) on the server; a 400, 403 or 404 from either shows X4's not-found. No API change.
  - Order: newest first before the start ("Newest first"); booking order after it, so rows stay put while the host marks. Removed bookings stay on the list, last, struck through, with "Removed" for the time and no actions (FR-037).
  - A row that arrives after the page loaded gets the lime sweep and "Booked just now". The page switches to marking at the start time without a reload (a timer, then a refetch).
  - Groups (UX-3): one per Plan with two or more confirmed bookings, named "{first name}'s group" after the Plan's first booking; one-person Plans add up to "Booked alone". As on the canvas, the summary shows from 768 px only.
  - Remove: the canvas's dialog from 768 px and bottom sheet on phone; "Keep" takes focus and Escape cancels. "Edit activity" sits in the aside at every width (T13 moved Edit to H1), before the start only.
  - Phone keeps the site header (with the Live pill) and a "My activities" link instead of the canvas's back bar, as T13 did for H2. The started banner sits above the list heading at every width (the desktop canvas puts it under the heading).
  - Bug fixed outside T14: `useLiveSpots` announced spots changes from inside a state updater, so a live `spots` event logged React's "Cannot update a component while rendering a different component" on every live screen (B1, B4, B6, H1). The version gate now reads a ref, and the announcement runs outside the updater.
  - New copy, not in the deck, for owner review at T16: "{Name} removed. Their spot is open again.", "We couldn't remove {Name}. Try again.", "You're offline. Reconnect to remove a guest.", "{Name} was removed, so they can't be marked.", "You can mark attendance once the activity starts.", "You're offline. Reconnect to mark attendance.", "We couldn't save that mark. Try again.", "No guest matches "{query}".", "Nobody booked this activity." (empty, after the start), "Bookings close at {time} {zone} on {day}." (desktop canvas empty body, used at every width), and the desktop stat labels "Attended", "No-shows", "Through invites" and "{m} of {n} marked" as drawn on the canvas.
- 2026-11-04: owner decision. No accessibility pass in S5: T15 is the responsive pass only (V-RESP-1). V-A11Y-1 is not run here; S9's full accessibility audit (parent S9, Playwright and axe) stays the place for it. NFR-003's live-region throttle and the components' own semantics, already built and unit-tested, are unchanged.
- 2026-11-04 (T15, responsive only), implementation notes:
  - H3 shows the table from 1024 px and the cards below it (two columns from 768 px), not the table from 768 px as §4.8 had it: at 768 px the 760 px-wide table scrolled sideways inside its card and hid Attendance and Edit.
  - Bug fixed: B1 showed the spots badge twice on phone. `hidden` on a design component loses to its own `vl-` display rule (that CSS sits outside Tailwind's layers), so the desktop badge is wrapped in a span that carries the breakpoint. No other design component takes a display utility.
- 2026-11-04: owner approved all new copy from T9–T14 as written; recorded in the UI design spec's copy deck (§5.5, *S5 web build*).
- 2026-11-04 (T16): deployed run on `f43f4bf` passed (VALIDATION Part B, *Deployed checks (T16)*). Two defects found and left open for the owner: D1 (B1's "Be the first to book" stays after a live sell-out) and D2 (cards load the 1280 px photo, not the 640 px variant). Status set to Implemented; validation Passed with exceptions.
- 2026-11-04: owner approved fixing D1 and D2 within S5. Fixed in `components/activity/activity-live.tsx` (members refetched after a live spots change) and `components/primitives.tsx` (`Photo` `srcset`/`sizes` with the 640 px variant), with unit tests. No API or contract change.
- 2026-11-04: §4.9 photo encoding changed for S6 D4 (owner's choice): the browser crops each upload to 16:10 around the centre before resizing (every screen shows photos at 16:10 or wider, cover-cropped), and encodes WebP at quality 0.7 (JPEG 0.72) instead of 0.8 (0.82). The hero's `sizes` becomes `(min-width: 768px) 60vw, 45vw` so phones take the 640 px file. Hosts' originals aren't kept; existing uploads are unchanged. Unit test for the crop in `apps/web/test/photo.test.ts`.
