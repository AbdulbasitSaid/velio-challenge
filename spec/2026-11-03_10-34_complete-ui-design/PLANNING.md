# Planning: Complete UI and UX design in Claude Design

- **Spec ID:** 2026-11-03_10-34_complete-ui-design
- **Created:** 2026-11-03 10:34 (local)
- **Status:** In review
- **Phase:** 0 (Decide and design), reworked on 2026-11-03
- **Extends:** `spec/2026-11-03_09-09_ux-design/` (principles, tokens, copy deck and decisions UX-1–UX-5 stay in force)
- **Depends on:** `Velio Group Bookings PRD.md`, `spec/2026-11-03_10-34_google-maps-locations/`

Claims are tagged **[Verified]**, **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The approved UX spec designed the riskiest flows only. Four artboards are clickable, seven screens are marked "wireframe needed", and several states are written down but not drawn. Google Maps now adds new screens and states. The product owner asked on 2026-11-03 for the **complete** UI and UX to be designed in Claude Design before any client work starts.

## 2. Context and current behavior

- [Verified] UX spec inventory: P (prototyped) G1–G6, B1–B4, H1; W (wireframe needed) G8, H2, H3, C1, P1, A1, X1; S (static spec only) G7, B5, X2. G3 lacks error states, B4 is partial.
- [Verified] The existing canvas ([artifact](https://claude.ai/artifact/NirxnmSocq3eaLLrAwxjBe), source in `spec/2026-11-03_09-09_ux-design/prototype/`) has no design system attached (`"designSystems": []` in `canvas.json`).
- [Verified] Tokens, contrast results and the copy deck are in the UX spec and remain normative.
- [Verified] The canvas loads only Google Fonts, so Sora and DM Sans stand in for Nohemi and Satoshi.

## 3. Product decisions (owner, 2026-11-03)

| # | Decision |
| --- | --- |
| UI-D1 | Build a Velio design system in Claude Design first, then design every screen and state, web and Flutter, at high fidelity, with the key flows clickable. |
| UI-D2 | "Wireframe" status is retired: every screen is designed at high fidelity. |
| UI-D3 | Add a **My plans** screen (B6): one list of a person's upcoming and past Plans with booking references, on web and Flutter. This is a new PRD requirement (§7.1). |
| UI-D4 | The existing canvas is archived as a reference at its current link. The design system and full design are new artifacts. |

## 4. Desired outcome

Two Claude Design artifacts that S5, S6 and S7 can build from without guessing:

1. **Velio design system:** tokens and every component, including map components.
2. **Velio Group Bookings design:** every screen in §5.3, in every listed state, at phone and desktop sizes for web and at phone size for Flutter, with clickable flows (§5.4).

## 5. Proposed solution

### 5.1 Process [Proposal]

1. Start from Claude Design's types (`Artifact` quickstart: design system with intent `other`, screens with intent `design`).
2. **Design system:** port the UX spec's tokens; build components (§5.2); review contrast.
3. **Screens:** build on the design system, flow by flow in risk order: guest → booker → host → community and maps → profile, sign-in, admin.
4. Owner reviews each flow on the canvas (comments on the artifact), and changes are folded in.
5. Record the artifact links in this spec, and copy the source into `prototype/` beside this spec, as the UX spec did.
6. Owner approves; Phase 0 exits.

### 5.2 Design system contents [Proposal]

- **Foundations:** colour, type scale, spacing, radius, elevation, motion (spots flash and reduced-motion fade), iconography, breakpoints (390 phone, 768 tablet, 1280 desktop), focus styles.
- **Components:**
  - Buttons (primary, secondary, destructive, loading, disabled); text fields; text areas with counters; selects; date and time picker; steppers (capacity); photo upload.
  - Spots badge (normal, just changed, last 2, sold out, stale); live connection pill (live, reconnecting, offline).
  - Avatars, avatar stack, source chips, invite status chips, community chip, booking reference.
  - Cards: activity card, detail rows, "You're in" hero, next-steps list, Plan member row, attendance row, community summary card.
  - Navigation: web header with Host / Booker role toggle, Flutter app bar, bottom sheet, share sheet trigger, toast, modal confirm, empty state, skeletons, error banner.
  - **Maps:** location block (static map, address, meeting point, directions), interactive map with marker, failed and offline placeholders, location picker (search field, results list, draggable pin, "pin is public" note), community map with markers, clusters and summary card.

### 5.3 Screen inventory (complete) [Proposal]

**W** = web, **F** = Flutter. "Both sizes" = phone (390) and desktop (1280).

| # | Screen | Surface | States to design |
| --- | --- | --- | --- |
| G1 | Invite: vouch | W both sizes, F | Available, live spot change, last 2, offline, loading skeleton; location block |
| G2 | Invite: public | W both sizes, F | As G1, with community chip and "Shared by" |
| G3 | Claim form | W, F | Empty, filled, submitting, validation error, `rate_limited`, server error |
| G4 | You're in | W, F | Success with haptic note, location block with directions |
| G5 | Sold out | W, F | With and without other dates or community picks |
| G6 | Expired | W, F | With and without next steps |
| G7 | Already claimed | W, F | Own device (shows booking), other device |
| G8 | Code entry | F | Empty, typing, invalid inline, rate-limited, loading |
| G9 | Invalid or unknown code (web link) | W | Not found, rate-limited |
| B1 | Activity page | W both sizes | Available, last spots, sold out, booking (optimistic), sold out mid-checkout, already booked, activity started, bookings paused; static and interactive map |
| B2 | Booked + invite prompt | W | Default |
| B3 | Vouch form | W (share sheet on mobile web) | Empty, filled, created (send through WhatsApp or SMS, copy) |
| B3b | Public share link | W | Created, copied, link paused |
| B4 | Plan | W both sizes, F | Members with sources, invite statuses (created, opened, claimed), removed by host, only me, location block |
| B5 | Server error on booking | W | Retry with the same idempotency key |
| B6 | My plans (UI-D3) | W both sizes, F | Upcoming and past sections, Plan card (activity, date, booking ref, member avatars, spots left), removed by host, empty, loading, offline (cached, Flutter) |
| H1 | Live attendance | W both sizes | Before start (remove), remove confirm, live arrival, after start (attended / no-show), empty, groups summary (UX-3) |
| H2 | Create and edit activity | W both sizes | Empty, filling, location picker (search, results, pin drag, pin without place, no results, maps unavailable), validation, preview card, published, locked fields after first booking |
| H3 | Host's activity list | W both sizes | Empty, upcoming, past, sold out |
| C1 | Community page | W both sizes | List, Map, map marker selected, cluster, empty, map failed |
| P1 | Profile page | W, F | Host with upcoming activities, guest with none |
| A1 | Admin metrics | W desktop | Goals, funnel by rail, K-factor, holdout split, oversell = 0 and > 0 |
| X1 | Sign in ("continue as") | W both sizes | Empty, filled, error |
| X2 | Live connection pill | All | Live, reconnecting, offline |
| X3 | App shell | W both sizes, F | Header with role toggle, Flutter app bar, toasts |
| X4 | Not found and generic error | W, F | 404, 500 |

### 5.4 Clickable flows [Proposal]

1. Guest, vouch rail: open link → claim → You're in → Plan → My plans (web phone and Flutter).
2. Guest, public rail: the same, plus the sold-out, expired and offline scenarios.
3. Guest, Flutter code entry: G8 → G1 → claim.
4. Booker: community map → activity → book → invite prompt → vouch → Plan; sold out mid-checkout.
5. Host: sign in → create activity with the location picker → publish → live attendance → remove → mark attendance.

## 6. Architectural considerations

- **Tokens** stay the single source for `packages/design-tokens` (UX FR-008); the design system must not introduce colours or sizes outside them without updating the token set in this spec.
- **Accessibility:** UX NFR-001–004 apply to every screen; maps follow Maps NFR-004.
- **Performance:** designs for G1 and G2 must fit the invite-page budget (no web fonts beyond the subset, hero image ≤ ~60 kB at mobile width, map below the fold).
- **Fidelity limits:** the canvas cannot load real Google Maps tiles or measure 3G performance. Maps use representative imagery; real rendering is verified in S5–S7.

## 7. Components and files affected

- New: two Claude Design artifacts; `spec/2026-11-03_10-34_complete-ui-design/prototype/` (source copy).
- Updated after approval: UX spec change log and inventory status (pointing here, old canvas marked archived per UI-D4); `ROADMAP.md` Phase 0 and Phase 4 gate.
- Updated after approval for B6: PRD (§7.1), MVP plan §4.8 (endpoint) and §7 (S5 and S7 scope).
- No application code.

### 7.1 Proposed PRD amendment for My plans (UI-D3, needs owner approval)

| ID | Requirement | Priority |
| --- | --- | --- |
| L2 | A signed-in person sees **My plans**: every Plan they belong to, split into upcoming and past, each with the activity, date, booking reference and members. Available on web and in the Flutter app. | P0 |

- **Proposed API:** `GET /me/plans`, returning Plan summaries for the session's user. Public-form names only on the card; full names inside the Plan (PRD Q12).
- **Limit:** identity is the lightweight "continue as" session (MVP plan §4.6). A guest on a new device sees their Plans only after continuing with the same email or phone; there is no verification in MVP (SEC-008 applies).
- **Flutter scope:** B6 extends the Flutter app beyond the claim flow (PRD M1). The offline cache (M2) covers the last loaded list.

## 8. Tasks

1. Owner approves this spec and the Google Maps spec.
2. Build the design system; owner review.
3. Build guest screens and flows; owner review.
4. Build booker screens and flows; owner review.
5. Build host screens including the picker; owner review.
6. Build C1, P1, X1–X4 and A1; owner review.
7. Contrast and inventory audit (VALIDATION.md); copy source into `prototype/`; record links.
8. Owner approval; update UX spec, ROADMAP and CHANGELOG.

## 9. Dependencies and prerequisites

- Claude Design (Artifact Design and Design System types) available on the owner's account [Assumption: confirmed when quickstart runs].
- Maps spec approved, so map screens are designed against agreed behavior.

## 10. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Design drifts from the PRD or copy deck | Copy deck stays canonical; each screen cites its PRD ID and copy keys |
| Design system diverges from code tokens | Tokens defined once here and in the UX spec; S5 and S7 generate from them |
| Scope creep into features the PRD lacks | Out-of-PRD screens are raised as questions, not designed silently (B6 was raised and approved as UI-D3) |
| Stand-in fonts mislead on metrics | Note on the canvas; final face chosen in S5 |
| A very large canvas is slow to review | Split screens into one artboard group per flow |

## 11. Alternatives considered

- **Extend the existing canvas only:** quicker, but without a design system components would be redrawn per screen. Rejected by the owner (UI-D1).
- **Design in Figma:** not requested; Claude Design keeps the prototype linked to these specs.

## 12. Assumptions and open questions

- ~~**OQ-1:** Should a screen list all of a person's Plans?~~ Resolved 2026-11-03: yes, B6 (UI-D3), pending the PRD amendment in §7.1.
- ~~**OQ-2:** Archive or replace the existing canvas?~~ Resolved 2026-11-03: archive (UI-D4).
- [Assumption] Tablet (768) needs no separate designs; layouts are checked at that width only.

## 13. Estimated complexity

Large: about 26 screens, over 100 states, two artifacts, five clickable flows.

## 14. Related

- PRD: all user-facing requirements, Edge cases, Business rules.
- `spec/2026-11-03_09-09_ux-design/`, `spec/2026-11-03_10-34_google-maps-locations/`.

## 15. Change log

- 2026-11-03 10:34: created after the owner asked to rework Phase 0 and design the complete UI and UX in Claude Design. UI-D1 and UI-D2 decided by the owner in the same session.
- 2026-11-03: OQ-1 and OQ-2 answered by the owner. B6 My plans added (UI-D3) with a proposed PRD requirement L2 (§7.1); the old canvas is archived (UI-D4).
