# Requirements: S4 Invites, attribution and read APIs

## Purpose and scope

Vouch and public invites with codes and links, the public invite view, the open beacon, claims through the booking engine, attribution and trust edges, the per-activity hash chain and its audit function, device and per-link rate limits, public-link pause and auto-pause, the Plan view, and the read APIs the clients need: My plans, the host's activity list, attendance and marks, communities, profiles and next-steps (decided 2026-11-04, PLANNING §12, Q3). Parent IDs refer to `spec/2026-11-03_07-42_group-bookings-mvp-plan/REQUIREMENTS.md`. Design: `PLANNING.md` in this directory.

## Goals and non-goals

- **Goals:** a vouch is never claimed twice; the first claim sets a new guest's inviter and generation forever; attribution can't be changed without the audit detecting it; codes can't be guessed at scale; every funnel event the PRD lists for invites is recorded.
- **Non-goals:** screens and share sheets (S5, S6, S7); holdout and the `group_invites` flag (S8); the nightly audit job, rate-limit cleanup and admin pause endpoints (S8); photo upload (S5); Static Maps signing (S6); vouch holds (PRD X2); notifications sent by Velio.

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | `POST /api/plans/:id/invites` with `rail: 'vouch'` (`inviteeName` required, `contact`, `country` and `note` optional) creates a single-use vouch, by a confirmed member of the Plan only (`403 forbidden` otherwise, `404` for an unknown Plan), before the activity starts (`409 activity_started` after). There is no cap on vouches. | PRD I1, Business rules (Plans), Q3; parent FR-008 |
| FR-002 | `POST /api/plans/:id/invites` with `rail: 'public'` returns the caller's public link for that Plan, creating it on first use (`201`, then `200`). Same member and start-time rules as FR-001. | PRD I2; PLANNING §12, Q4; parent FR-009 |
| FR-003 | Every invite gets a unique code of 6 characters from `23456789ABCDEFGHJKMNPQRSTUVWXYZ`, retried on collision, and a link `PUBLIC_BASE_URL/i/<code>`. `expires_at` equals the activity's start time. | PRD I3; parent FR-010, FR-022 |
| FR-004 | Invite creation records an `invite_created` event and sends `notifyPlan`, in its transaction. | PRD Success metrics; S3 FR-009 |
| FR-005 | `GET /api/invites/:code` is public and returns `InviteView` (PLANNING §4.4): code, rail, `status` (`claimed` for a claimed vouch, else `expired` after start, else `paused`, else `claimable`), `pausedReason`, inviter as `PublicPerson`, note (vouch only), `claimedByViewer`, and the S3 activity snapshot. Code input is trimmed, stripped of spaces and hyphens, and upper-cased before lookup. Unknown → `404 invalid_code`. | PRD Flows, Lifecycles, Edge cases; MVP plan §4.8 |
| FR-006 | `POST /api/invites/:code/opens` (`X-Device-Id` required) records at most one open per invite per device and returns `204` for any known code. It records nothing for preview-bot user agents or for signed-in confirmed members of the invite's Plan. A new open records `invite_opened` and sends `notifyPlan`. Opens on sold-out or expired invites are recorded. | PRD Scope challenge 2, R9, Edge cases; parent FR-020; PLANNING §12, Q7 |
| FR-007 | `POST /api/invites/:code/claims` (`Idempotency-Key` required) books a spot through the S2 engine, joining the invite's Plan with `source` = the invite's rail, in one transaction with the `invite_claims` row (PRD I6). There is no other claim path. | PRD I6, B3; parent FR-006, FR-012 |
| FR-008 | Claim identity: a valid session wins; otherwise a user with the same contact hash is used and their display name kept; otherwise a new user is created inside the claim transaction with `invite_generation` = the inviter's generation + 1. A failed claim creates no user. | PRD I4, Scope challenge 5, Identity, R5; MVP plan §4.4 |
| FR-009 | A successful claim by a caller without a valid session issues a session in the same transaction: an httpOnly cookie for web callers, the token in the body for `X-Client: mobile`. | MVP plan §4.6; S1 SEC-002 |
| FR-010 | Claim rejections, in this order after validation: `rate_limited` (device), `invalid_code`, idempotent replay (`200`), `invite_expired` (activity started, including a start-time race inside the transaction), `invite_paused`, vouch already claimed (`200` with the caller's own booking if they claimed it, otherwise `409 already_claimed`), `rate_limited` (link), `forbidden` (host), `already_booked`, `booking_removed`, `bookings_paused`, `sold_out`. | PRD Edge cases; parent FR-012; PLANNING §4.6 [Proposal for the order] |
| FR-011 | A claim by a user created in that claim inserts one `attributions` row (invitee, inviter, invite, rail, generation, activity). No later claim changes it. A vouch claimed by an existing user inserts a `trust_edges` row instead. A public claim by an existing user writes neither. | PRD I4, D4; parent FR-011, AC-006 |
| FR-012 | Two or more parallel claims of one vouch produce exactly one booking; the others get `already_claimed` and take no spot. | PRD I6; parent AC-002 |
| FR-013 | A claim records `invite_claimed` (with `is_new_user`) and, inside the transaction, S2's `booking_succeeded`. A vouch whose stored contact hash differs from the claimer's records `vouch_contact_mismatch`; the claim still succeeds. | PRD Success metrics, Edge cases (wrong recipient) |
| FR-014 | The claim response is `201 { booking, activity, planId, user: MemberPerson, token? }`; a replay is `200` with the same shape. | PLANNING §4.6 |
| FR-015 | Every `invites` and `attributions` insert is assigned, by a database trigger under the activity row lock, a per-activity `chain_seq` (1, 2, …), `prev_hash` (32 zero bytes for the first) and `row_hash = sha256(prev_hash ‖ canonical row)`. Values supplied by the caller are overwritten. | PRD NFR Immutable attribution, R11; parent SEC-002 |
| FR-016 | `audit_chain(activity_id)` and `audit_all_chains()` recompute both chains and report, per table, the first `chain_seq` whose hash doesn't match or that follows a gap; a clean chain reports nothing. | PRD Operations (attribution audit); parent SEC-002 |
| FR-017 | More than 10 invalid codes from one device (by `X-Device-Id`, or by client IP when none is sent) within a fixed one-hour window → `429 rate_limited` for every code lookup from that key (view, open, claim) until the window ends. | PRD R10; parent SEC-005; UI copy `claim.rateLimited` |
| FR-018 | Claim attempts on one public link are limited to 60 per minute (`LINK_CLAIMS_PER_MINUTE`), and a public link is auto-paused (`paused_reason = 'auto'`) when its trailing 60 minutes hold at least 200 opens (`AUTO_PAUSE_MIN_OPENS`) and that window's claims ÷ opens < 2%. Both are config values. | PRD R7; parent SEC-006; user decision 2026-11-04 |
| FR-019 | `POST` and `DELETE /api/invites/:code/pause` pause and resume a public link, by its creator or the activity's host only (`403` otherwise). Pausing a vouch → `400 validation_failed`. Pause state is in `invite_controls` with `paused_by` and `paused_reason`, and sends `notifyPlan`. | PRD Operations, R7; parent FR-024 |
| FR-020 | `GET /api/plans/:id`, for users with a booking of any status in the Plan (`403` otherwise), returns `PlanView` (PLANNING §4.9): confirmed members with `MemberPerson`, source and inviter; the viewer's own booking and ref and `canInvite`; every Plan invite with status (`created`, `opened`, `claimed`, `expired`), counts and pause state, with `code`, `link` and `note` only on the viewer's own invites. A removed viewer gets no invites and `canInvite: false`. | PRD L1, Q12, D5; parent FR-007; PLANNING §12, Q3 |
| FR-021 | One forward-only migration adds the columns, constraints, triggers, functions and indexes in PLANNING §4.2. | PLANNING §4.2 |
| FR-022 | `GET /api/me/plans` returns the caller's Plans (bookings of any status) split into `upcoming` (soonest first) and `past` (most recent first), each with `planId`, `ActivityCard`, the caller's own booking (`id`, `ref`, `status`) and members (count and a `MemberPerson` preview). | PRD L2, Q14; parent FR-036 |
| FR-023 | `GET /api/host/activities` returns the caller's hosted activities split into `upcoming` and `past`, each `ActivityCard` plus `bookedCount`. | UI design H3; PRD W1 |
| FR-024 | `GET /api/host/activities/:id/attendance`, for the host only (`403` otherwise), lists confirmed and removed bookings in booking-time order with ref, status, `MemberPerson`, booking time, source, inviter (`MemberPerson` or null), Plan ID and the latest mark, plus the activity's capacity, spots left, version and whether it has started. No contacts, hashes or notes. | PRD H1, D5; parent FR-013 |
| FR-025 | `POST /api/host/bookings/:id/attendance` with `attended` or `no_show`, by the host only, after the start time (`409 activity_not_started` before), on a confirmed booking (`409 booking_removed` otherwise), inserts an `attendance_marks` row. The latest mark wins and earlier marks stay. It sends `notifyAttendance` (S3). | PRD H2; parent FR-015 |
| FR-026 | `GET /api/communities` lists every community (`slug`, `name`, `blurb`, `coverPhotoUrl`, `upcomingCount`). `GET /api/communities/:slug` returns the community and its upcoming activities as `ActivityCard`s with coordinates, soonest first, sold-out ones included, at most 100. Unknown slug → `404`. | PRD Q11, A6; parent FR-029 |
| FR-027 | `GET /api/users/:id/profile` returns `PublicPerson`, `memberSince` (month and year) and upcoming hosted activities as `ActivityCard`s, and never bookings or Plans. Unknown user → `404`. | PRD Q10; parent FR-031 |
| FR-028 | `GET /api/activities/:id/next-steps` returns `hostOtherDates` (the host's other upcoming activities with spots, soonest first, at most 3) and `moreInCommunity` (up to 3 upcoming activities with spots in the same community, soonest first, excluding this one). Unknown activity → `404`. | PRD Q9, Edge cases; parent FR-030 |
| FR-029 | `ActivityCard` is built by the S3 snapshot module and shows people only as `PublicPerson`. | PRD Q12; parent SEC-012 |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | With M = 200 new guests claiming one public link in parallel on an activity with N ∈ {1, 5, 14} spots, exactly N claims succeed, the rest get `sold_out`, there are N attribution rows with `chain_seq` 1…N and no gaps, and `audit_chain` is clean. Runs in `bun test`, so in CI. | PRD R1, I6; MVP plan §4.13 |
| NFR-002 | The claim transaction makes no network calls besides the database and keeps the S2 lock order (activity row first). | PRD R2; S2 NFR-003, NFR-004 |
| NFR-003 | Metrics `invites_created_total` (`rail`), `invite_opens_total` (`rail`, `outcome`), `rate_limited_total` (`scope`), `invite_auto_paused_total` and `vouch_contact_mismatch_total` exist with no other labels; claims use `booking_attempts_total{path="claim"}` with the claim outcome values. | MVP plan §4.12; CLAUDE.md |
| NFR-004 | Rate limits and pause state live in Postgres; there is no in-process or external counter. | MVP plan §4.2, §4.7 |
| NFR-005 | List endpoints (FR-022–FR-028) run a fixed number of queries regardless of how many rows they return (no per-row query). | PRD NFR performance [Proposal] |

## Use cases

- **Tunde vouches for Zainab** with her number and a note → a code and link; his Plan shows "Created", then "Opened", then "Claimed" live.
- **Zainab claims** as a new user → generation 1, attribution to Tunde on the vouch rail, signed in, in Tunde's Plan.
- **Zainab invites her own friend** → generation 2, filling Tunde's Plan (PRD Business rules).
- **Kofi claims Tunde's public link**, then later gets a vouch from Tunde for another activity → his attribution stays public-rail; the vouch writes a trust edge (D4).
- **Two friends tap the same vouch link at once** → one gets the spot, the other sees "This invite has already been claimed."
- **Someone guesses codes** → the 11th wrong code in an hour locks that device out, including valid codes, until the hour ends.
- **A public link lands in a spam channel** → opens spike with almost no claims and the link pauses itself; Tunde sees it paused and can resume it.
- **Amara checks in her group** on the morning of the walk: the attendance list shows names, refs and "via Tunde"; after the start she marks each person attended or no-show.
- **Zainab opens My plans** on a new phone after continuing with the same number and sees Tunde's Plan under Upcoming.

## Acceptance criteria

- **AC-001:** 20 parallel claims of one vouch by different users → one `201`, 19 `already_claimed`, `spots_left` down by 1 (parent AC-002).
- **AC-002:** a new guest claiming Tunde's vouch gets generation = Tunde's + 1; the same guest's later claim elsewhere leaves their attribution unchanged (parent AC-006).
- **AC-003:** NFR-001 passes for N ∈ {1, 5, 14}.
- **AC-004:** after tampering with an `attributions` row (trigger disabled by the owner in a test), `audit_chain` reports that row's `chain_seq`; after deleting one, it reports the gap.
- **AC-005:** `UPDATE` and `DELETE` on `invites`, `invite_claims`, `attributions` and `trust_edges` fail for `velio_api` (parent AC-007).
- **AC-006:** the 11th invalid code within an hour from one device returns `429`, and a valid code from that device is also refused until the window ends.
- **AC-007:** a beacon from a preview-bot user agent, and from the inviter's own session, records no open (parent AC-005, beacon part).
- **AC-008:** no response from the invite view, Plan view, claim, open or read endpoints contains a contact, contact hash or another member's booking ref, and the host is never shown a note.
- **AC-009:** a host marks an attendee no-show, then attended; the attendance list shows `attended`, both `attendance_marks` rows exist, and a mark before the start time is `409 activity_not_started`.
- **AC-010:** the profile and community endpoints return names only as `PublicPerson` and never a booking or Plan.

## Business rules and edge cases

- Invites don't hold spots (PRD D2); a sold-out invite stays viewable and becomes claimable again if a spot frees.
- Invites expire at activity start (PRD Lifecycles).
- A vouch is claimed at most once; a public link until start, sold out or pause.
- First claim sets inviter and generation forever (D4). An existing user claiming an invite keeps their generation and doesn't count as a new user.
- Any Plan member can invite; claims fill the Plan the invite came from, whoever created it.
- The wrong recipient can claim a vouch; the code is the credential (PRD Edge cases).
- A removed member can't create invites and sees no invites in the Plan.
- Attendance can be marked only after start and only on confirmed bookings; the latest mark wins (parent FR-015).
- "More in [community]" lists only activities with spots; the community page lists all upcoming activities, including sold-out ones, with their status.

## Error handling and failure behavior

- The S1 envelope for every error. Claim rejections roll back the whole transaction (spot, user, booking, claim, attribution, session, events).
- A new-user contact conflict inside the transaction retries once as the existing user; a second conflict is `internal`.
- Code collisions retry up to 5 times, then `internal`.
- The open beacon never fails the page: unknown code is the only error a client sees (plus `rate_limited`).
- A failed `booking_rejected` event write is logged and doesn't change the response (S2).

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | A vouch contact is stored only as `HMAC-SHA256(CONTACT_PEPPER, normalised)` in `invitee_contact_hash`; the raw value is stored nowhere. This is stricter than PRD Q7 (decided 2026-11-04, PLANNING §12, Q1). | PRD Privacy, Q7; parent SEC-004 |
| SEC-002 | Contacts and contact hashes never appear in a response, URL, log, span or metric. Notes appear only on the vouch invite view and to the invite's creator in the Plan view, never to the host. | PRD D5, Privacy; parent SEC-003, SEC-011 |
| SEC-003 | Public endpoints (invite view) return people only as `PublicPerson`; the Plan view returns `MemberPerson` only to Plan members. The invitee's name isn't returned by the public invite view. | PRD Q12; parent SEC-012 |
| SEC-004 | Codes never appear in metric labels, span attributes or log lines; logged paths stay redacted. Rate-limit keys store hashes of device IDs and IPs. | Parent SEC-011 |
| SEC-005 | Insert-only rules from S1 hold for every new column; triggers set chain values regardless of what the API sends. | Parent SEC-001, SEC-002 |
| SEC-007 | Host endpoints (activity list, attendance, marks) check that the caller hosts the activity; attendance never returns contacts, hashes or invite notes. | PRD D5, Identity; parent FR-016 |
| SEC-006 | Claim-time sign-in by contact is unverified, like `POST /api/sessions`, and is covered by parent SEC-008 (replace before GA). | Parent SEC-008 |

## Performance and reliability

NFR-001, NFR-002. The full `invite_claims` k6 scenario is S9.

## Compatibility constraints

- Contracts additions are backwards-compatible.
- New required config in production: `PUBLIC_BASE_URL`. New config with defaults: `LINK_CLAIMS_PER_MINUTE` (60), `AUTO_PAUSE_MIN_OPENS` (200).
- New error code `activity_not_started` (409).
- S6 must forward `X-Device-Id` and `X-Forwarded-For` on server-side calls.

## Data and migration

One forward-only migration (PLANNING §4.2). The affected tables are empty in every environment, so no backfill. Generated DB types are regenerated.

## Dependencies and integrations

S2 engine; S3 snapshot builder, `notifyPlan` and `notifyAttendance` (implement S3 first); S1 identity and contracts. No new npm dependencies.

## Explicitly excluded

Screens and share sheets; holdout and flags; scheduled audit, purge and cleanup jobs; admin pause; vouch holds; waitlist; notifications from Velio; trust scores; contact verification; photo upload; Static Maps signing.
