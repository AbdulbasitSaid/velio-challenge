# Validation: S6 Web invite and claim page

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] Scope matches parent S6 (SSR `/i/[code]`, OG tags, deep-link files, claim flow, static location map, edge-case states, performance budget), plus Static Maps signing moved here by S3 Q1.
- [x] Budgets come from the PRD and MVP plan §4.10; none invented.
- [x] Open questions Q1–Q4 (PLANNING §12) answered; new copy (Q2, Q3) approved (2026-11-04).
- [ ] S5 Phase A done.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, SEC-005 | V-SSR-1 |
| FR-018 | V-SSR-2 |
| FR-002, FR-003, SEC-001 | V-STATE-1 |
| FR-004, AC-004 | V-RT-1 |
| FR-005, AC-002 | V-OPEN-1 |
| FR-006, SEC-003 | V-OG-1 |
| FR-007, SEC-006 | V-CLM-1 |
| FR-008 | V-CLM-2 |
| FR-009 | V-CLM-3 |
| FR-010 | V-CLM-1 |
| FR-011 | V-NEXT-1 |
| FR-012 | V-STATE-1 |
| FR-013 | V-RT-1 |
| FR-014, FR-015, AC-006 | V-MAP-3 |
| FR-016, SEC-004 | V-MAP-1, V-MAP-2 |
| FR-017, AC-005 | V-DL-1, V-DL-2 |
| NFR-001…004, AC-003 | V-PERF-1, V-PERF-2 |
| NFR-005 | V-A11Y-1 |
| NFR-006 | V-RESP-1 |
| NFR-007 | V-CI-1 |
| SEC-002 | V-SEC-1 |
| AC-001 | V-E2E-1 |

### Proposed checks

**Automated:**

| ID | Check | Expected |
| --- | --- | --- |
| V-CI-1 | `bun run lint && bun run typecheck && bun run format:check && bun run web:test && bun test` | Pass locally and in CI |
| V-MAP-1 | `bun test apps/api/test/maps`: signing matches Google's published example; null when unconfigured; snapshot carries the URL | Pass |
| V-SSR-1 | Vitest with a mocked API: SSR request carries cookie, `X-Device-Id`, `X-Forwarded-For`, `X-Origin-Verify`; lowercase path redirects `308` | Pass |
| V-SSR-2 | Route status: `404` invalid, `429` rate-limited, `200` for each valid state | Pass |
| V-STATE-1 (unit part) | Screen selection for every row of PLANNING §4.3 | Pass |
| V-OPEN-1 (unit part) | Beacon called once after paint; not during SSR; not on re-render | Pass |
| V-OG-1 | Metadata snapshot for vouch, public, invalid; `noindex` everywhere; map `<img>` has `referrerpolicy="no-referrer"` | Pass |
| V-CLM-2 | Key persisted in `sessionStorage` per code, reused on retry and reload, cleared on a final outcome | Pass |
| V-CLM-3 | Each claim error code maps to its screen | Pass |
| V-DL-1 | Association handlers: JSON content type, no redirect, values from config, `404` when unset | Pass |
| V-SEC-1 | Bundle and network inspection: contact only in the claim body; none in URLs or `sessionStorage` | Pass |

**Manual (Chrome; deployed stack; real phone):**

| ID | Procedure | Expected |
| --- | --- | --- |
| V-STATE-1 (manual part) | Seed invites for each state (claimable vouch and public, claimed by viewer and by other, expired, started, sold out, paused, bookings paused, viewer already going, viewer is host) and compare with the canvas at phone and desktop | Matches design |
| V-RT-1 | Two browsers on one invite; claim the last spot in one; then remove a booking via H1; then go offline in DevTools | G1→G5 live; G5→G1 when freed; offline disables Claim |
| V-OPEN-1 (manual part) | `curl -A "WhatsApp/2.23.20.0"` the page, then open in a browser twice; query `invite_opens` | OG tags returned; one row for the browser device only |
| V-CLM-1 | Claim signed out (vouch and public), signed in ("Claiming as"), "Not you?"; check G4 content, ref, directions, "See the plan" | As designed |
| V-NEXT-1 | G5 and G6 with and without host dates and community picks; "Tell {Inviter}" opens share or WhatsApp with the prefilled reply | Empty blocks hidden; share works |
| V-MAP-2 | With the secret in Secrets Manager, deploy and check `staticMapUrl` loads (HTTP 200 from Google) | Image renders |
| V-MAP-3 | Invite page network log: map image requested only after scrolling near it; no `maps.googleapis.com/maps/api/js`; block the image → address block | As designed |
| V-PERF-1 | Lighthouse CLI (pinned latest), mobile preset, simulated throttling, on the deployed G1 and G2, three runs, median | FCP < 1.5 s; record LCP, TBT, CLS |
| V-PERF-2 | Build output and network panel: total JS on `/i/[code]` gzipped; hero transfer size at 390 px | ≤ 100 kB; ≤ ~60 kB |
| V-A11Y-1 | Keyboard-only claim; screen reader (VoiceOver) on G1 spots change and G4 focus; axe or Lighthouse accessibility | No critical issues |
| V-RESP-1 | Five widths for every G-state; `scrollWidth <= innerWidth` | No overflow |
| V-E2E-1 | Real phone: owner sends a vouch link in WhatsApp; preview shows; tap; claim on mobile data; screenshot G4; Plan in S5 shows "Claimed" | Completes |
| V-DL-2 | With S7: `adb shell pm get-app-links <package>` shows `verified`; tapping a link on an Android device with the app opens the app | Verified (Android only) |

