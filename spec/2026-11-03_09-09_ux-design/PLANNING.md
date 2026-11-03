# Planning: UX design for Group Bookings MVP

- **Spec ID:** 2026-11-03_09-09_ux-design
- **Created:** 2026-11-03 09:09 (local)
- **Status:** Approved (2026-11-03)
- **Prototype:** [Velio Group Bookings UX canvas](https://claude.ai/artifact/NirxnmSocq3eaLLrAwxjBe) (private; share from its page to show others). Source copy: `prototype/`.
- **Depends on:** `Velio Group Bookings PRD.md` (Business rules, Edge cases, Q8–Q12), `spec/2026-11-03_07-42_group-bookings-mvp-plan/`

## Problem statement

Delivery specs S5–S7 (web and Flutter) need screens, states, tokens and copy that the PRD only describes in words. This spec turns the PRD into a screen inventory, a design system and a clickable prototype of the riskiest flows. It runs in parallel with S1–S2, which need no UI.

## Context

- [Verified] Colours were read from velio.app's public stylesheets on 2026-11-03:
  - cream `#F5F3EC`, forest `#173600`, lime `#C8FC7C`, lime-press `#B8EC6C`;
  - mid-green `#97E565`, ink `#0A0A0A`, grey `#818181`, red `#F53333` and `#BE1E1E`, light blue `#EDF4FC`.
- [Verified] The site's fonts are Nohemi (display) and Satoshi (body), self-hosted.
- [Verified] Contrast checks (WCAG 2.1 formula):
  - forest on lime 11.3:1, forest on cream 12.1:1, ink on cream 17.8:1;
  - **the site's grey `#818181` on cream is 3.5:1, which fails body text**;
  - lime on cream is 1.07:1, so lime is never used as text or as a boundary on cream.
- [Decided] Fonts: Satoshi (free from Fontshare) in production; Nohemi only if a licence is confirmed, otherwise a free display face. The prototype uses Google Fonts stand-ins (Sora, DM Sans), because the canvas can only load Google Fonts.

## Design principles

1. **The spots number is the hero.** It appears on every screen that can book, changes visibly when it moves (a 1.4 s lime flash, or a fade when reduced motion is on), and is never shown stale without saying so ("Reconnecting…").
2. **The inviter leads for vouches; social proof leads for public links.** "Tunde wants you on…" versus "Join the group going to…" plus the community chip.
3. **Never promise a held spot.** The copy says "Spots aren't held. Claim while they last."
4. **Every failure has a next step.** Sold out and expired screens offer "Tell [inviter]", the host's other dates and "More in [community]".
5. **Minimal identity, honest disclosure.** Two fields at claim. The disclosure says exactly what the host sees.
6. **Phone first for guests, desktop first for hosts.** Both work at both sizes.

## Screen inventory

Status: **P** = in the clickable prototype · **W** = wireframe needed before S5–S7 · **S** = static spec in this document is enough.

| # | Screen | Surface | States | Status |
| --- | --- | --- | --- | --- |
| G1 | Invite: vouch | Web (SSR) + Flutter | Available, live spot change, offline, loading skeleton | P |
| G2 | Invite: public | Web (SSR) + Flutter | As G1, with community chip and "Shared by" | P |
| G3 | Claim form | Web + Flutter | Empty, filled, submitting, validation error, `rate_limited` | P (no error states yet) |
| G4 | You're in | Web + Flutter | Success, haptic | P |
| G5 | Sold out | Web + Flutter | With and without other dates or community picks | P |
| G6 | Expired | Web + Flutter | — | P |
| G7 | Already claimed | Web + Flutter | Own device (show booking) versus other device | S |
| G8 | Code entry | Flutter | Empty, typing, invalid (inline), rate-limited | W |
| B1 | Activity page | Web | Available, last spots, sold out, booking (optimistic), sold out mid-checkout, already booked | P |
| B2 | Booked + invite prompt | Web | — | P |
| B3 | Vouch form | Web (share sheet on mobile web) | — | P |
| B4 | Plan | Web + Flutter | Invite statuses, removed by host, empty | P (partial) |
| B5 | Server error on booking | Web | Retry with the same idempotency key | S |
| H1 | Live attendance | Web | Before start (remove), after start (attended / no-show), live arrival, remove confirm | P |
| H2 | Create and edit activity | Web | Empty, validation, preview card, locked fields after first booking | W |
| H3 | Host's activity list | Web | Empty, upcoming, past | W |
| C1 | Community page | Web | List, empty | W |
| P1 | Profile page | Web + Flutter | Host with activities, guest without | W |
| A1 | Admin metrics | Web | Goals, funnel by rail, holdout split | W (functional, low design priority) |
| X1 | Sign in ("continue as") | Web | — | W |
| X2 | Live connection pill | All | Live, Reconnecting, Offline | S |

## Components

These are defined on the canvas's *Tokens and components* artboard:
- **Buttons:** primary pill (default, pressed or loading, disabled); secondary outline pill; destructive text button.
- **Spots badge:** normal, just changed, last 2, sold out, stale.
- **People and status:** avatar and avatar stack (public form "First L."), invite status chips, source chips.
- **Inputs:** text field with error state.
- **Cards:** detail rows (date, place, price, host), the next-steps list, and the "You're in" hero card.

## Tokens (proposal for `packages/design-tokens`)

```json
{
  "color": {
    "cream": "#F5F3EC", "forest": "#173600", "lime": "#C8FC7C", "limePress": "#B8EC6C",
    "ink": "#0A0A0A", "muted": "#4A4A4A", "line": "#ECEAE2", "fieldBorder": "#8A8A8A",
    "danger": "#BE1E1E", "info": "#EDF4FC", "surface": "#FFFFFF", "live": "#2F8F00"
  },
  "avatar": ["#C8FC7C", "#CDE7FF", "#FFE58A", "#F2D4FF", "#FFD6BA"],
  "radius": { "pill": 999, "hero": 22, "card": 16, "field": 14 },
  "space": [4, 8, 12, 16, 20, 24, 32, 40],
  "type": {
    "display": { "family": "Nohemi|fallback", "size": 40, "weight": 700, "tracking": -0.02 },
    "title": { "size": 28 }, "heading": { "size": 22 }, "button": { "size": 17, "weight": 700 },
    "body": { "family": "Satoshi", "size": 15 }, "caption": { "size": 13 }
  },
  "motion": { "spotsFlashMs": 1400, "reducedMotion": "fade only" }
}
```

## Copy deck (canonical strings)

| Key | Copy |
| --- | --- |
| invite.vouch.lead | "{Inviter} wants you on" |
| invite.public.lead | "Join the group going to" |
| invite.noHold | "Spots aren't held. Claim while they last." |
| claim.cta | "Claim my spot" |
| claim.confirm | "Confirm my spot" / "Confirming…" |
| claim.contactHelp | "So you can find this booking again. We don't message you." |
| claim.disclosure.vouch | "{Host} (the host) will see your name and that {Inviter} invited you. Your phone or email stays private." |
| claim.disclosure.public | "{Host} (the host) will see your name and that you joined from a shared link. Your phone or email stays private." |
| success.title | "You're in, {FirstName}." |
| success.ref | "Booking ref {Ref}" |
| price.payment | "{Price} · pay the host on the day" |
| soldout.title | "This one filled up before you got here." |
| soldout.midCheckout | "Someone just took the last spot." / "We didn't book or charge you." |
| expired.title | "This invite expired when the activity started." |
| offline.banner | "You're offline · Last updated {n} min ago" / "Reconnect to claim" |
| booked.prompt | "Who's coming with you?" / "Only {n} spots left. Invites don't hold a spot, so tell friends now." |
| vouch.title | "Vouch for a friend" / "One invite, one person. It shows your name, so they know it's from you." |
| plan.createdHelp | "\"Created\" means the link exists; we can't see whether it was sent." |
| host.remove.confirm | "Remove {Name}? Their spot opens to whoever books next, and they'll see that you removed them." |
| host.privacy | "You see names and how people found you. Phone numbers, emails and invite notes stay private." |
| host.locked | "Date, time and place are locked now that people have booked." |

The remaining edge-case copy is in the PRD's Edge cases table, which stays normative.

## Decisions made in this design (for review)

| # | Decision | Why |
| --- | --- | --- |
| UX-1 | Price line reads "pay the host on the day" ✅ confirmed 2026-11-03 | Payments are a non-goal; without this, guests may expect a checkout. |
| UX-2 | A booking reference on the success card, Plan and host attendance ✅ confirmed 2026-11-03 | Gives Zainab something concrete to screenshot and Amara something to check people in by. Format `VLO-XXXXX` (MVP plan §4.3). |
| UX-3 | Host sees a "Groups" summary (Tunde's group: 4) | Supports PRD D5's reason (seating, boats); derived from Plans. |
| UX-4 | The claim form keeps the code visible in the header | Helps support conversations ("which code did you use?"). |
| UX-5 | Muted text uses `#4A4A4A`, not the site's `#818181` | `#818181` fails contrast. |

## Implementation notes for S5–S7

- The web invite page renders G1 and G2 on the server: no client JS is needed to see the activity, and the spots badge hydrates after load.
- Flutter mirrors the same tokens. Haptics: a light impact on claim success, a warning pattern on sold out.
- The avatar colour is `palette[hash(avatarSeed) % 5]`, and the TypeScript and Dart implementations must agree (FR-032).

## Risks

- **Fonts:** Nohemi's licence is unknown, so the display face may change. Tokens isolate this.
- **Prototype fidelity:** the canvas cannot test real 3G performance or deep links. Those stay with S6 and S7 (PERF-1, MAN-DL-1).

## Open questions

None. UX-1 and UX-2 were confirmed by the product owner on 2026-11-03.

## Change log

- 2026-11-03 09:09: created, with the prototype canvas (4 artboards).
- 2026-11-03: UX-1 (price line) and UX-2 (booking reference) confirmed. The reference was added to the MVP plan's data model and requirements, and the copy deck gained `price.payment` and `success.ref`.
- 2026-11-03: **approved by the product owner.** Remaining wireframes (G8, H2, H3, C1, P1, A1, X1) are still required before S5–S7.
- 2026-11-03: superseded for screens by `spec/2026-11-03_10-34_complete-ui-design/` (approved): every screen, including the former W items, new map states and My plans (B6), is designed at high fidelity in Claude Design. The "W" status is retired. This prototype canvas is archived as a reference. Principles, tokens, copy deck and UX-1–UX-5 still apply.
