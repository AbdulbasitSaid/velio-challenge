# Validation: S5 Web app: foundation, host and booker

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] Scope matches parent S5 (create with photo and picker, activity page with map, community map, book, Plan, My plans, invite step, attendance, role toggle), plus the shared web foundation and production wiring that S10 deferred to S5.
- [x] No invented product targets. The 2 MB and 10-minute upload limits, the 1280/640 px variants and the 60 s hidden-tab pause are proposals, marked as such.
- [x] Open questions Q1–Q5 (PLANNING §12) answered (2026-11-04).
- [ ] Owner's Google Cloud project and browser key exist (or T9–T10 proceed on fallbacks only).

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, FR-002 | V-TOK-1, V-TOK-2 |
| FR-003, NFR-007 | V-CI-1 |
| FR-004 | V-CMP-1 |
| FR-005 | V-CMP-1 |
| FR-006, FR-007 | V-DEP-2, V-AUTH-1 |
| FR-008 | V-ERR-2 |
| FR-009, NFR-003 | V-RT-1, V-RT-2, V-RT-3 |
| FR-010, FR-011, SEC-003 | V-AUTH-1 |
| FR-012 | V-ERR-1 |
| FR-013, FR-014, SEC-006 | V-PH-1 |
| FR-015, FR-016, FR-041, AC-009 | V-PH-2 |
| FR-017 | V-MAP-2 |
| FR-018, FR-019 | V-MAP-3 |
| FR-020 | V-MAP-4 |
| FR-021, AC-010 | V-MAP-5 |
| FR-022 | V-BK-1 |
| FR-023 | V-BK-2 |
| FR-024 | V-BK-3 |
| FR-025 | V-BK-4 |
| FR-026 | V-BK-5 |
| FR-027 | V-INV-1 |
| FR-028 | V-INV-2 |
| FR-029, AC-004 | V-PLAN-1 |
| FR-030 | V-MY-1 |
| FR-031 | V-PROF-1 |
| FR-032 | V-HOST-1 |
| FR-033 | V-HOST-2 |
| FR-034 | V-HOST-3 |
| FR-035, FR-038 | V-ATT-1 |
| FR-036, FR-037, AC-008 | V-ATT-2 |
| FR-039 | V-DEP-1 |
| FR-040 | V-DEP-3 |
| NFR-001, AC-007 | V-RESP-1 |
| NFR-002 | V-A11Y-1 |
| NFR-004 | V-MAP-6 |
| NFR-005 | V-VER-1 |
| NFR-006 | V-OBS-1 |
| NFR-008 | V-DEP-4 |
| SEC-001 | V-SEC-1 |
| SEC-002 | V-SEC-2 |
| SEC-004, SEC-005 | V-SEC-3 |
| SEC-007 | V-MAP-3 |
| SEC-008 | V-SEC-4 |
| AC-001 | V-E2E-1 |
| AC-002 | V-E2E-2 |
| AC-003, AC-005 | V-RT-3 |
| AC-006 | V-STATE-1 |

### Proposed checks

**Automated (Vitest, `bun test`, CI):**

| ID | Check | Expected |
| --- | --- | --- |
| V-TOK-1 | `bun run tokens:build` then `git diff --exit-code packages/design-tokens` | Generated CSS, Tailwind theme and Dart match `tokens.json`; no drift |
| V-TOK-2 | Avatar hash fixtures (seed → colour index) | All pass; same fixtures used by S7 |
| V-CI-1 | `bun run lint && bun run typecheck && bun run format:check && bun run web:test && bun run web:build` | All pass locally and in CI |
| V-CMP-1 | Component tests: each ported component renders its README's documented states; `SpotsBadge` five states; reduced-motion fade | Pass |
| V-RT-1 | Realtime client against a fake socket: `subscribe` sent before the snapshot fetch; version gate drops `≤` versions; `resync`, `plan`, `attendance` trigger the right refetch; `rendered` sent once per painted version | Pass |
| V-RT-2 | Disconnect: stale state set, polling every 10 s (fake timers), reconnect with `resume=1` and backoff; live region announces at most once per 5 s | Pass |
| V-ERR-2 | `apiFetch` maps every code in `@velio/contracts/errors` to a copy-deck message; unknown codes map to the generic error | Pass |
| V-BK-3 | Booking action: one key per attempt, reused on retry; success only on `201`/`200`; rollback on each typed error | Pass |
| V-PH-1 | `bun test` against MinIO: presigned POST accepts a 1 MB WebP, rejects 3 MB and `image/gif`; `photoKey` from another user's prefix or a missing object → `400` | Pass |
| V-HOST-2 | H2 form validation unit tests: each copy-deck error, summary count, meeting point ≤ 140, capacity ≥ 1 | Pass |
| V-INV-1 | Share URLs: WhatsApp and SMS URLs encode `vouch.message` with the link; no contact in any URL | Pass |
| V-SEC-2 | Grep built client bundle and test logs for contact fields in URLs or storage; vouch contact only in POST body | None found |
| V-OBS-1 | Inspect exported spans locally (collector debug exporter): route templates only, no codes, names or contacts | Pass |