### Preconditions and test data

- Seed script producing one invite per state (PLANNING §4.3) on local Compose and, tagged for cleanup, on the deployed stack.
- Google server key and signing secret (or record fallback-only runs).
- A real Android or iOS phone with WhatsApp.

### Known limitations

- Real 3G conditions are approximated by Lighthouse throttling; the PRD target is checked on emulation, and RUM arrives in S8.
- No iOS Universal Links: there is no Apple Developer account (decided 2026-11-04).

## Part B: Executed checks

In progress (2026-11-04): T1–T10 done locally; T11 (deployed stack, real phone, App Links with S7) and the Lighthouse run wait for the deploy.

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-MAP-1 | `bun test apps/api/test/maps apps/api/test/activities/snapshot.test.ts` | 2026-11-04 | Pass. Signing reproduces Google's published sample signature exactly; null when either value is unset; the snapshot carries a signed, fixed-size URL when configured | FR-014–016 |
| V-SSR-1 | `test/ssr.test.ts`: SSR transport forwards cookie, `X-Device-Id`, `X-Forwarded-For`, `traceparent`, user agent and adds `X-Origin-Verify` | 2026-11-04 | Pass | FR-001, SEC-005 |
| V-SSR-2 | `curl` on local Compose + `web:dev` against the seed (`bun apps/api/scripts/seed-invites.ts`) | 2026-11-04 | Every valid state `200`; unknown code `404` (G9); lowercase path `308` to the canonical code. Rate-limited answers `200` + `noindex`, not `429` (PLANNING change log) | FR-018 (partly) |
| V-STATE-1 | Unit: `test/invite-screen.test.ts` (every §4.3 row, live switch). Manual: Chrome, each seeded state | 2026-11-04 | Pass. G1 vouch with note, G2 public, G5 with next steps and "Tell Tunde", G6 with the inviter's profile and next steps, G7 other, G7 own (after claiming), paused link (approved copy), bookings paused (disabled Claim with `booking.paused`), G9 with the code field | FR-002, FR-003, FR-012, SEC-001 |
| V-OPEN-1 | Unit: `test/invite-live.test.tsx` (once, after paint, not during render). Manual: `invite_opens` after visiting four seeded codes in Chrome and fetching all with `curl` | 2026-11-04 | Pass. One open for each code opened in the browser (one opened three times), none for a code only fetched with `curl` | FR-005, AC-002 |
| V-OG-1 | `test/ssr.test.ts` and `curl` on `/i/<code>` | 2026-11-04 | Pass: vouch and public titles, absolute `og:image` and `og:url`, `summary_large_image`, `noindex, nofollow` on every invite page; neutral metadata for unknown codes | FR-006, SEC-003 |
| V-RT-1 (unit) | `test/invite-live.test.tsx`: G1 → G5 on a `spots` event to 0, back to G1 on a freed spot; offline disables Claim ("Reconnect to claim") | 2026-11-04 | Pass. Two-browser run is with the deployed check | FR-004, FR-013 |
| V-CLM-1 (manual, local) | Chrome: claim as a signed-in guest ("Claiming as"), "Not you?" signs out and shows the fields, claim as a new guest | 2026-11-04 | Pass: G4 with booking ref `VLO-…`, members with "Via Tunde", "See the plan", invite buttons, location block; revisiting the invite shows G7 own | FR-007, FR-010, SEC-006 |
| V-CLM-2 | `test/claim.test.tsx`: one key per code, reused on retry and reload, cleared after a final outcome; contact never stored | 2026-11-04 | Pass | FR-008 |
| V-CLM-3 | `test/claim.test.tsx`: every claim error code mapped | 2026-11-04 | Pass | FR-009 |
| V-DL-1 | `test/app-links.test.ts` | 2026-11-04 | Pass: JSON, values from config, `404` when unset | FR-017 |
| V-PERF-2 (JS) | Production build, `next start`, gzip of every script on `/i/<code>` | 2026-11-04 | 232 kB → **199 kB** after removing Zod from browser code; ~157 kB is React DOM and the Next runtime. NFR-002 amended to ≤ 200 kB (owner). Hero size waits for S5's photo variants (T8) | NFR-002 |
| V-RESP-1 | Chrome: each invite route's server HTML laid out in a 360 px container; any element past 360 px reported | 2026-11-04 | Pass, no overflow on all nine routes. (DevTools device emulation wasn't available; headless Chrome's minimum window is 500 px) | NFR-006 |
| V-CI-1 | `bun run format:check && bun run lint && bun run typecheck && bun run web:test` (117) and `bun test` | 2026-11-04 | Pass, except the known macOS `somaxconn` race failures (3 of 265, 200-parallel tests; S4 Part B) | NFR-007 |
| V-MAP-2 (part) | The API's `staticMapUrl` signer with the values stored in `velio/prod/google-maps` (project `velio-maps-5eb36a`), fetched from Google; then the same URL with a wrong signature | 2026-11-04 | Pass: signed `200 image/png`; wrong signature `403`. The check on the deployed page follows the next deploy | FR-016, SEC-004 |

