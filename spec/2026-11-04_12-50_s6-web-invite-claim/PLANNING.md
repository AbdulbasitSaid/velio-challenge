# Planning: S6 Web invite and claim page

- **Spec ID:** 2026-11-04_12-50_s6-web-invite-claim
- **Created:** 2026-11-04 12:50 (local)
- **Status:** Approved for implementation
- **Phase:** 4, Clients (`ROADMAP.md`), alongside S5 and S7
- **Parent:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (approved), delivery step S6
- **Builds on:** S4 (invite view, opens, claims), S3 (snapshot, realtime), and **S5 Phase A** (`spec/2026-11-04_12-50_s5-web-host-booker/`, T1–T7: web app, tokens, components, API and realtime clients, device cookie, production wiring)
- **Design:** `spec/2026-11-03_10-34_complete-ui-design/` (G1–G7, G9 on web phone and desktop), UX spec copy deck, Maps spec FR-007, NFR-001, NFR-002
- **Feeds:** S7 (deep-link files carry the app's identifiers)

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The invite link is where the 25% open-to-claim goal is won or lost (PRD goals, Zainab and Kofi personas). Zainab taps Tunde's link on a bus on weak data, often without the app. Today `https://<distribution>.cloudfront.net/i/<code>` returns the API's `not_found`. There is no page, no link preview, no open beacon caller, no claim form, no deep-link association for the app, and no static map (the snapshot's `staticMapUrl` is always null).

## 2. Context and current behavior

- [Verified, S4 PLANNING §4.4–§4.7, `apps/api/src/modules/invites/routes.ts`] `GET /api/invites/:code` returns `InviteView` (status `claimable` | `claimed` | `expired` | `paused`, `pausedReason`, inviter as `PublicPerson`, note on vouches, `claimedByViewer`, the live activity snapshot). `POST /api/invites/:code/opens` needs `X-Device-Id` and returns `204`. `POST /api/invites/:code/claims` needs `Idempotency-Key`, takes `{ displayName, contact, country?, platform? }` without a session, issues the session cookie, and returns `201 { booking, activity, planId, user, token? }`.
- [Verified, S4 FR-010] Claim rejection order: `rate_limited` (device) → `invalid_code` → replay → `invite_expired` → `invite_paused` → vouch claimed (own: `200` with booking; other: `already_claimed`) → `rate_limited` (link) → `forbidden` (host) → `already_booked` → `booking_removed` → `bookings_paused` → `sold_out`.
- [Verified, S4 §4.4 and §4.7] Server-side rendering must forward the viewer's device ID and IP, because rate limits key on them; a locked-out device gets `429` for every code.
- [Verified, S3 PLANNING §12 Q1] Static Maps signing, its secret and the Google budget alert move to S6.
- [Verified, `packages/contracts/src/activities.ts`] `PublicLocation.staticMapUrl` is nullable; `directionsUrl` works today.
- [Verified, MVP plan §4.7, §4.10] Link format, Open Graph previews (bots get the preview and never run the beacon), performance budget: first content < 1.5 s on mid-range Android over 3G, claim-page JS ≤ 100 kB gzipped, hero ≤ ~60 kB at mobile width, fonts subset with swap, static map lazy below the fold with fixed dimensions, Lighthouse under slow 3G/4G and mid-tier device emulation.
- [Verified, S10 PLANNING §4] One hostname serves the app and `/.well-known/`; the default CloudFront behavior moves to the web app in S5 (T7).
- [Verified, UI design §5.5] Copy for every G-screen state (`claim.*`, `soldout.*`, `next.tellInviter`, `expired.body`, `started.body`, `claimed.*`, `invalid.title`, `youreIn.ref`, `booking.retry`).

## 3. Desired outcome

- A link opens a server-rendered invite page that shows the inviter, the activity, who's going, live spots and the location, within the 3G budget.
- Link previews in WhatsApp, iMessage and others show the photo and "{Inviter} wants you on {Activity}", without counting as opens.
- One tap leads to a two-field claim (or none, for a signed-in guest), and a "You're in" screen with the booking reference and directions.
- Every outcome (sold out, expired, started, already claimed, invalid, rate-limited, paused, server error) ends with a next step.
- When the Flutter app is installed, the same link opens it (association files); otherwise this page is the full flow.
- Static map images are signed by the API and shown wherever the snapshot is used.

## 4. Proposed solution

### 4.1 Route and rendering [Proposal]

`apps/web/app/i/[code]/page.tsx`, a dynamic server component (`no-store`):

1. Normalise the code like the API (trim, drop spaces and hyphens, upper-case). If the path differs, `308` redirect to the canonical `/i/<CODE>` so shared links look the same.
2. Fetch `GET /api/invites/:code` on the internal network with the viewer's `Cookie`, `X-Device-Id` (S5 device cookie; minted by middleware on first visit, so first-time guests have one before SSR), `X-Forwarded-For` and `X-Origin-Verify`.
3. Choose the screen from the response (§4.3) and render it as HTML with critical CSS; hydrate only the small client islands (live spots, claim form, beacon, share buttons).
4. Response status: `200` for any invite state, `404` for `invalid_code`, `429` for `rate_limited` (so bots and caches treat them right) [Proposal].

### 4.2 Open Graph and the beacon

- `generateMetadata` sets `og:title` "{Inviter short name} wants you on {Activity}" (vouch) or "Join the group going to {Activity}" (public) [Assumption: these follow the G1/G2 headings; copy deck check at implementation], `og:description` with date, zone and spots, `og:image` = the activity's 1280 px photo variant (S5), `og:url` canonical, `twitter:card` `summary_large_image`. Unknown codes get a neutral preview and `noindex`.
- All invite pages send `robots: noindex, nofollow` (codes are credentials) [Proposal].
- The **open beacon** is a client effect that runs after first paint (`requestAnimationFrame` inside `useEffect`), once per page load: `POST /api/invites/:code/opens` with `X-Device-Id` and `{ platform: 'web' }`. Bots fetching HTML never run it (PRD Scope challenge 2, R9). The API de-duplicates per device and skips Plan members.

### 4.3 Screen selection

| Condition (from `InviteView`) | Screen | Copy keys |
| --- | --- | --- |
| `invalid_code` / `rate_limited` from the API | **G9** not found (with a code field that navigates to `/i/<code>`) / rate-limited | `invalid.title`, `claim.rateLimited` |
| `status = claimed`, `claimedByViewer` | **G7** own: "You're already going" with their booking and a link to the Plan | `claimed.own` |
| `status = claimed`, not the viewer | **G7** other | `claimed.other` |
| `status = expired` (activity started) | **G6** started/expired with next steps | `expired.body`, `started.body` |
| `status = paused` | **G-paused** (§12 Q2) | proposed copy, needs approval |
| `activity.status = sold_out` | **G5** sold out with next steps | `soldout.nextHeading`, `next.tellInviter` |
| `activity.bookingsPaused` | G1/G2 with Claim disabled and `booking.paused` | `booking.paused` |
| `activity.viewer.booking` confirmed (already going, e.g. Tunde previewing) | G1/G2 with "You're already going" and a link to the Plan | PRD Edge cases (already booked) |
| `activity.viewer.isHost` | G1/G2 with a link to attendance instead of Claim | PRD Business rules |
| otherwise `claimable` | **G1** vouch (inviter lead, note) / **G2** public (community chip, "Shared by") | UX FR-004 |

Live changes move between G1/G2 and G5 without reload: a `spots` event to 0 shows G5; a freed spot shows G1/G2 again (PRD Lifecycles: sold out isn't an invite state).

**Next steps** (G5, G6): from `GET /api/activities/:id/next-steps`, fetched server-side with the invite. "Tell {Inviter}" opens the Web Share API or WhatsApp with a prefilled reply (§12 Q3); the host's other dates; "More in {Community}". Empty blocks are hidden (UX FR-007). G6 links to the inviter's profile (PRD Edge cases: expired).

### 4.4 Claim flow (G3 → G4)

- **G3** as a step on the same route (`/i/<code>/claim`) so Back works and the page stays light [Proposal]:
  - Signed out: display name and phone-or-email, with `claim.nameHelp`, the rail-specific disclosure (UX FR-006; D5: the host sees "via {Inviter}" or "Public link", never the note or contact), and the PRD privacy line. Country for phone numbers defaults from `Accept-Language`'s region, editable [Proposal].
  - Signed in: no fields; "Claim my spot" confirms as the session user (PRD Identity: a recognised guest skips the step). "Not you?" signs out and shows the fields.
  - One `Idempotency-Key` per attempt, kept in `sessionStorage` for the code so a reload during a slow claim retries with the same key (PRD Edge cases: server error) [Proposal].
  - States: empty, filled, submitting ("Confirming…"), validation (`claim.contactError`), `rate_limited`, server error with "Try again. You won't be booked twice."
- **Rejections** map per the S4 order: `sold_out` → G5; `invite_expired` → G6; `invite_paused` → G-paused; `already_claimed` → G7 other; `200` with the viewer's own booking → G4/G7 own; `already_booked` → "You're already going" with the Plan link; `booking_removed` → the B4 removed copy with next steps; `forbidden` (host) → attendance link; `bookings_paused` → paused state.
- **G4 You're in:** "You're in, {FirstName}." with the booking reference (`youreIn.ref`), activity summary, members (full names: the guest is now a member, PRD Q12), location block with the signed static map and "Get directions", "See the plan" (S5's B4), and "Invite a friend" when the Plan view says `canInvite`. Android Chrome gets a short `navigator.vibrate` on success where supported (PRD M3 is the app's; this is a progressive extra) [Proposal].

### 4.5 Live spots

The S5 realtime client subscribes to `activity:<id>` after hydration and applies the six rules. Until then the server-rendered count shows. The badge greys out while stale. On `navigator.onLine = false`, Claim is disabled with "Reconnect to claim" (PRD Edge cases: offline; claims are never queued).

### 4.6 Static map signing (API) [Proposal]

- In the snapshot module, `staticMapUrl` = Maps Static API URL for the activity's pin: fixed `size=600x300&scale=2`, `zoom=15`, one marker in a token colour, the server key, and `signature` = URL-safe base64 HMAC-SHA1 of the path and query with the URL-safe-base64-decoded signing secret (Google's documented scheme [Assumption: checked against Google's current docs and their published example at implementation]).
- Config `GOOGLE_MAPS_SERVER_KEY` and `GOOGLE_MAPS_SIGNING_SECRET`, both optional; when either is unset, `staticMapUrl` stays null (current behavior, A7).
- Production: a `velio/prod/google-maps` secret in Secrets Manager (CDK creates it empty; the owner puts the values, like the Grafana secret), written into the instance `.env` by the deploy script.
- The server key is restricted to the Maps Static API; the image is requested by the browser from Google directly.
- On the page: `<img>` with fixed `width`/`height`, `loading="lazy"`, `decoding="async"`, alt "Map showing {Venue}", below the fold, collapsing to the address block on error (Maps FR-012, NFR-002). No Maps JavaScript on any invite route (Maps FR-007, AC-004).

### 4.7 Deep-link association files [Proposal, values from S7]

Served by Next.js route handlers with `Content-Type: application/json`, no redirect, no auth, cache 1 hour:

- `/.well-known/apple-app-site-association`: `applinks.details[].appIDs = ["<TeamID>.<bundleId>"]`, `components = [{ "/": "/i/*" }]`.
- `/.well-known/assetlinks.json`: `delegate_permission/common.handle_all_urls` for the Android package with its release and debug signing SHA-256 fingerprints.
- Values come from config (`APPLE_APP_IDS`, `ANDROID_PACKAGE`, `ANDROID_CERT_SHA256`), so S7 fills them without a code change. With no values, the routes return `404` [Proposal].
- No origin-check exemption is needed: CloudFront adds `X-Origin-Verify` to every origin request, including those from Apple's and Google's fetchers.

### 4.8 Performance budget [Proposal]

| Item | Budget | How |
| --- | --- | --- |
| First content (FCP) | < 1.5 s, mid-range Android, 3G | SSR HTML; critical CSS inlined; no client fetch before paint |
| Claim-page JS | ≤ 100 kB gzipped (all JS loaded on `/i/[code]`) | Client islands only; no Maps JS; no date library (use `Intl`); measured from the build output and the network panel |
| Hero image | ≤ ~60 kB at mobile width | `srcset` with S5's 640 px and 1280 px WebP variants, `fetchpriority="high"` |
| Fonts | Latin subset, swap, at most two files preloaded | `next/font/local` (S5) |
| Layout shift | Fixed image and map dimensions | Fixed boxes |
| Map | Lazy, below the fold, no JS | §4.6 |

Verified with Lighthouse (mobile, simulated slow 4G/3G throttling and mid-tier CPU) on the deployed page, plus a WebPageTest-style manual check with DevTools "Slow 3G" and 4× CPU slowdown [Proposal]. If the shared layout from S5 pushes JS over budget, the invite route gets its own minimal layout without the app header's client code.

### 4.9 Tests [Proposal]

- **Vitest:** screen selection for every row of §4.3; claim rejection mapping; idempotency key persists across reload and is reused on retry; beacon fires once after paint and never during SSR; OG metadata for vouch, public and invalid; association route handlers with and without config.
- **`bun test` (API):** static map URL signing against Google's published example (key, secret, URL → signature); null when unconfigured; snapshot includes the signed URL.
- **Manual:** every G-state in Chrome at the five widths; preview fetch with `curl -A "WhatsApp/2.23"` shows OG tags and records no open (check `invite_opens`); Lighthouse; real-device WhatsApp link preview and claim on the owner's phone; App/Universal Link verification with S7 (Android `adb shell pm get-app-links`, Apple's CDN validator `https://app-site-association.cdn-apple.com/a/v1/<host>`).

## 5. Architectural considerations

- **Correctness:** claims go only through `POST /api/invites/:code/claims` (PRD I6); the page never infers success.
- **Security:** codes are credentials: `noindex`, no third-party scripts on invite routes, `Referrer-Policy: strict-origin-when-cross-origin` so the code doesn't leak to Google through the static map request's referrer path [Proposal: `no-referrer` on the map `<img>`]; the signing secret stays server-side; rate limits keyed on the forwarded device and IP.
- **Privacy:** only `PublicPerson` before the claim; the vouch note shows only on that vouch's page (S4); contact only in the POST body; the Google Maps privacy line near the map.
- **Performance:** §4.8.
- **Accessibility:** spots changes announced politely, at most once per 5 s; the claim form is labelled with errors tied to fields; focus moves to the outcome heading after claim.
- **Operations:** invite pages are uncached at CloudFront (default behavior) because they're live and personalised.

## 6. Components and files affected

| Path | Change |
| --- | --- |
| `apps/web/app/i/[code]/**` | Invite page, claim step, outcomes, metadata |
| `apps/web/app/.well-known/apple-app-site-association/route.ts`, `assetlinks.json/route.ts` | Association files |
| `apps/web/components/invite/*` | G-screen compositions from S5's components |
| `apps/api/src/modules/activities/snapshot.ts`, new `maps/static.ts` | Static map signing |
| `apps/api/src/config.ts`, `.env.example` | `GOOGLE_MAPS_SERVER_KEY`, `GOOGLE_MAPS_SIGNING_SECRET` |
| `apps/web` config, `.env.example` | `APPLE_APP_IDS`, `ANDROID_PACKAGE`, `ANDROID_CERT_SHA256` |
| `infra/aws/lib/app-stack.ts`, deploy script | `velio/prod/google-maps` secret and its `.env` lines |
| `infra/docker-compose.prod.yml` | New env on `api` and `web` |
| Tests under `apps/web/test/invite/`, `apps/api/test/maps/` | New |
| `README.md`, `CHANGELOG.md`, `ROADMAP.md` | Docs |

No new npm dependencies expected [Proposal]: HMAC-SHA1 via `node:crypto`; everything else from S5.

## 7. Implementation phases and ordered tasks

| # | Task | Verified by |
| --- | --- | --- |
| T1 | Static map signing in the API, config, tests | V-MAP-1 |
| T2 | Google Maps secret in CDK and deploy script (owner fills it) | V-MAP-2 |
| T3 | `/i/[code]` SSR with forwarding, canonical redirect, status codes | V-SSR-1, V-SSR-2 |
| T4 | Screen selection and every outcome screen (G1, G2, G5, G6, G7, G9, paused) with next steps | V-STATE-1, V-NEXT-1 |
| T5 | OG metadata and the open beacon | V-OG-1, V-OPEN-1 |
| T6 | Live spots and offline handling | V-RT-1 |
| T7 | Claim step G3 and G4, rejection mapping, idempotency | V-CLM-1…3 |
| T8 | Association files | V-DL-1 |
| T9 | Performance pass and Lighthouse | V-PERF-1, V-PERF-2 |
| T10 | Accessibility and responsive pass | V-A11Y-1, V-RESP-1 |
| T11 | Deployed run, real-device preview and claim; with S7, link verification | V-E2E-1, V-DL-2 |
| T12 | Record Part B; CHANGELOG, ROADMAP | — |

## 8. Dependencies and prerequisites

- S5 Phase A (T1–T7) done.
- **Owner action:** Google Cloud project with Maps Static API enabled, a server key restricted to it, the URL-signing secret, and the $10 budget alert (MAP-D5, MAP-D6; shared with S5 §12 Q2). Without them `staticMapUrl` stays null and the address block shows (A7), so the page still ships.
- **From S7:** Android package name and signing certificate SHA-256 (S7 §12). There is no Apple Developer account (decided 2026-11-04), so `APPLE_APP_IDS` stays unset and the AASA route returns `404`; iOS links open this web page.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Budget missed because of shared layout JS | Dedicated minimal layout for `/i/*` if measurement says so (§4.8) |
| Link previews count as opens | Beacon only after paint in a real browser; API bot filter as backup (S4) |
| A guest on a shared NAT gets rate-limited by others' guesses | Limits key on device ID first; IP only when no device ID (S4); SSR always forwards the device cookie, which middleware mints before SSR |
| Preview bots or in-app browsers lack cookies, so each fetch has a new device ID | Only invalid codes count toward limits; valid invite fetches are free |
| WhatsApp in-app browser quirks (Web Share, `sms:`) | Copy link always available; tested on a real device |
| No Universal Links on iOS (no Apple developer account, decided 2026-11-04) | The web page is the full flow (MVP plan §8); iOS app users enter the code |
| Static map leaks the code via `Referer` to Google | `referrerpolicy="no-referrer"` on the image |
| Signing implementation wrong | Test against Google's published example |

## 10. Alternatives considered

- **Client-rendered invite page:** fails the 3G budget and link previews (MVP plan §5).
- **Claim as a modal on the same URL:** lighter navigation but breaks Back on Android and complicates focus; a sub-route is simpler.
- **Static map proxied through our API:** hides the viewer's IP from Google and allows caching, but puts image bytes through the API and may conflict with Google's terms on caching; not needed.
- **Interactive map on the invite page:** rejected by the Maps spec (no Maps JS on invite pages).

## 11. Estimated complexity

Medium: one route with nine outcome screens, a claim step, metadata, a beacon, association files, a signing function and a performance pass.

## 12. Assumptions and open questions

**Open questions** (each with a recommendation):

1. **Q1: Response status codes for G9.** **Answered 2026-11-04, as recommended:** `404` for unknown codes and `429` for rate-limited, `200` for every valid invite state, so previews and crawlers don't index dead links.
2. **Q2: Paused public link, seen by a guest.** The design has a paused state only for the link's owner (B3b, `share.paused`). The API returns `status: paused` and `invite_paused`. **Answered 2026-11-04, as recommended:** reuse the G6 layout with next steps and the approved copy: "This link is paused." / "{Inviter} can send you a new invite, or pick another date below." (adds `invite.paused` to the copy deck).
3. **Q3: "Tell {Inviter}" prefilled reply.** The deck has the button copy but no message text. **Answered 2026-11-04, copy approved:** "{Activity} on {date} filled up before I could claim. Let's find another date?" (adds `next.tellInviterMessage`).
4. **Q4: Signed-in claim without fields on web.** The returning-guest design ("Claiming as …") was drawn for Flutter. **Answered 2026-11-04, as recommended:** use the same pattern on web: name shown, no fields, "Not you?" to switch.

**Assumptions:**

- The OG titles mirror the G1/G2 headings already in the deck.
- CloudFront forwards `X-Forwarded-For` to the web origin as it does to the API (S4 assumption, same distribution).
- Apple's and Google's association fetchers accept a `200` JSON from the default behavior with no redirect.

## 13. Related specs and PRD sections

- PRD: M1 (web fallback), I3, I4, I6, A5, A7, Flows (Zainab, Kofi), Edge cases, Lifecycles (Invite), Business rules (Identity, names by audience), NFR Performance, Privacy, Accessibility, Scope challenge 2, R4, R7, R9, R10, D5, Q12.
- MVP plan §4.7, §4.10, §4.11, §7 (S6); Maps spec FR-007, FR-012, FR-015, NFR-001, NFR-002, AC-004; UI design G1–G9; UX FR-004, FR-006, FR-007.
- S4 §4.4–§4.7; S3 Q1; S5 Phase A; S7 deep links.

## 14. Change log

- 2026-11-04 12:50: created, together with S5 and S7.
- 2026-11-04: owner answers. No Apple Developer account: the AASA route ships but stays unconfigured (`404`); AC-005 and V-DL-2 cover Android only. Q1–Q4 accepted as recommended; `invite.paused` and `next.tellInviterMessage` copy approved. Google Cloud project to be created under the owner's Google account (S5 §12 Q2).
- 2026-11-04: approved by the owner.
- 2026-11-04: authorized for implementation by the owner, after S5 Phase A.
- 2026-11-04 (T9): the JS budget of 100 kB can't hold on a hydrated Next.js page: React DOM and the Next runtime alone are ~157 kB gzipped. Removing Zod from browser code (hand-checked error envelope and socket messages; a test keeps the code alphabet equal to the contracts) took the page from 232 kB to 199 kB. The owner chose to amend NFR-002 to ≤ 200 kB and judge the page by NFR-001 (first content < 1.5 s on 3G, Lighthouse on the deployed stack); the alternative was a plain-HTML invite page outside React.
- 2026-11-04 (T3–T8), implementation notes:
  - Status 429 for a rate-limited lookup isn't possible from an App Router page without a second API call in the proxy; that page answers 200 with `noindex` (FR-018 partly met: 404 and 308 are as specified).
  - G9 lives at `app/i/not-found.tsx` with `app/i/layout.tsx`: a segment's own not-found file didn't catch `notFound()` from its page in Next 16.
  - G4 "You're in" is its own route, `/i/<code>/in`, rendered from the Plan, so a reload shows the same screen. "Vouch for a friend" and "Share link" go to the Plan (B4, S5 T12) with `?invite=vouch|public`.
  - The signed-in web claim shows "Claiming as {Name}" without the masked contact: the web has no stored contact to mask (SEC: the API never returns it).
  - Static Maps signing was verified against Google's published URL-signing sample (secret `vNIXE0xscrmjlyV-12Nj_BvUPaw=` → `chaRF2hTJKOScPr-RQCEhZbSzIE=`), which reproduced exactly.
  - Seed script for every state: `bun apps/api/scripts/seed-invites.ts` (local only; uses the superuser connection for the two states the API refuses to create).

- 2026-11-04 (found in S5 T11): `apiFetch` without a schema returned `undefined` for JSON bodies, so the invite page's reconnect refresh and its live next-steps fetch got nothing (G5 reached live showed no suggestions; the server-rendered G5 was unaffected). Fixed in the shared client (S5 change log, T11) with a regression test in `test/invite-live.test.tsx`.