**Manual, in Chrome (local Compose, then the deployed stack):**

| ID | Procedure | Expected |
| --- | --- | --- |
| V-VER-1 | Record each new dependency's and image's latest stable version at implementation time and the pinned value | Pinned = latest stable (or a recorded exception) |
| V-AUTH-1 | Sign in, sign out, deep page while signed out → X1 → back to page; role toggle persists; device cookie set and sent as `X-Device-Id` | As described |
| V-ERR-1 | Visit an unknown route; force an SSR error | X4 404 and 500 with reference |
| V-RT-3 | Two browsers on B1: book in one; block `/api/ws` in DevTools in the other, watch "Reconnecting" and polling, unblock | Live update ≤ 2 s; stale state while blocked; recovers without reload; sold out shown in both |
| V-PH-2 | Upload a large JPEG in H2; check the two WebP objects and sizes; check `photoUrl` on B1, C1 and B6 | Photo shows; 640 px variant ≤ ~60 kB for a typical photo [Assumption]; served from `/photos/` in production |
| V-MAP-2 | H2 picker: search, select, drag, keyboard nudge, drop pin without place, no results, key removed | Prefill and pin behave as designed; fallback fields when maps are unavailable |
| V-MAP-3 | B1 and B4 location block: static map present when signed (after S6) or address-only; directions link opens Google Maps; privacy note visible | As designed |
| V-MAP-4 | C1 map: markers only for activities with spots, cluster at low zoom, summary card links to B1 | As designed |
| V-MAP-5 | Block `maps.googleapis.com`; visit B1, C1, H2, B4; book and publish | Fallbacks show; booking and publishing work |
| V-MAP-6 | Network panel on first load of B1 and C1 (list) | No Maps JS request until interaction or Map tab |
| V-BK-1 | C1 list and map, empty community, map failed | As designed |
| V-BK-2 | B1 content: zone-labelled time, currency price with "pay the host on the day", avatar stack, `PublicPerson` names | As designed |
| V-BK-4 | Drive each B1 state: last spots, sold out, sold out mid-checkout (two sessions race the last spot), already booked, started (seed a past activity), paused (set `bookings_paused`), server error (stop the API mid-request, then retry), own activity as host | Each designed state, with next steps where designed |
| V-BK-5 | After booking: B2 invite prompt shown once; dismiss; not shown again for that booking | As designed |
| V-INV-2 | B3b: create, copy, share; pause through the API; resume | Paused state shown; resume works for the creator |
| V-PLAN-1 | B4 with members from vouch and public claims; invite statuses change live; removed viewer; only-me | As designed |
| V-MY-1 | B6 upcoming/past, removed, empty, loading | As designed |
| V-PROF-1 | P1 for a host with activities and a guest with none | As designed; no bookings shown |
| V-HOST-1 | H3 upcoming, past, sold out, empty, phone cards | As designed |
| V-HOST-3 | Edit after a booking: locked fields, capacity floor, API `location_locked` shown inline | As designed |
| V-ATT-1 | H1 live arrival while another browser books; sources and inviter names; groups summary; phone search by ref | As designed; no contacts |
| V-ATT-2 | Remove with confirm; check spots on B1 elsewhere and the removed person's B4; after start, mark attended then no-show; try marking a removed booking | Spot freed live; latest mark shown; removed not markable |
| V-STATE-1 | Walk the UI design §5.3 state list for every S5 screen side by side with the canvas | Every state present and matching |
| V-RESP-1 | Resize to 360, 390, 768, 1024, 1280 for every page and state; check `document.documentElement.scrollWidth <= innerWidth` with the JavaScript tool | No overflow |
| V-A11Y-1 | Keyboard-only pass of every flow; axe DevTools or Lighthouse accessibility on B1, B4, H1, H2; 200% browser zoom | No critical issues; focus visible; targets ≥ 44 px |
| V-SEC-1 | Inspect C1, B1, P1 HTML and API responses for full names | Only short names |
| V-SEC-3 | Check response headers for CSP and others; check the browser key's restrictions in Google Cloud | Present and restricted |
| V-SEC-4 | Open another host's attendance and edit URLs | Not-found state; API `403` |
| V-DEP-1 | Deploy; open the `cloudfront.net` root, B1, `/_next/static/*` cache headers (`x-cache: Hit` on repeat) | Web served; static assets cached; `/api/healthz` still OK |
| V-DEP-2 | On the deployed stack, an SSR page that needs the session (B4) renders with the viewer's data | API accepted the internal call |
| V-DEP-3 | `curl` the instance origin directly without the header (from the instance via SSM) | `403` |
| V-DEP-4 | `docker stats` and `free -m` on the instance after deploy and during V-E2E | Within limits; headroom recorded |
| V-E2E-1 | UI design flow 5 on the deployed stack: sign in → create with picker and photo → publish → live attendance → remove → mark (with a past-dated seeded activity for marking) | Completes |
| V-E2E-2 | UI design flow 4 on the deployed stack: community map → activity → book → invite prompt → vouch → Plan; plus sold out mid-checkout | Completes |