### Deployed checks (T11, commit `90c8ca2`)

Run 2026-11-04 against `https://depimls1pcvv4.cloudfront.net`. Test data was made through the public API by the S5 run's "E2E" users: activity "E2E Invite check" (3 spots, hosted by E2E Guest Two, booked by E2E Guest One) with public link `VVD5CQ` and vouch `K4B4AJ`; on "E2E Sunset walk" (with a photo), Guest Two's public link `U3K6CE` and vouch `J6SRZG`; a third user "E2E Guest Three". The owner's account was signed in to Chrome.

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-OG-1 (deployed) | `curl -A "WhatsApp/2.23.20.0"` on `/i/VVD5CQ`, `/i/K4B4AJ`, `/i/U3K6CE`; unknown code; lowercase code | 2026-11-04 | Pass: public and vouch titles ("Join the group going to …", "{Inviter} wants you on …"), description with the date, venue and live spots, absolute `og:url`, `noindex, nofollow`, `private, no-store`, CloudFront `Miss`. With a photo: absolute `og:image` (WebP, `200`) and `summary_large_image`; without one, `summary` and no image. `ZZZZZZ` → `404`; `vvd5cq` → `308` to `/i/VVD5CQ`. Risk for V-E2E-1: WhatsApp's support for WebP previews is uneven | FR-006, SEC-003 |
| V-OPEN-1 (deployed) | `/i/K4B4AJ` opened by full page loads in Chrome, the WhatsApp fetch above; then the Plan view as the inviter | 2026-11-04 | Pass, with finding F1: K4B4AJ shows `opened` with exactly 1 open (the browser device; the WhatsApp fetch isn't counted; reloads don't add). **F1:** the page's own beacon on a full page load gets **`503`** in the browser, three loads out of three, though the open is recorded. The same request from the page's console, a client-side remount, or `curl` gets `204`. The API returns `503` only from `/readyz`, so it's added between CloudFront and the browser. Not diagnosed: CloudFront and API logs were unreachable (the AWS tool disconnected). Users don't see it (the beacon ignores errors), but it adds 5xx at CloudFront | FR-005, AC-002 |
| V-MAP-2 (deployed) | Chrome network log on `/i/VVD5CQ` | 2026-11-04 | Pass: signed `maps/api/staticmap` (`600x300`, `scale=2`) `200` | FR-016, SEC-004 |
| V-MAP-3 (part) | Same log | 2026-11-04 | Pass in part: no `maps.googleapis.com/maps/api/js` on the invite page. "Loaded only near the scroll" not shown: in a 1440 px-tall window the map is in the first screen (top at 996 px) | FR-014, FR-015 |
| V-RT-1 (deployed) | `/i/VVD5CQ` open in Chrome (G2, 2 left); Guest Three claimed through the API; the host lowered capacity to 2 through the API; then removed Guest Three's booking | 2026-11-04 | Pass: 2 → "Last spot" live; G2 → G5 ("This one filled up before you got here.", "Tell E2E", the host's other dates, "More in Explore Kenya") live; G5 → G2 with Claim live, each within 3 s and no reload. Offline: unit test only (no DevTools offline). Finding D3 below | FR-004, FR-013 |
| V-CLM-1 (deployed, signed in) | Chrome as the owner: "Claim my spot" → "Claiming as …" with "Not you?" → "Confirm my spot" | 2026-11-04 | Pass: G4 "You're in, Abdulbasit.", `VLO-` ref, the group with "Via E2E", "See the plan", Vouch and Share link, the map, meeting point and directions; the claim key is gone from `sessionStorage`. Signed-out claim on the deployed stack not run (it creates an account; owner step) | FR-007, FR-008, FR-010 |
| V-PERF-1 | `npx lighthouse@13.6.0` (latest, published 2026-10-27), default mobile preset (412 px, DPR 1.75, simulated throttling), performance and accessibility, three runs each on G1 `/i/J6SRZG` and G2 `/i/U3K6CE` (signed out, the photo activity) | 2026-11-04 | Pass. Median G1: FCP 939 ms, LCP 1723 ms, TBT 24 ms, CLS 0.000, 300 kB total. G2: FCP 793 ms, LCP 1372 ms, TBT 20 ms, CLS 0.005, 389 kB. Performance and accessibility scores 1.00 on all six | NFR-001 |
| V-PERF-2 (deployed) | Lighthouse network items (G2 run 1); `curl` of a real photo's variants | 2026-11-04 | JS: 180 kB script transfer (≤ 200 kB, NFR-002 as amended): pass. Hero: the test photo (synthetic) is 8.9 kB, but a real upload on the stack (`c7f317a0…`) is 332 kB at 1280 px and 125 kB at 640 px; at DPR 1.75 a phone picks the 1280 px file. **Fails** the ~60 kB hero target for real photos (finding D4) | NFR-002 |

