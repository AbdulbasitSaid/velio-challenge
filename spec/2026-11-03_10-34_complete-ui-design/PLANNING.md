# Planning: Complete UI and UX design in Claude Design

- **Spec ID:** 2026-11-03_10-34_complete-ui-design
- **Created:** 2026-11-03 10:34 (local)
- **Status:** Implemented (2026-11-03). Approved by the owner; Phase 0 closed.
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
| UI-D5 | Responsive rules (§5.6) adopted by the owner on 2026-11-03: defined breakpoints, phone-first web screens become fluid with a centred column on wide screens, Flutter is phone-only portrait with text scaling up to 200%, admin is desktop-first. |

## 4. Desired outcome

Two Claude Design artifacts that S5, S6 and S7 can build from without guessing:

1. **Velio design system:** tokens and every component, including map components.
2. **Velio Group Bookings design:** every screen in §5.3, in every listed state, at phone and desktop sizes for web and at phone size for Flutter, with clickable flows (§5.4).

### 4.1 Artifacts

| Deliverable | Link | Status |
| --- | --- | --- |
| Velio design system | [claude.ai/artifact/HVyi155enP8ug5BVzdg8qz](https://claude.ai/artifact/HVyi155enP8ug5BVzdg8qz) (private) | Approved 2026-11-03. Source: `prototype/design-system/` |
| Archived first prototype | [claude.ai/artifact/NirxnmSocq3eaLLrAwxjBe](https://claude.ai/artifact/NirxnmSocq3eaLLrAwxjBe) | Retitled "(archived)" with a note linking the new artifacts (UI-D4, FR-012) |
| Velio Group Bookings screens | [claude.ai/artifact/9hFK2e2AhKVGMsrwPMei48](https://claude.ai/artifact/9hFK2e2AhKVGMsrwPMei48) (private) | Approved 2026-11-03: 42 artboards. Source: `prototype/screens-canvas/` |

Source copies are saved to `prototype/` when the owner approves (FR-010).

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

### 5.6 Responsive rules (UI-D5)

| Surface | Widths it must work at | Treatment |
| --- | --- | --- |
| Web: pages designed at both sizes (B1, B4, B6, C1, P1, X1, H1–H3, G1/G2 desktop) | 360 → 1440+ | Fluid. Content max `content-max` (1120px). Side-by-side columns stack below about 900px; grids use `auto-fit` with `min(…, 100%)`. Header nav hides below 720px. |
| Web: phone-first screens (G3–G7, G9, B2, B3, B3b, X4) | 360 → 1440+ | Fluid. Full-width header; content in a centred column of at most 480px. Shown on desktop in the "Guest and booking screens · desktop" frame. |
| Admin (A1) | 1024 → 1440+ designed; 768 usable | Desktop-first. Reflows without horizontal scroll down to 390px, but phone layout is not designed. |
| Flutter app | Phones 360 → 430 wide, portrait | Phone layouts only. Text scales up to 200% (system setting): content stacks or wraps, never truncates key information or overflows. Tablets show the phone layout centred; landscape is not designed. |

**Breakpoints:** 360 (small Android), 390 (design width), 768 (tablet), 1024, 1280 (design width), 1440.

### 5.5 Copy deck additions (FR-008)

New strings introduced by the designs. They extend the UX spec's copy deck and need the owner's approval with the batch that uses them. All batch strings (1–5) approved 2026-11-03.

| Key | Copy | Screen |
| --- | --- | --- |
| claim.title | "Claim your spot" | G3 |
| claim.nameHelp | "The host and the people in your group see this." | G3 |
| claim.contactError | "Enter a full phone number with country code, or an email address." | G3 |
| claim.rateLimited | "Too many attempts from this device." / "Try again in an hour. Your invite still works." | G3, G8, G9 |
| booking.retry | "Try again. You won't be booked twice." (button: "Try again") | G3, B5 |
| claim.returning | "Claiming as {Name}" / "{masked contact} · saved on this phone" / "Not you?" | G3 (Flutter) |
| offline.cached | "Showing the saved invite. Reconnect to claim." / "Showing your saved plans." | G1, B6 (Flutter) |
| soldout.nextHeading | "What you can do" | G5 |
| next.tellInviter | "Tell {Inviter}" / "Let them know it filled up" | G5 |
| expired.body | "Bookings close at the start time. Here are a few ways to still get out together." | G6 |
| started.body | "Bookings closed at {time} {zone} time. {Host} has more coming up." | G6 |
| claimed.own | "You're already going, {FirstName}." / "You claimed this invite on this phone on {date}." | G7 |
| claimed.other | "A vouch invite is for one person. If it was meant for you, ask {Inviter} for a new one." | G7 |
| invalid.title | "We can't find that invite." / "The link may be cut short or mistyped. Check the code in the message you got and type it below." | G9 |
| code.title | "Got an invite code?" / "Type the 6 characters from the message your friend sent." | G8 |
| code.linkHint | "Got a link instead? Tap it and it opens straight in the app." | G8 |
| plan.removedBody | "Your spot was released. You can still book another date below." | B4 |
| myplans.empty | "No plans yet" / "When you book or claim a spot, your plan shows up here." | B6 |
| myplans.otherDevice | "On another phone, continue with the same number to see these." | B6 |
| youreIn.ref | "Show this to {Host} when you arrive." | G4 |
| *Batch 2* | | |
| booking.cta | "Book a spot" / "Booking…" | B1 |
| booking.noPayment | "Pay the host on the day. Velio doesn't take payment." | B1 |
| booking.paused | "Bookings are paused for this activity." / "Nothing has changed for people already going. Check back soon." | B1 |
| booking.closed | "Bookings closed" (disabled button) | B1 |
| booked.lead | "You're going to" | B2, B4 |
| booked.goToPlan | "Go to my plan" | B2 |
| share.cardHelp | "For a group chat or a community thread. Anyone with it can claim a spot while spots last." | B2, B3b |
| vouch.contactHelp | "Used only to send and match this invite. {Host} never sees it." | B3 |
| vouch.nameError | "Add their name, so the invite is addressed to them." | B3 |
| vouch.notePlaceholder | "A line from you, shown on their invite" | B3 |
| vouch.cta | "Create invite" / "Creating…" | B3 |
| vouch.noHold | "Invites don't hold a spot. {n} spots left right now." | B3 |
| vouch.sendTitle | "Send it to {Name}" / "Your invite is ready. Send it however you usually talk." | B3 |
| vouch.message | "{Name}, I'm going to {Activity} on {date} and want you there. Claim your spot: {link}" | B3 |
| vouch.sendActions | "Send on WhatsApp" / "Send by text message" / "Copy link" | B3 |
| vouch.codeHelp | "Works once, until the activity starts" | B3 |
| vouch.next | "You'll see \"Opened\" in your plan when {Name} opens it, and \"Claimed\" once the spot is taken." | B3 |
| share.title | "Share a link" / "Anyone with this link can claim a spot while spots last." | B3b |
| share.paused | "This link is paused." / "We paused it while we check unusual activity. Bookings already made are safe. Vouch invites still work." | B3b |
| share.copied | "Link copied" | B3b |
| *Batch 3* | | |
| host.photoEmpty | "Add one photo" / "It leads your activity page and every invite link." / error "Add a photo. It shows on the activity page and every invite." | H2 |
| host.titleError | "Add a title." | H2 |
| host.dateError | "Pick a date in the future." | H2 |
| host.zoneHelp | "Guests see times in this zone" | H2 |
| host.priceHelp | "Guests pay you on the day. Velio takes no payment." | H2 |
| host.spotsHelp | "You can add spots later, never fewer than people booked." / locked: "{n} booked, so at least {n}. You can always add more." | H2 |
| host.validationSummary | "{n} things need fixing before you can publish." / "They're marked below." | H2 |
| host.lockWarning | "Once someone books, date, time and place lock. Check them before you publish." | H2 |
| host.lockedEditable | "You can still change the title, description, photo and number of spots." | H2 |
| host.published | "Published. {Activity} is live in {Community}." / "Open live attendance" | H2 |
| host.emptyList | "No activities yet" / "Create your first activity. It gets a page in its community and links you can share." | H3 |
| host.markStatus | "Mark attendance" / "{n} attended" | H3 |
| host.marking | "The activity has started." / "Mark who came. It's how Velio counts the plans that actually happen." | H1 |
| host.groupsHelp | "People who came in through each other's invites. Useful for seating and boats." | H1 (UX-3) |
| host.noBookings | "No bookings yet" / "This page updates by itself the moment someone books." | H1 |
| host.findGuest | "Find a guest" / "Name or booking ref" | H1 (phone) |
| *Batches 4–5* | | |
| community.count | "{n} upcoming activities with spots" | C1 |
| community.mapHint | "Only activities with spots show. Sold-out and started ones leave the map." | C1 |
| community.empty | "Nothing coming up right now" / "Activities with spots show here as soon as a host publishes one." | C1 |
| community.mapFailedAction | "Show the list instead" | C1 |
| profile.upcoming | "Upcoming with {FirstName}" | P1 |
| profile.nothingHosted | "{FirstName} isn't hosting anything right now." | P1 |
| profile.privacy | "Profiles never show which activities someone has booked." | P1 |
| signin.title | "Continue to Velio" / "Your name and a phone number or email. No password." | X1 |
| signin.nameHelp | "Others see your first name and last initial." | X1 |
| signin.contactHelp | "Use the same one on every device to see your plans. We don't message you." | X1 |
| signin.error | "We couldn't sign you in." / "Check your connection and try again." | X1 |
| signin.pitch | "Book together. Go together." / "Hosts list activities with fixed spots. You book one, invite friends into your plan, and watch the spots fill live." | X1 desktop |
| error.notFound | "This page doesn't exist." / "The link may be old or mistyped. Your plans and invites are where you left them." | X4 |
| error.server | "Something went wrong on our side." / "It's not you. Try again in a moment." / "Reference {id}" | X4 |
| error.appUpdate | "This link needs a newer version of the app." / "Update Velio to open it, or open it in your browser now." | X4 (Flutter) |
| admin.oversell | "Oversold: {Activity}, {date} has {n} bookings for {capacity} spots." / "Pause bookings for this activity" | A1 |
| share.sourceHelp | "People who join from this link show as \"Public link\" in your plan." | B3b |

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
- ~~[Assumption] Tablet (768) needs no separate designs; layouts are checked at that width only.~~ Superseded by §5.6 (UI-D5).

## 13. Estimated complexity

Large: about 26 screens, over 100 states, two artifacts, five clickable flows.

## 14. Related

- PRD: all user-facing requirements, Edge cases, Business rules.
- `spec/2026-11-03_09-09_ux-design/`, `spec/2026-11-03_10-34_google-maps-locations/`.

## 15. Change log

- 2026-11-03 10:34: created after the owner asked to rework Phase 0 and design the complete UI and UX in Claude Design. UI-D1 and UI-D2 decided by the owner in the same session.
- 2026-11-03: OQ-1 and OQ-2 answered by the owner. B6 My plans added (UI-D3) with a proposed PRD requirement L2 (§7.1); the old canvas is archived (UI-D4).
- 2026-11-03: **approved by the product owner**, with PRD L2 and Q14. PRD and MVP plan updated. Building the artifacts in Claude Design awaits explicit authorization.
- 2026-11-03: implementation authorized by the owner. Task 2 done: Velio design system published (tokens from the UX spec, 29 components including MapView, LocationBlock, LocationPicker, CommunityMap and PlanCard, brand-book README, cover). Deviations: the design system is named "Velio"; component icons were drawn for the system because no Velio icon set was available (flagged in its README); the wordmark is set in type because no logo files were supplied.
- 2026-11-03: design system approved by the owner. Task 3 done: "Velio Group Bookings" canvas created with the design system installed and batch 1 published: 18 artboards covering G1–G9 on web phone, G1/G2 on desktop, the Flutter guest flow (G8, G1/G2, G3, G4, G5–G7 outcomes), and B4 Plan and B6 My plans on web and Flutter, where flow 1 ends. States are switched with each artboard's Tweaks. New copy strings listed in §5.5. Deviation: B4 and B6 were pulled forward from batch 2 so flow 1 is clickable end to end.
- 2026-11-03: batch 1 and its copy additions approved by the owner. Batch 2 (booker) started.
- 2026-11-03: batch 2 published: B1 activity page (phone, with all booking states and B5 server error as a state; desktop), B2 booked + invite prompt, B3 vouch form (empty, filled, validation, creating, created and send), B3b public share link (created, copied, paused), and desktop B4 Plan and B6 My plans. New copy in §5.5 under *Batch 2*. Deviation: B5 is a state of B1 rather than its own artboard.
- 2026-11-03: batch 2 and its copy additions approved by the owner. Batch 3 (host) started.
- 2026-11-03: batch 3 published: H2 create and edit activity (desktop and phone; empty, place search results, pin placed, no results, maps unavailable, validation errors, published, editing with locked fields), H3 host's activity list (desktop table, phone cards; upcoming, past, empty), H1 live attendance (desktop and phone; before start, live arrival, remove confirm, after start marking, no bookings). New copy in §5.5 under *Batch 3*. Drafts and duplicating activities were drafted and then removed because the PRD has neither. Addition for review: a guest search on phone attendance, for check-in by booking ref (UX-2).
- 2026-11-03: the owner asked to finish all remaining screens before one full review. Batches 4 and 5 published: C1 community page (phone: list, map, map with activity selected, map failed, empty; desktop: list beside map), P1 profile (web phone, desktop, Flutter; host with activities, nothing hosted), X1 sign in (phone and desktop; empty, filled, invalid contact, submitting, server error), X4 not found and server error (web; Flutter adds "link needs a newer app"), A1 admin metrics (five PRD goals with targets and status, funnel by rail, K-factor by rail, holdout split, guardrails; oversell alert state with the R1 pause action). X2 (live pill) and X3 (app shell, role toggle, app bar, toasts) are covered by the components used on every screen rather than their own artboards. Old prototype canvas labelled archived (FR-012). Contrast audit run (VALIDATION Part B). Batch 3 approval is folded into the owner's full review. Source copy to `prototype/` (FR-010) waits for final approval.
- 2026-11-03: the owner reported UI overflow. Root causes found with a local headless-Chrome harness that renders every artboard state with the real components: (1) full-width link buttons were 100% wide plus padding because components lacked border-box sizing; (2) `AttendanceRow` used a prop named `ref`, which React reserves, so attendance rows failed to render (renamed `bookingRef`); (3) the desktop header did not fit at phone width (nav now hides below 720px and the header wraps); (4) list rows squeezed names to nothing on phones (rows now wrap); (5) desktop grids used fixed column counts or minimums wider than a phone (now `auto-fit` with `min(…, 100%)`); (6) 13 frames were shorter than their content, so the canvas cropped them (frames resized, rows re-spaced). Design system republished (v5) and recopied into the canvas.
- 2026-11-03: the owner asked whether the designs are responsive and approved the proposed rules (UI-D5, §5.6, FR-013 to FR-016). Scope added: phone-first web screens made fluid with a centred column and a desktop frame for them; checks at 360px and with 200% text scaling.
- 2026-11-03: UI-D5 implemented. The 10 phone-first web screens are now fluid pages (full-width header, content in a centred 480px column) and a new desktop frame, "phone-first screens on desktop", shows each at 1280px through a screen picker. Flutter claim summary row now wraps at large text sizes. Design system rule added: text scales to 200% and rows wrap; avatar initials and icons keep their size. Results in VALIDATION Part B.
- 2026-11-03: **approved by the owner; Phase 0 closed.** Batches 3–5 and their copy approved with the whole design. Open calls settled as designed: the desktop sign-in headline and the guest search on phone attendance are kept. Source of both artifacts saved to `prototype/` (FR-010). Status: Implemented.
