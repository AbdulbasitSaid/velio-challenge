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

In progress. Phase A (T1–T7) and Phase B (T8–T10) recorded 2026-11-04; T11–T16 follow.

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

### Deploy fix (T7)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-DEP-0 | `bun test infra/aws` (15); `bun run aws:diff -c alertEmail=…` against the live stack (change set) | 2026-11-04 | Pass. The diff adds only the 3000 rule, the Maps secret, photos CORS, the instance role policy and the CloudFront changes; no security group replacement, and the instance isn't touched | SEC-002 |
| Quota | Service Quotas request L-0EA8095F = 120, eu-west-2 (request `1bb59c48996b4b419a7c180a3ef0c7e1qtO3axB2`) | 2026-11-04 | Applied: `GetServiceQuota` returns 120 (the request record still showed `PENDING`) | — |

### Not run yet

- V-MAP-2…6 on the real screens (B1, B4, C1 in T11–T12; H2 in T13), V-MAP-5 with Google blocked in the browser, V-MAP-6 network panel, and the deployed key's referrer restriction.
- V-PH-2 (needs H2, T13) and the dev `/photos` rewrite in a browser (with T13).
- Production photo uploads: need `bun run aws:deploy` (bucket CORS, instance role), after the push deploys the web container (the same order as V-DEP-1), then an upload through CloudFront. Until then the API starts normally and only uploads fail. Checked so far: `bash -n deploy.sh`, and `docker compose -f infra/docker-compose.prod.yml config` resolves `PHOTOS_BUCKET` and `S3_REGION` for the API.
- V-DEP-1, V-DEP-2, V-DEP-3 (deployed), V-OBS-1 (collector): need the commit pushed to `master` (the owner's git) and then `bun run aws:deploy` for the CloudFront and security-group change, in that order (the web container must be running before CloudFront's default behavior points at it).