### Preconditions and test data

- Local Compose (Postgres, MinIO, API) with seeded communities; a seed script for a past-dated activity with bookings (for marking) and a one-spot activity (for races) [Proposal: reuse `load/seed.ts` helpers or add `apps/api/scripts/seed-dev.ts`].
- Google Maps browser key (or fallback-only runs, noted).
- Two browser profiles for two users.

### Known limitations

- No automated end-to-end tests until S9.
- Map rendering can't be verified without the owner's key.
- Lighthouse budgets are checked only for the invite page (S6).

## Part B: Executed checks

In progress. Phase A (T1–T7), Phase B (T8–T10), T11 and T12 recorded 2026-11-04; T13–T16 follow.

### V-VER-1: versions (looked up 2026-11-04 with `npm view`, nodejs.org and `docker buildx imagetools inspect`)

| Dependency | Latest stable | Pinned | Note |
| --- | --- | --- | --- |
| next, eslint-config-next's `@next/eslint-plugin-next` | 16.4.5 | 16.4.5 | |
| react, react-dom | 19.3.1 | 19.3.1 | |
| @types/react, @types/react-dom | 19.3.0 | 19.3.0 | |
| tailwindcss, @tailwindcss/postcss | 4.3.4 | 4.3.4 | |
| vitest | 5.1.0 | 5.1.0 | No `@vitejs/plugin-react`: Vitest's built-in JSX transform is enough |
| jsdom | 30.1.3 | 30.1.3 | |
| @testing-library/react · dom · user-event · jest-dom | 16.3.3 · 10.4.2 · 14.6.8 · 7.0.1 | same | |
| @types/node | 26.6.6 | 26.6.6 | |
| eslint-plugin-react-hooks | 7.1.1 | 7.1.1 | `eslint-config-next` not used: its `eslint-plugin-react` predates ESLint 10; the Next and hooks plugins are wired directly |
| @opentelemetry/* (web) | api 1.10.0, sdk-trace 3.0.0, exporter 0.300.0 | same as the API | `@vercel/otel` 2.2.1 rejected: it requires OTel 2.x / 0.200 |
| Node LTS image | 26.13.0 (LTS "Lithium", 2026-10-28) | `node:26.13.0-slim@sha256:e4db4c91…` | |
| Bun (build stage) | 1.4.4 (repo pin) | `oven/bun:1.4.4-slim@sha256:1846adf2…` | |
| Fonts | Sora, DM Sans (Google Fonts, OFL) | `next/font/google`, self-hosted at build | Satoshi dropped (PLANNING change log) |
| AWS SDK, Maps loader, marker clusterer | 3.1161.0, 2.1.3, 2.6.2 | Added in T8–T10 | |

### Phase A checks

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-TOK-1 | `bun run tokens:build && git diff --exit-code packages/design-tokens` (also a CI step) | 2026-11-04 | Pass locally (no diff after rebuild); CI step added | FR-001, FR-002 |
| V-TOK-2 | `bun test packages/design-tokens` (17 tests) and `flutter test` in `packages/design-tokens/dart` (fixtures shared) | 2026-11-04 | Pass; fixtures also checked against the prototype's `avatarIndex` with Node | FR-001, FR-002 |
| V-CMP-1 | `bun run web:test`: `test/components.test.tsx` (SpotsBadge five states, avatar fixtures, stack labels, Button, TextField a11y, Segmented, rows, maps fallbacks, dialog, banner) | 2026-11-04 | Pass | FR-004, FR-005 |
| V-RT-1, V-RT-2 (unit) | `test/realtime.test.ts` (fake socket, fake timers: subscribe-before-fetch, routing, resync, 10 s polling, `resume=1`, backoff 1 s doubling to 30 s, `rendered`, unsubscribe, hidden-tab pause) and `test/realtime-react.test.tsx` (version gate, ack after paint, 5 s announcement throttle) | 2026-11-04 | Pass | FR-009, NFR-003 |
| V-AUTH-1 (unit) | `test/api.test.ts`: device header, idempotency key, error envelope mapping, network failure, schema check, `safeNext` rejects off-site redirects | 2026-11-04 | Pass | FR-006, FR-010 |
| V-AUTH-1 (manual, part) | Chrome on local Compose + `bun run web:dev`: X1 with an invalid contact shows the inline copy; valid sign-in returns to `next` (`/me/plans`); header switches to role toggle and avatar ("TA") | 2026-11-04 | Pass. Sign-out UI and role-toggle persistence are checked with B6 (T12) | FR-010, FR-011 |
| V-OBS-1 (unit) | `test/redact.test.ts`: span names and URL attributes templated (`:code`, `:id`), query strings, headers and user agent dropped | 2026-11-04 | Pass. Collector inspection runs at deploy | NFR-006 |
| V-SEC-3 (headers) | Production image run locally: `curl -D -` on `/signin` | 2026-11-04 | CSP, `Referrer-Policy`, `nosniff`, `Permissions-Policy` present; device cookie `Secure; SameSite=Lax`. Key restrictions: T9 | SEC-004 |
| V-DEP-3 (local) | Production image with `ORIGIN_VERIFY_SECRET`: `/signin` without header, with header, `/healthz` | 2026-11-04 | `403`, `200`, `200` | SEC-002 |
| V-DEP-4 (local) | `docker stats` on the production image after start | 2026-11-04 | 91 MiB; Compose limit 512 MiB | NFR-008 |
| V-CI-1 | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && bun run web:build`; `bun test infra/aws packages` | 2026-11-04 | Pass (web 64 tests; CDK 14). Full `bun test`: 258 pass, 3 fail, the known macOS `somaxconn` claim-race failures recorded in S4 Part B; also fails with the pre-S5 `bunfig.toml` | FR-003, NFR-007 |
| Image build | `docker build -f apps/web/Dockerfile .` (arm64) | 2026-11-04 | Pass, 431 MB | FR-039 |

### Phase B checks (T8)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-VER-1 (T8) | `npm view @aws-sdk/client-s3 version`, `@aws-sdk/s3-presigned-post`; minio-client image by `docker buildx imagetools inspect` | 2026-11-04 | 3.1161.0 both, pinned; `cgr.dev/chainguard/minio-client@sha256:1dccd2a6…` | — |
| V-PH-1 | `bun test apps/api/test/uploads` against Compose MinIO (8 tests) | 2026-11-04 | Pass: 401 signed out; `image/gif` → 400; key under the caller, two targets, 10-minute expiry; MinIO accepts 1 MB WebP (204) and serves it unsigned; refuses 3 MB and 0 B (400), another type and another key (403); `photoKey` from another user, never uploaded, or malformed → 400; `photoUrl` on the snapshot and My plans cards; photo editable after a booking, `null` removes it, non-host 403 | FR-013, FR-014, FR-015, SEC-006 |
| V-CDK (T8) | `bun test infra/aws` (15) | 2026-11-04 | Pass: photos bucket CORS is POST from the app origin only; instance role has `PutObject`/`GetObject*` on `photos/*` and no delete | FR-041 |
| V-CI-1 (T8) | `bun run format:check && bun run lint && bun run typecheck && bun run contracts:openapi && bun run web:test && bun run web:build`; `bun test`; the CI MinIO step (`compose run --rm minio-photos-public`) | 2026-11-04 | Pass (web 117). `bun test`: 272 pass, 3 fail, the known macOS `somaxconn` 200-parallel races; the same tests fail on the tree without T8 | NFR-007 |

### Phase B checks (T9–T10)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-VER-1 (T10) | `npm view @googlemaps/js-api-loader version`, `@types/google.maps` | 2026-11-04 | 2.1.3 and 3.66.9, pinned; marker clusterer not used (PLANNING change log) | — |
| V-MAP-unit | `bunx vitest run test/maps.test.tsx` (13), fake `google.maps` and mocked loader | 2026-11-04 | Pass: 10 m nudge and accumulation; pixel clustering; search → keyboard pick prefills place ID, venue, address, pin, without a second search; no-results and search-failed copy; drop pin, drag (idle), venue edit; no-Maps manual fields with coordinate validation; failed load → manual fields; locked; static image loads no script until tapped; "Show the map"; clusters, marker card, cluster zoom, map click closes; unavailable → "Show the list instead" | FR-017, FR-018, FR-020, FR-021, NFR-004 |
| V-MAP-2…6 (components, live) | Chrome on `next dev` with the real browser key, a temporary dev page (deleted after) | 2026-11-04 | Pass: Places (New) suggestions for "Lake Naivasha", keyboard pick fills place ID, venue, address, coordinates; picker map at the pin; 3× ArrowUp/Right = 10 m then (after fix) 30 m; drag moved the pin 320 m; drop pin without a place; "Show the map" → interactive map with pin; community map tiles, cluster "2", marker → card, cluster click splits; no console errors (CSP allows Google). Two bugs found and fixed: suggestions reopening after a pick, and nudges not adding up during a pan | FR-017, FR-018, FR-020, SEC-004 |
| V-CI-1 (T10) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && bun run web:build` | 2026-11-04 | Pass (web 130) | NFR-007 |

### Phase C checks (T11)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-BK-3 | `bunx vitest run test/booking.test.tsx`: outcome mapping for every typed error; "Booking…" shown at once and success only on the API's answer, then `/plans/<id>?welcome=1`; a 500 offers "Try again" and the retry reuses the attempt's key; key cleared after a final outcome | 2026-11-04 | Pass | FR-024 |
| V-BK-4 (unit) | Same file: sold out mid-checkout (banner, next steps fetched, no Book), live sold out disables and a freed spot re-enables, already booked, own activity, started (closing time in the activity's zone), paused, removed, signed out → X1 with `next`, `already_booked` refreshes the server view | 2026-11-04 | Pass | FR-025, SEC-001 |
| V-BK-1 (unit) | Same file: phone list first and map only after Map, sold-out activities off the map, live sold out removes a marker and updates the count line, wide shows both, empty community | 2026-11-04 | Pass | FR-020, FR-022, NFR-004 |
| V-BK-5 (unit) | Same file: B2 lead with zone and ref, prompt with live count, vouch and share links, `?welcome=1` dropped; holdout shows no invite step | 2026-11-04 | Pass | FR-026 |
| Regression | `test/api.test.ts` (JSON without a schema), `test/invite-live.test.tsx` (G5 reached live renders fetched next steps) | 2026-11-04 | Pass; both failed against the old client | — |
| V-BK-1, V-BK-2, V-BK-4, V-BK-5 (manual, part) | Chrome, production build (`next build` + `next start -p 3100`) against local Compose and the seed: C1 at 1280 px (list and map side by side, cluster on the shared pin); B1 desktop with Live pill, details, avatar stack, "You're already going"; booked a seed activity → B2 with `VLO-` ref and 11 spots, address `/plans/<id>`; paused activity shows the banner and disabled "Bookings paused"; no console errors | 2026-11-04 | Pass. Found and fixed the blank community map. Phone-width screenshots and the two-browser race (AC-003) wait for T15/T16 (the browser window would not resize below desktop) | FR-018, FR-020, FR-022–FR-026 |
| V-CI-1 (T11) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && next build` | 2026-11-04 | Pass (web 161) | NFR-007 |
| V-INV-1 (unit) | `test/plan.test.tsx`: `vouch.message`; WhatsApp and SMS URLs carry only the message; B3 requires the name, sends the contact only in the POST body, shows "Send it to {Name}", code and send links without the contact; `invalid_contact` on the field; error mapping | 2026-11-04 | Pass | FR-027, SEC-002 |
| V-INV-2 (unit) | Same file: B3b gets the caller's link and copies it ("Link copied"); auto-paused shows `share.paused` and Resume, which calls `DELETE /invites/:code/pause` and reloads; host-paused shows a disabled "Link paused" | 2026-11-04 | Pass | FR-028 |
| V-PLAN-1 (unit) | Same file: members with full names, "(you)", "Via Tunde", public link; invite rows with status; subscribes `activity:` and `plan:`; a `plan` event refetches and moves an invite Created → Opened; only-me prompt with live count; no invite tools without `canInvite`; removed state with banner and next steps, no members or ref | 2026-11-04 | Pass | FR-029, AC-004 (unit) |
| V-MY-1 (unit) | Same file: upcoming with ref, live spots and the removed chip; past on its tab; empty state; sign-out calls `DELETE /sessions/current` | 2026-11-04 | Pass | FR-030, FR-010 |
| V-AUTH-1 (role, unit) | Same file: Host pages are Host; elsewhere the `velio_role` cookie decides; unknown values are Booker | 2026-11-04 | Pass | FR-011 |
| V-PLAN-1, V-INV-1, V-INV-2, V-MY-1, V-PROF-1, V-AUTH-1 (manual) | Chrome, production build (`next build` + `next start -p 3100`) against local Compose and the seed, signed in as a test booker: booked a seed activity → B4 only-me state at 1280 px (ref card and location in the aside); B3 empty submit shows `vouch.nameError`; created a vouch → "Send it to Wanjiru", code chip, WhatsApp, SMS, Share and Copy link, and neither send URL contains the contact; B4 shows the invite "Created"; recorded an open from another device ID through the API → "Opened" without a reload; claimed it through the API as the friend → "Claimed", "Wanjiru Njoroge · Via Tunde", 2 people, spots 11 → 10, without a reload; B3b link, paused through the API → "You paused this link." and Resume, which restores Copy link; B6 card with ref and live spots, footer and Sign out; P1 for the host (nine upcoming cards, privacy line) and for a guest (`profile.nothingHosted`, no `VLO-` anywhere); `velio_role=host` puts host navigation on `/me/plans` | 2026-11-04 | Pass. Live updates here came from the 10 s poll (rule 3): the production build on :3100 has no socket locally, as in T11. The socket path is covered by the unit test and T16's deployed run. Phone widths wait for T15 | FR-011, FR-027–FR-031, SEC-001, SEC-002 |
| V-CI-1 (T12) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && next build` | 2026-11-04 | Pass (web 185) | NFR-007 |

### Phase D checks (T13)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-READ-2 (T13) | `bun test apps/api/test/read` (9) | 2026-11-04 | Pass, including the new test: past rows count marks by the latest mark, confirmed bookings only (0/0 → 2 marked, 1 attended after a mark is superseded; a removed booking's mark drops out); the query-count test still holds | FR-032 |
| V-HOST-1 (unit) | `bunx vitest run test/host.test.tsx`: chip and actions per row (spots left, sold out, no bookings yet, mark attendance, {n} attended), Upcoming / Past tabs, empty state | 2026-11-04 | Pass | FR-032 |
| V-HOST-2 (unit) | Same file: zone-to-ISO with DST (Nairobi, London summer and winter, New York), price in minor units, every copy-deck error and the summary count, meeting point `maxlength` 140, capacity ≥ 1; empty Publish shows "6 things need fixing"; a complete form publishes the right body and goes to the published state; the price label follows the community | 2026-11-04 | Pass | FR-033 |
| V-HOST-3 (unit) | Same file: after a booking, lock banner, read-only date, time, zone and price, location block, capacity floor; PATCH sends only changed fields; `location_locked` and `capacity_below_bookings` inline with a refresh; published banner links | 2026-11-04 | Pass | FR-034 |
| V-HOST-1…3, V-PH-2 (manual, desktop) | Chrome on `next dev` against local Compose, signed in as a new test host: H3 empty state; H2 empty Publish → summary and field errors; filled with a generated 2400×1600 JPEG (encoded and uploaded through the real path: `-640` WebP 3.1 kB served from `/photos/` through the dev rewrite), dropped a pin without a place, typed venue and address; preview followed the form; Publish → "Published. … is live in Explore Kenya." with both links; a second test user booked through the API; edit showed the lock banner ("1 person is going"), read-only date, time and zone, the location block with meeting point and directions; capacity 0 → "1 booked, so at least 1." and the summary; 12 → "Changes saved", API capacity 12, preview 11 left; H3 table row "1 of 12", "11 spots left", Attendance and Edit; the other user's edit URL → 404 and their PATCH → 403; no console errors | 2026-11-04 | Pass. Phone widths wait for T15; Places search on H2 was checked in T10 | FR-013, FR-017, FR-032–FR-034, SEC-006, SEC-008 |
| V-CI-1 (T13) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && bun run web:build`; `bun run contracts:openapi` | 2026-11-04 | Pass (web 200) | NFR-007 |

### Phase D checks (T14)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-ATT-1, V-ATT-2 (unit) | `bunx vitest run test/attendance.test.tsx` (14): source labels; groups by Plan with removed bookings excluded; search by name or ref with or without `VLO-`; order before and after the start; stats over confirmed bookings only; full names, refs, sources and no contacts; subscribes `activity:` and `host:`; an `attendance` event refetches and the new row is marked new ("Booked just now"); Remove only after confirmation (Keep and Escape cancel), then `POST /host/bookings/:id/removal` and the row shows removed with no actions; after the start, Attended then No-show (latest wins, "1 of 3 marked"), removed rows have no mark buttons; a failed mark reverts and explains; empty state with the closing time | 2026-11-04 | Pass | FR-035–FR-038, AC-008 (unit) |
| V-ATT-1, V-ATT-2, V-SEC-4 (manual, desktop) | Chrome on `next dev` against local Compose; seeded through the API a host, an upcoming activity and a started one (start moved one hour back in the database, as `seed-invites.ts` does), each with Tunde direct, Zainab by vouch, Kofi by public link and Omar direct. Signed in as another user, H1 is X4's not-found. As the host: four rows with full names, refs, "Direct" / "Via Tunde" / "Public link", groups "Tunde's group 3" and "Booked alone 1", stats "4 of 14", "2", "10"; two bookings made through the API while the page was open arrived at the top with the lime sweep and "Booked just now", spots 10 → 9 → 8, without a reload; Remove Zainab → dialog with the deck copy → confirm → row struck through and "Removed", spots 8 → 9, "Tunde's group 2", toast; started activity: banner, "Who came?", Attended then No-show on Kofi, after a reload "No-show" kept, "1 of 4 marked", "No-shows 1"; search "eb9j" leaves Omar only | 2026-11-04 | Pass. Found and fixed the `useLiveSpots` setState-in-render error (PLANNING change log). A hydration mismatch on the header's Live pill turned out to be stale server output in the long-running dev server, and went away once the module recompiled: the isolated server render and the fresh dev render both include the pill. Phone width not checked in the browser (the window would not resize below desktop); T15 | FR-035–FR-038, AC-008, SEC-008 |
| V-CI-1 (T14) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && bun run web:build` | 2026-11-04 | Pass (web 214) | NFR-007 |

### Phase E checks (T15–T16)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-RESP-1 | A throwaway headless-Chrome script (DevTools protocol, no dependencies, outside the repo) loads 19 pages at 360, 390, 768, 1024 and 1280 px with the right session cookie: X1 sign-in, home, C1, B1 (booker, signed out, host), B4, B2, B3, B3b, B6, P1, the S6 invite page, X4, H3, H2 create and edit, H1 before and after the start. It checks `scrollWidth <= innerWidth`, lists elements past the right edge and content cut off inside clipping or scrolling boxes, and saves a full-page screenshot of each (95) | 2026-11-04 | Pass after two fixes: H3's table scrolled its actions out of view at 768 px (now cards below 1024 px), and B1 showed the spots badge twice on phone (PLANNING change log). No page overflows at any width. The only remaining "clipped" boxes are the community map's marker pane inside the map (by design) and screen-reader-only text. Screenshots reviewed for H1 (360, 768), B4 (360), B1 (360), H2 edit (360), H3 (768, 1024), C1 (768) | NFR-001 (layout), AC-007 |
| V-A11Y-1 | — | — | Not run: the owner dropped the accessibility pass from S5 (PLANNING change log); S9's audit covers it | — |
| V-DEP-1 | `curl` on the deployed stack (commit `ba41147`, T13): `/`, a `/_next/static/` chunk twice, `/api/healthz` | 2026-11-04 | Pass: `/` → `307` to `/communities/explore-kenya`, which answers `200`; the chunk is `public, max-age=31536000, immutable`, `x-cache: Miss` then `Hit`; healthz `{"status":"ok"}` | FR-039, FR-040 |
| V-SEC-3 (deployed) | Response headers on the deployed pages | 2026-11-04 | Pass: CSP (no `unsafe-eval` in production), `Referrer-Policy`, `nosniff`, `Permissions-Policy`. The key restrictions were set and checked in Google Cloud on 2026-11-04 (PLANNING change log, §12 Q2) | SEC-004 |
| V-SEC-1 | Local seed: HTML of C1, B1 and P1 signed out and as a signed-in non-member, searched for the seeded full names; `GET /api/activities/:id` | 2026-11-04 | Pass: no full name in any page; the API returns only `shortName` ("Tunde A.") | SEC-001 |
| V-CI-1 (T15) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && bun run web:build` | 2026-11-04 | Pass (web 214) | NFR-007 |

### Deployed checks (T16, commit `f43f4bf`)

Run on 2026-11-04 against `https://depimls1pcvv4.cloudfront.net`, after CI and Deploy passed on `f43f4bf` (Deploy run `41894185587`). The owner signed in as host in Chrome; Claude drove the browser. The second users ("E2E Guest One", "E2E Guest Two", "E2E Friend", `@example.com` contacts) were created through the public API with `curl`. Every row created is titled or named "E2E" (list below).

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| Deploy state | SSM on the instance: `docker ps`; `GetBucketCors` on the photos bucket; `DescribeStacks` | 2026-11-04 | `velio-web` and `velio-api` both `f43f4bf…`, healthy; photos bucket CORS is `POST` from the `cloudfront.net` origin only; `VelioApp` `UPDATE_COMPLETE` | FR-039, FR-041 |
| V-DEP-3 (deployed) | SSM: `curl` the web origin `127.0.0.1:3000/communities/explore-kenya` without `X-Origin-Verify`, and `/healthz` | 2026-11-04 | Pass: `403` without the header, healthz `200` | SEC-002 |
| V-DEP-4 | SSM: `docker stats --no-stream`, `free -m` | 2026-11-04 | Pass (idle, just before the E2E run): web 78.8 MiB of 512 MiB, API 74 MiB, collector 88 MiB, Postgres 86 MiB; 936 MB available of 1840 MB, no swap. The during-run snapshot wasn't taken (the AWS tool disconnected after the run) | NFR-008 |
| V-E2E-1 | Chrome, desktop: H2 create "E2E Sunset walk": Places (New) search "Karura Forest" with the deployed key, picked a suggestion (pin on the live map), zone Africa/Nairobi, a generated 2400×1600 JPEG put into the photo input → browser-encoded WebP posted to S3 → Publish → published banner. H1 open; "E2E Guest One" booked through the API → row arrived live with the sweep and "Booked just now", spots 3 → 2 → Remove → dialog → confirm → struck through, "Removed", spots 2 → 3, toast. Marking: an activity ("E2E Marking check") created through the API to start 5 minutes later, both guests booked; H1 left open switched to "Who came?" at the start time without a reload; Attended / No-show / Attended / No-show clicks; after a reload, "Attended" and "No-show" kept, "2 of 2 marked", stats 1 and 1 | 2026-11-04 | Pass | FR-013, FR-015, FR-017, FR-033, FR-035–FR-038, AC-001, AC-008 |
| V-PH-2 (production) | The published photo's `photoUrl` fetched through CloudFront; C1 card | 2026-11-04 | Pass: `/photos/…webp` `200 image/webp`, 8.6 kB; shown on C1, H2 preview and H3 | FR-013, FR-015 |
| V-E2E-2 | Chrome, desktop: C1 Explore Kenya (list with the live map tiles, clusters, "3 left" marker) → "E2E Kayak trip" (hosted by Guest Two) B1: Live pill, signed static map, meeting point, directions → Book → B2 with `VLO-` ref and "3 spots left" → Vouch → B3 name, contact (`example.com`), note → "Send it to …", code `4VGFYR`; WhatsApp and SMS links don't contain the contact → B4 shows the invite "Created" → claimed through the API as "E2E Friend" → B4 updated within ~2 s, no reload: member "Via Abdulbasit", invite "Claimed", 2 people, "Last 2 spots". Sold out: "E2E Last spot" (1 spot) open on B1, Guest One booked it through the API → within 2 s "Sold out" badge, disabled button, dimmed photo, the host's other dates and "More in Explore Kenya" | 2026-11-04 | Pass, with defect D1 below. The sold-out state came through the live event, so B1's `sold_out` answer from the API (Book pressed after the spot went) is covered by the unit test only | FR-018, FR-020, FR-022–FR-029, SEC-002, AC-002, AC-004 |
| V-RT (deployed) | Timing of the live changes above against the 10 s poll | 2026-11-04 | Pass: every change appeared in ≤ 3 s with the Live pill on, which the 10 s poll can't do, so the WebSocket path through CloudFront works | FR-009 |
| V-DEP-2 | In the signed-in tab, `fetch('/plans/<id>')`; `curl` of the same URL with no cookie | 2026-11-04 | Pass: signed in, `200` with the ref and the members in the server HTML, `cache-control: private, no-cache, no-store…`, `x-cache: Miss`; signed out, `307` to `/signin?next=…`, no plan data | FR-039, SEC-001 |
| V-SEC-3 (deployed, again) | `curl -I` on C1 | 2026-11-04 | Pass: CSP as in production (no `unsafe-eval`); no CSP errors in the console on C1 | SEC-004 |

**Defects found in T16** (fixed 2026-11-04 on the owner's go-ahead; deployed in `90c8ca2` and checked):

- **D1.** B1's "Be the first to book" stays on an activity that sold out live: the avatar line comes from the server snapshot's members, and a `spots` event updates only the count. A reload shows the booker. Cosmetic; spots, badge and button are right. **Fixed:** B1 refetches the snapshot's members after a live spots change (random 0–2 s delay, a newer version cancels the pending fetch, a resync updates them too); a later server refresh replaces them.
- **D2.** Cards (C1, H3, B6) load the 1280 px photo variant. `Photo` is given `photoUrl` only and never the 640 px variant, so a small card downloads the large file. Affects NFR-004's weight on phones, not correctness. **Fixed:** `Photo` adds `srcset` with the `-640` variant (the API's `smallVariantKey` rule) for uploaded photos, `sizes="320px"` on cards and `(min-width: 768px) 60vw, 100vw` on the hero. The live E2E photo's `-640.webp` answers `200 image/webp` (3.8 kB vs 8.6 kB) through CloudFront.

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| D1, D2 unit | `test/booking.test.tsx` "a live spots change refetches who is going"; `test/components.test.tsx` "Photo (T16 D2)" | 2026-11-04 | Pass | FR-023, NFR-004 |
| V-CI-1 (D1, D2) | `bun run format:check && bun run lint && bun run typecheck && bun run web:test && bun run web:build` | 2026-11-04 | Pass (web 217) | NFR-007 |
| Deployed D1, D2 | Commit `90c8ca2` (CI and Deploy `41900983783` green). D1: "E2E Stack check" (1 spot, hosted by Guest Two) open in Chrome showing "Be the first to book"; Guest One booked it through the API. D2: `curl` of C1's HTML, and the image each card actually loaded in Chrome | 2026-11-04 | Pass. D1: within 4 s, no reload (one navigation entry), "Sold out" and "E2E O. is going", no "Be the first to book". D2: C1's HTML has `srcSet` with the `-640` variant and `sizes="320px"`, and both cards loaded `…-640.webp` | FR-023, NFR-004 |

**Test data left on the deployed stack:** activities "E2E Sunset walk", "E2E Marking check" (hosted by the owner's account), "E2E Kayak trip", "E2E Last spot" and "E2E Stack check" (hosted by E2E Guest Two); users "E2E Guest One", "E2E Guest Two", "E2E Friend"; their bookings, Plans and the vouch invite `4VGFYR`; one photo in the photos bucket.

### Deploy fix (T7)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-DEP-0 | `bun test infra/aws` (15); `bun run aws:diff -c alertEmail=…` against the live stack (change set) | 2026-11-04 | Pass. The diff adds only the 3000 rule, the Maps secret, photos CORS, the instance role policy and the CloudFront changes; no security group replacement, and the instance isn't touched | SEC-002 |
| Quota | Service Quotas request L-0EA8095F = 120, eu-west-2 (request `1bb59c48996b4b419a7c180a3ef0c7e1qtO3axB2`) | 2026-11-04 | Applied: `GetServiceQuota` returns 120 (the request record still showed `PENDING`) | — |

### Not run yet

Updated 2026-11-04 after T16. The items that waited for the push and deploy (V-E2E-1, V-E2E-2, V-DEP-2, V-DEP-3, V-DEP-4, production photo upload, V-PH-2 from CloudFront, the maps on the real deployed screens) ran in *Deployed checks (T16)* above.

- V-A11Y-1: dropped from S5 by the owner; S9's audit covers it.
- V-MAP-5 with Google blocked in the browser and V-MAP-6's network panel: not run on the deployed stack (the fallback is unit-tested and was checked locally in T10).
- V-OBS-1 collector inspection of web spans in Grafana Cloud: not run in T16.
- Phone widths on the deployed stack: not run (the browser window doesn't resize below desktop); V-RESP-1 covered them on the production build locally.
- V-DEP-4 during load: only the idle snapshot; S10's load-runner work (Phase 5) measures under load.

### Final validation status

**Passed with exceptions** (2026-11-04): every functional flow passes locally and on the deployed stack. Exceptions: V-A11Y-1 dropped by the owner; the not-run items above. D1 and D2 are fixed and checked on the deployed stack.