**Findings (open; owner to decide):**

- **F1.** Open beacon `503` on full page loads (V-OPEN-1 above). Needs CloudFront access logs or the API's logs for one of those requests.
- **D3.** G1/G2's "{Name} is going" line and avatar stack stay as the server rendered them: a live `spots` event changes only the count (`components/invite/invite-live.tsx`, `activity.members`). Same defect and fix as S5's D1.
- **D4.** Real photos are far over the invite hero budget: S5's browser encoder writes WebP at quality 0.8, which gives 332 kB / 125 kB for a real 1280 / 640 px photo. Options: lower quality, a smaller large variant, or a `sizes` that lets phones take 640 px. A design change to S5 §4.9 and S6's hero, so not changed here.

**Test data added on the deployed stack:** "E2E Invite check"; invites `VVD5CQ`, `K4B4AJ`, `U3K6CE`, `J6SRZG`; user "E2E Guest Three" and their removed booking; the owner's booking on "E2E Invite check"; Guest Two's booking on "E2E Sunset walk"; Lighthouse's six runs added opens to `J6SRZG` and `U3K6CE` (headless Chrome isn't filtered as a bot); four probe opens on `VVD5CQ`.

### Not run yet

Updated 2026-11-04 after the deployed run above.

- V-E2E-1: real phone with WhatsApp (owner).
- V-A11Y-1: VoiceOver on a phone (owner); Lighthouse accessibility scored 1.00 above, keyboard and axe not run on the deployed stack.
- V-DL-2: needs S7's Android app.
- V-CLM-1 signed out and "Not you?" on the deployed stack (creates an account: owner step); both passed locally.
- V-SEC-1 network inspection of a signed-out claim on the deployed stack (no contact is sent in a signed-in claim); passed locally.
- V-STATE-1 for every state on the deployed stack: G1, G2, G4 and G5 seen above; the rest passed locally.
- V-RESP-1 at five widths on the deployed stack: the invite pages rendered without overflow at 712 px; the 360 px check ran locally.

### Final validation status

**Not final** (2026-11-04): deployed checks pass except V-PERF-2's hero budget (D4); findings F1, D3, D4 open; the owner's real-phone checks (V-E2E-1, V-A11Y-1 VoiceOver) and V-DL-2 (S7) remain.
