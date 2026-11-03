Velio Group Bookings turns "we should do this together" into "we're booked". Hosts list activities with fixed spots, bookers reserve and invite friends into a shared Plan, and guests claim a spot from a link or a code. This system covers the web app (Next.js) and the Flutter app. Build every screen from these tokens and components; tokens feed `packages/design-tokens`, which generates Tailwind and Dart values.

## Principles

1. **The spots number is the hero.** Every screen that can book shows `SpotsBadge`. It flashes `lime` for 1.4 s when it changes (a fade under reduced motion) and never shows a stale number without the `stale` state.
2. **The inviter leads for vouches; social proof leads for public links.** Vouch: "Tunde wants you on…". Public: "Join the group going to…" with the community chip.
3. **Never promise a held spot.** Invites don't hold spots. Say "Spots aren't held. Claim while they last."
4. **Every failure has a next step.** Sold out, expired and removed states end in `NextSteps`.
5. **Minimal identity, honest disclosure.** The claim form asks for two fields and says exactly what the host sees.
6. **Phone first for guests, desktop first for hosts.** Both work at both sizes.

## Content

- **Voice:** plain, warm, specific. Second person ("You're in, Zainab."). Name people and places. No exclamation marks, no emoji.
- **Casing:** sentence case everywhere, including buttons and titles.
- **Buttons are verbs** naming the outcome: "Claim my spot", "Book a spot", "Share link", "Remove Imani". Loading states continue the verb: "Confirming…".
- **Errors say what happened and what to do:** "That code doesn't match an invite. Check the letters." Never "Something went wrong" alone.
- **Prices** always read "KES 3,500 · pay the host on the day". There is no checkout.
- **Times** show the activity's zone: "Sat 14 Dec, 17:30 Nairobi time".
- **Names by audience:** public surfaces use "Tunde A." only. Full names appear only inside a Plan (members) and to the host.
- **Canonical copy** lives in the UX spec's copy deck (`spec/2026-11-03_09-09_ux-design/PLANNING.md`). Add a string there before using it.

Examples from the copy deck:

| Moment | Copy |
| --- | --- |
| Vouch invite lead | "Tunde wants you on" |
| Public invite lead | "Join the group going to" |
| Claim help | "So you can find this booking again. We don't message you." |
| Disclosure (vouch) | "Amara (the host) will see your name and that Tunde invited you. Your phone or email stays private." |
| Sold out | "This one filled up before you got here." |
| Sold out mid-checkout | "Someone just took the last spot." / "We didn't book or charge you." |
| Booked prompt | "Who's coming with you?" |
| Location lock | "Date, time and place are locked now that people have booked." |

## Color

- Page ground is `cream`; cards, fields and sheets are `surface`.
- Text is `ink` (body) and `muted` (secondary). Never use the website's `#818181`; it fails contrast.
- `forest` is the brand ink: headings that need brand weight, chip text, the secondary button, the focus ring.
- `lime` is the action colour: primary button fill, the spots-changed flash, Claimed and Vouch chips. **Lime is never text and never a sole boundary on cream** (1.07:1).
- `danger` is for errors and destructive actions, always with words.
- `live` is only the small live dot.
- `sky`, `sun`, `lilac`, `peach` and `lime` are the avatar palette; `sky` also marks Opened and Public link, `sun` the meeting-point note.
- One light theme. A dark theme is out of scope for the MVP.

## Type

- `display` (40) is the activity title on invite and activity pages, once per screen. `title` (28) heads outcome screens ("You're in, Zainab."). `heading` (22) heads sections.
- `body` (15) for running text, `body-strong` for values, `caption` (13) for help and metadata, `button` (17 bold) for buttons, `code` (18 tracked) for invite codes and booking references.
- Families: the canvas uses Sora (display) and DM Sans (body) from Google Fonts as stand-ins. Production uses Satoshi for body text and Nohemi for display if its licence is confirmed, otherwise a free display face chosen in S5. Swap fonts only in tokens.
- Use tabular numbers wherever counts or references line up.

## Space, shape and elevation

- 4px grid: `space-1` … `space-10`. Phone gutter `space-5`, desktop gutter `space-10`, desktop content at most `content-max`.
- Radius by role: `radius-pill` for buttons, badges, chips and toggles; `radius-hero` for the activity hero and sheets; `radius-card` for cards, maps and dialogs; `radius-field` for inputs and panels; `radius-small` for thumbnails.
- Elevation is rare: `shadow-raised` for floating things (map summary card, toasts), `shadow-sheet` for sheets and dialogs. Cards sit flat on cream.
- Every control is at least `touch-min` (44px); primary buttons and fields are `button-height` (52px).

## Motion and states

- The only signature motion is the 1.4 s `lime` flash on a spots change and the live-dot pulse. Under `prefers-reduced-motion`, both become a fade or stop.
- Optimistic booking: the button goes straight to loading ("Confirming…"), and rolls back gently on `sold_out`.
- Focus: a solid 2px `forest` ring, 2px offset, on every interactive element (12.1:1 on cream).
- Loading uses `Skeleton` shaped like the content.

## Maps

- Every location surface uses `LocationBlock`: map, venue, address, optional meeting point, Get directions.
- Invite pages use a **static** map image, lazy-loaded below the fold, so the page still shows first content in 1.5 s on 3G. The activity page loads an interactive map on tap. Flutter uses the native interactive map.
- The address and Get directions always render, even when the map fails or the device is offline.
- The host sets the location with `LocationPicker`, which states that the pin is public.
- **The map art in this system is representative.** Production maps are Google Maps with Google's own attribution.

## Imagery

- Each activity has one host-uploaded photo. On the canvas, `PhotoArt` stands in with duotone landscapes in the palette. Never ship `PhotoArt`.
- People have no photos: `Avatar` shows initials.

## Iconography

- Line icons on a 24px grid, 1.75 stroke, round caps and joins, in `currentColor` (usually `forest`). Use `Icon` by name.
- Velio's own icon set was not available, so these were drawn for this system. Replace them if Velio supplies its set.
- No emoji in the interface.

## Brand marks

- No Velio logo files were supplied. The wordmark is "velio" set in the display face in `forest`. Replace it with the real mark when it is available.

## Accessibility

- WCAG 2.1 AA: 4.5:1 for text, 3:1 for large text, control boundaries and focus rings. Each colour token's note names the grounds it passes on.
- Live changes are announced politely, at most once every 5 s.
- Status is never colour alone: chips carry words, errors carry icons and text.
- Every map has an address in text beside it.
- Text scales with the system setting up to 200%: rows wrap and stack rather than truncate key information. Avatar initials and icons keep their size.
