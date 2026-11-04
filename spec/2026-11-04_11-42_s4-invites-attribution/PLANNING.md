# Planning: S4 Invites, attribution and read APIs

- **Spec ID:** 2026-11-04_11-42_s4-invites-attribution
- **Created:** 2026-11-04 11:42 (local)
- **Status:** Implemented (2026-11-04)
- **Phase:** 3, Realtime and invites (`ROADMAP.md`), alongside S3
- **Parent:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (approved), delivery step S4
- **Builds on:** `spec/2026-11-03_22-30_s2-booking-core/` (implemented); uses the snapshot and `notifyPlan` from `spec/2026-11-04_11-42_s3-realtime/` (in review)
- **PRD:** `Velio Group Bookings PRD.md`

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

Invites are how a booking recruits the next one, and attribution is how Velio knows whether that worked (PRD Context, goals "Bookers invite" and "Invites convert", K-factor). Today a Plan has one member and no way to add more. There are no invite codes, no invite page data, no open beacon, no claim, no attribution, and the hash chain the schema reserved columns for is never computed. The three risks the PRD names for this area are a vouch claimed twice (I6), attribution that can be rewritten (I5, R11) and codes or links abused (R7, R10).

## 2. Context and current behavior

- [Verified, `apps/api/migrations/20261103140100_schema.sql`] The tables exist:
  - `invites` (insert-only): `code` unique and pattern-checked, `rail`, `activity_id`, `plan_id`, `inviter_id`, `invitee_name`, `invitee_contact_hash`, `note`, `expires_at`, nullable `prev_hash`/`row_hash` ("computed in S4"). There is **no raw contact column**.
  - `invite_controls` (mutable): `paused`, `paused_by`, `updated_at`.
  - `invite_opens`: primary key `(invite_id, device_id)`, `first_rendered_at`.
  - `invite_claims` (insert-only): primary key `booking_id`, partial unique `invite_claims_one_per_vouch (invite_id) WHERE rail = 'vouch'`.
  - `attributions` (insert-only): primary key `invitee_id` (first claim wins, PRD D4), `generation >= 1`, nullable hash columns, **no `activity_id`**.
  - `trust_edges` (insert-only), `rate_limits (key, window_start, count)`, `events`.
  - Insert-only tables have triggers that reject `UPDATE`/`DELETE` for every role, and `velio_api` has only `SELECT, INSERT` on them.
- [Verified, `apps/api/src/modules/bookings/engine.ts`] `bookSpot` accepts `source`, `planId`, `inviteId` and `extend(tx, booking)`, which runs inside the transaction after the booking row exists. The transaction takes the activity row lock first. It needs a known `userId` before the transaction (replay lookup and prechecks).
- [Verified, `packages/contracts/src/errors.ts`, `apps/api/src/errors.ts`] Codes `already_claimed` (409), `invite_expired` (410), `invite_paused` (409), `invalid_code` (404) and `rate_limited` (429) exist.
- [Verified, `apps/api/src/modules/identity/`] `normaliseContact`, `contactHash` (HMAC with `CONTACT_PEPPER`), `createSession` and the cookie/bearer handling exist. `POST /api/sessions` finds or creates a user by contact hash with no verification (parent SEC-008).
- [Verified, S1 VALIDATION V-OBS-2] Logged paths already redact `/api/invites/:code`.
- [Verified, UI design spec §5.5] Copy that constrains the API:
  - `vouch.contactHelp`: "Used only to send and match this invite. {Host} never sees it."
  - `claim.rateLimited`: "Too many attempts from this device. Try again in an hour. Your invite still works."
  - `share.paused`: "We paused it while we check unusual activity… Vouch invites still work."
  - `claimed.other`: "A vouch invite is for one person…"
  - UX FR-004: the vouch invite page shows the inviter lead and the note.
- [Verified, MVP plan §4.7] Code alphabet and length; link `https://<distribution>.cloudfront.net/i/<code>`; opens from a client beacon after first paint; rate limits in Postgres with fixed windows.
- [Verified, PRD R10] 10 invalid-code attempts per device per hour.
- [Verified, PRD R7] Public links are rate-limited per link and auto-paused on "opens per link spike while claims stay under 2%". The PRD gives no number for the spike or the per-link limit (§12, Q2).

## 3. Desired outcome

- Any confirmed Plan member can create a vouch (one named person, single use) or get their public link (multi-use) (PRD I1, I2), each with a 6-character code and a link (I3).
- Anyone with a code sees the invite: inviter, note (vouch), live activity snapshot and a clear status (PRD Flows, Edge cases).
- A rendered invite page records one open per invite per device (Scope challenge 2, R9).
- A claim is a booking through the S2 engine, in one transaction with the invite claim, the attribution and, for a new guest, the user and session (PRD I4, I6). Two parallel claims of one vouch give one booking.
- Attribution is append-only and hash-chained per activity, and a SQL audit function detects tampering (PRD I5, R11).
- Invalid-code guessing is rate-limited per device; public links can be paused by their creator or the host, and are auto-paused on the R7 signal.
- The Plan view shows members, how each joined and invite status (PRD L1), live through S3's `plan` hint.
- Every remaining read API the clients need exists: My plans, the host's activity list, attendance and marks, communities, profiles and next-steps (§4.12, decided in §12, Q3).

## 4. Proposed solution

### 4.1 Module layout [Proposal]

```text
apps/api/src/modules/
  invites/
    codes.ts       # code generation and input normalisation
    service.ts     # create, view, open, pause/resume
    claims.ts      # claim: identity resolution, prechecks, engine call with extend
    limits.ts      # fixed-window rate limits (device, link) and the R7 auto-pause check
    routes.ts
    metrics.ts
  plans/
    service.ts     # GET /plans/:id, GET /me/plans
    routes.ts
  attendance/
    service.ts     # attendance list, marks, host activity list
    routes.ts
  communities/
    service.ts     # communities, profiles, next-steps
    routes.ts
  bookings/
    engine.ts      # + new-user insert at the start of the transaction; claim error mapping
migrations/
  20261104xxxxxx_invites_attribution.sql
```

### 4.2 Schema changes (one forward-only migration)

All three tables are empty in every environment, because no code writes to them yet [Verified: nothing in `apps/api/src` inserts into them].

| Change | Why |
| --- | --- |
| `invites.chain_seq bigint NOT NULL`; `prev_hash`, `row_hash` `NOT NULL`; unique `(activity_id, chain_seq)` | Explicit chain order, safe under concurrency (§4.8) |
| `attributions.activity_id uuid NOT NULL REFERENCES activities`, `chain_seq`, hashes `NOT NULL`; unique `(activity_id, chain_seq)` | Chain per activity (parent SEC-002); the table had no activity column |
| `BEFORE INSERT` triggers `invites_chain` and `attributions_chain` | The database assigns `chain_seq` and both hashes; the API can't forge them (§4.8) |
| Functions `audit_chain(activity_id uuid)` and `audit_all_chains()` | The audit (PRD Operations); S8 schedules it nightly |
| `CHECK` on `invites`: vouch needs `invitee_name`; public has no `invitee_name`, `invitee_contact_hash` or `note`; `note` ≤ 280 characters and `invitee_name` 1–80 non-blank characters (§12, Q6) | Rail rules in the database |
| Partial unique `(plan_id, inviter_id) WHERE rail = 'public'` | One public link per member per Plan (§4.3) |
| `invite_controls.paused_reason text CHECK (paused_reason IN ('owner', 'host', 'auto'))` | The UI shows a different message for an automatic pause (`share.paused`) |
| Index `invite_opens (invite_id, first_rendered_at)` | The R7 trailing-window count |
| Indexes `bookings (user_id)` and `activities (starts_at)` | My plans and next-steps (§4.12) |

### 4.3 Creating invites: `POST /api/plans/:id/invites`

- **Who:** the caller must hold a confirmed booking in the Plan (PRD business rules: any Plan member). Otherwise `403 forbidden`; unknown Plan `404`.
- **When:** before the activity starts (`409 activity_started` after). Sold out and paused activities still allow invites, because spots can free up and the invite page shows availability live (PRD Lifecycles note).
- **Vouch body:** `{ rail: 'vouch', inviteeName, contact?, country?, note? }`. `inviteeName` is 1–80 characters and `note` at most 280 (§12, Q6). The contact is normalised and stored only as `invitee_contact_hash`; the raw value is never stored (§12, Q1). No cap on vouches (PRD Q3).
- **Public body:** `{ rail: 'public' }`. Returns the caller's existing public link for this Plan (`200`) or creates it (`201`) [Proposal, §12, Q4]. A paused link is returned paused; the creator resumes it rather than making a new one.
- **Code:** 6 characters from `23456789ABCDEFGHJKMNPQRSTUVWXYZ` with `crypto.randomInt`; `ON CONFLICT (code) DO NOTHING`, retried up to 5 times, then `internal` (same pattern as booking refs).
- `expires_at` = the activity's `starts_at`. It can't change later, because the start time is locked once a booking exists and the creator holds one (PRD Q2).
- In the same transaction: the insert (its trigger takes the activity row lock and extends the chain), an `invite_created` event (user, activity, invite, rail, generation, platform), and `notifyPlan`.
- **Response:** `Invite { id, code, link, rail, inviteeName, note, status, opens, claims, paused, pausedReason, createdBy, createdAt }`. `link` = `PUBLIC_BASE_URL` + `/i/` + code. `PUBLIC_BASE_URL` is a new config value, required in production (the `cloudfront.net` hostname), defaulting to `http://localhost:3000` in development [Proposal].
- **Holdout:** not gated in S4. S8 adds the `group_invites` flag and removes invite tools for holdout users (parent FR-027) [Proposal, §12, Q5].

### 4.4 Viewing an invite: `GET /api/invites/:code`

Public. Also used by the Flutter code-entry screen.

- **Code input** is normalised before lookup: trim, remove spaces and hyphens, upper-case [Proposal]. Anything that isn't 6 alphabet characters after that is `invalid_code` without a database lookup, and counts toward the limit.
- **Rate limit first** (§4.7): a device over its limit gets `429 rate_limited` for every code, valid or not, so a locked-out device can't learn which codes exist.
- Unknown code → `404 invalid_code`, counted.
- **Response** `InviteView`:

  ```ts
  {
    code, rail,
    status: 'claimable' | 'claimed' | 'expired' | 'paused',  // precedence: claimed (vouch) > expired > paused > claimable
    pausedReason: 'owner' | 'host' | 'auto' | null,
    inviter: PublicPerson,
    note: string | null,                       // vouch only
    claimedByViewer: boolean,                  // the signed-in caller claimed this vouch
    activity: PublicActivity                   // S3 snapshot, including live spotsLeft, version, members, viewer
  }
  ```

- Sold out isn't an invite status (PRD Lifecycles): `activity.status` shows it, and the invite becomes claimable again if a spot frees.
- The invitee's name and contact are never returned on this public endpoint [Proposal]: the page leads with the inviter ("Tunde wants you on…").
- **Server-side rendering (S6):** the web invite page fetches this from the Next.js server, so S6 must forward the viewer's device ID and IP (§4.7). Recorded as an S6 dependency.

### 4.5 Open beacon: `POST /api/invites/:code/opens`

- Headers: `X-Device-Id` required (1–128 characters of `[A-Za-z0-9_-]`, generated and kept by the client); body `{ platform }`.
- Unknown code → `invalid_code`, counted like a view.
- **Not recorded** (still `204`) when:
  - the user agent matches the preview-bot list (backup filter, PRD R9) [Proposal: a fixed list in `invites/service.ts` including WhatsApp, facebookexternalhit, Twitterbot, Slackbot, TelegramBot, Discordbot, LinkedInBot, SkypeUriPreview, Googlebot, bingbot, Applebot and generic `bot|crawler|spider`];
  - the signed-in caller is a confirmed member of the invite's Plan, such as Tunde checking his own link [Proposal, §12, Q7].
- Otherwise `INSERT … ON CONFLICT (invite_id, device_id) DO NOTHING`. A new row writes an `invite_opened` event (user if signed in, activity, invite, rail, generation, platform), sends `notifyPlan`, and runs the R7 check for public links (§4.7).
- Opens on sold-out or expired invites are recorded too, so the funnel separates sell-out loss from friction loss (PRD Edge cases).
- Always `204` for a known code, so the beacon reveals nothing about de-duplication.

### 4.6 Claiming: `POST /api/invites/:code/claims`

Header `Idempotency-Key` (same rules as S2). Header `X-Client: mobile` returns the token in the body, as `POST /api/sessions` does. Body for a caller without a session: `{ displayName, contact, country?, platform? }`; with a session the identity fields are ignored (PRD Identity: a recognised guest skips the name and contact step).

**Identity resolution, before the transaction:**

1. Valid session → that user (**existing**).
2. Otherwise hash the contact. A user with that hash → that user (**existing**; R5, "first identity wins"; their stored display name is kept). This signs them in without verification, exactly as `POST /api/sessions` does today (parent SEC-008).
3. Otherwise → **new user**, created inside the transaction (below), with `invite_generation` = inviter's generation + 1 (PRD I4, Glossary).

**Prechecks** (read checks for clear errors; the database stays the authority), in this order [Proposal]:

1. Request validation → `400 validation_failed`.
2. Device rate limit (§4.7) → `429 rate_limited`.
3. Code lookup → `404 invalid_code` (counted).
4. Existing user only: idempotent replay of `(user, key)` → `200` with the original claim result, as in S2.
5. Activity started → `410 invite_expired` (PRD Edge cases: "This invite expired when the activity started").
6. Public link paused → `409 invite_paused`.
7. Vouch already claimed: by this user → `200` with their booking (PRD Edge cases: "If it was claimed by her own device, show her booking instead"); by anyone else → `409 already_claimed`.
8. Per-link claim limit for public links (§4.7) → `429 rate_limited`.
9. Engine prechecks for existing users: host → `403 forbidden`; `already_booked`; `booking_removed`.
10. In the transaction: `sold_out` (and `bookings_paused`, or a start-time race, which is reported as `invite_expired`).

**Transaction** (the S2 engine, PRD I6):

```sql
BEGIN;
-- New user only: created first, so a failed claim creates no user (MVP plan §4.4, step 1).
INSERT INTO users (display_name, contact_hash, invite_generation) VALUES (…)
  ON CONFLICT (contact_hash) DO NOTHING RETURNING id;
--   no row → a parallel claim or sign-in created this contact: ROLLBACK, resolve as existing, retry once.
UPDATE activities SET spots_left = spots_left - 1, version = version + 1 WHERE …;   -- S2, takes the row lock
INSERT INTO bookings (… plan_id = invite.plan_id, source = rail, invite_id …);       -- S2
-- extend(tx, booking), all S4:
INSERT INTO invite_claims (booking_id, invite_id, rail);
--   unique violation on invite_claims_one_per_vouch → ROLLBACK ⇒ already_claimed (spot restored)
INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation);    -- new users only; trigger chains it
INSERT INTO trust_edges (voucher_id, vouchee_id, invite_id);                       -- existing users on the vouch rail (D4)
INSERT INTO sessions (…);                                                          -- caller had no valid session
INSERT INTO events ('invite_claimed', …);                                          -- props: is_new_user
-- vouch with a stored contact hash that differs from the claimer's: INSERT events ('vouch_contact_mismatch')
INSERT INTO events ('booking_succeeded', …);                                       -- S2
SELECT pg_notify('activity_spots', …), pg_notify('plan_changed', …);               -- S2, S3
COMMIT;
```

- **Engine change:** `BookSpotInput` gains `newUser?: { displayName, contactHash, generation }`. When set, the engine skips the replay lookup and the user prechecks (a user that doesn't exist yet can't have bookings), inserts the user as the transaction's first statement, and passes the new ID to `extend`. The new-user conflict is a typed internal signal that `claims.ts` turns into one retry as an existing user [Proposal].
- **Error mapping:** a unique violation on `invite_claims_one_per_vouch` becomes `already_claimed`, after the S2 replay re-check. `already_claimed`, `invite_expired`, `invite_paused` and `invalid_code` join the engine's `booking_rejected` reasons, and become `outcome` values of `booking_attempts_total{path="claim"}`.
- **Why a vouch can't be claimed twice:** two claims both pass precheck 7. The second waits for the row lock, takes a spot, then fails on the partial unique index and rolls back, which restores its spot. The index is the authority (PRD I6).
- **Existing users** keep their generation and get no attribution (PRD Identity; D4). Their claim still counts for invite conversion through `invite_claims` and `bookings.invite_id`.
- **Contact mismatch** (PRD Edge cases, wrong recipient): the claim succeeds; an event and a warning log carry only the invite ID.
- **Response:** `201 { booking, activity: ActivityState, planId, user: MemberPerson, token? }`, plus the session cookie for web callers who had no session. A replay is `200` with the same shape and issues a session if the caller had none.

### 4.7 Rate limits and pausing

**Fixed windows in `rate_limits`** (MVP plan §4.7): `INSERT … ON CONFLICT (key, window_start) DO UPDATE SET count = rate_limits.count + 1 RETURNING count`, outside the booking transaction.

| Limit | Key | Window | Limit | Source |
| --- | --- | --- | --- | --- |
| Invalid codes per device | `code:dev:<sha256(device id)>`, or `code:ip:<sha256(ip)>` when no device ID is sent | 1 hour | 10, then every code lookup from that key is refused until the window ends | PRD R10 |
| Claim attempts per public link | `link:<invite id>` | 1 minute | 60 (config `LINK_CLAIMS_PER_MINUTE`; §12, Q2) | PRD R7 |

- Keys hold hashes, never raw device IDs or IPs.
- **Client IP** is the rightmost `X-Forwarded-For` entry added by CloudFront, since the origin accepts only CloudFront [Assumption: checked against the CloudFront request headers at implementation]. S6's server-side calls forward the viewer's `X-Device-Id` and `X-Forwarded-For`.
- Fixed windows let a device make up to 20 attempts across a window boundary. This is the MVP plan's accepted trade-off.
- Old windows are deleted by S8's jobs [Proposal].

**Pause** (PRD Operations, R7; parent FR-024), public links only:

- `POST /api/invites/:code/pause` and `DELETE /api/invites/:code/pause` by the link's creator or the activity's host; anyone else `403`. Upserts `invite_controls` with `paused_by` and `paused_reason` (`owner` or `host`), sends `notifyPlan`.
- A vouch can't be paused (`400 validation_failed` with a message) [Proposal]: it's single-use, and the host can remove a wrong recipient.
- **Auto-pause** (R7): after each recorded open on a public link, if the trailing 60 minutes hold at least 200 opens (config `AUTO_PAUSE_MIN_OPENS`; §12, Q2) and claims ÷ opens < 2%, the link is paused with `paused_reason = 'auto'` and `paused_by = null`, and `notifyPlan` tells the owner's open Plan view (Velio sends no notifications in MVP). The owner or host can resume it.
- Claims counted for the ratio are those made in the same trailing 60 minutes.

### 4.8 Hash chain

PRD NFR "Immutable attribution", R11; parent SEC-001, SEC-002; MVP plan §4.3.

- One chain per activity per table, for `invites` and `attributions` (the two tables S1 gave hash columns).
- A `BEFORE INSERT` trigger on each:
  1. locks the activity row (`SELECT … FOR UPDATE`). The booking transaction already holds it; invite creation takes it here. Writes to one chain are therefore serialized, and the lock order (activity first) matches S2;
  2. for `attributions`, sets `activity_id` from the invite, so it can't disagree;
  3. reads the activity's latest row in that table by `chain_seq`;
  4. sets `chain_seq` = previous + 1 (1 for the first), `prev_hash` = previous `row_hash` (32 zero bytes for the first), and `row_hash = sha256(prev_hash || convert_to(canonical, 'UTF8'))`.
- **Canonical text:** a `jsonb_build_array` of the row's columns in a fixed order, with timestamps as UTC ISO 8601 text with microseconds and `bytea` as hex, cast to `text` [Proposal]. `jsonb` text output is deterministic and doesn't depend on session settings once timestamps are pre-formatted.
- **Audit:** `audit_chain(activity_id)` walks each table by `chain_seq`, recomputes every hash, and returns the first broken `chain_seq` per table (or none). `audit_all_chains()` runs it for every activity. A gap in `chain_seq` also counts as a break (a deleted row).
- **What it catches:** any edit or deletion made by bypassing the grants and triggers (for example, a superuser disabling the trigger). Rewriting the whole chain consistently is still possible for a superuser; the defence there is the nightly `pg_dump` (parent NFR-008), which S8's audit report can compare against [Assumption].
- `invite_claims` and `trust_edges` stay protected by grants and triggers only. Adding them to the chain is an alternative (§10).

### 4.9 Plan view: `GET /api/plans/:id`

PRD L1, D5, Q12. See §12, Q3 for ownership.

- **Who:** a user with a booking (any status) in the Plan. Otherwise `403`; unknown `404`.
- **Response** `PlanView`:
  - `activity`: `{ id, title, startsAt, timezone }` (the client takes live spots from the S3 snapshot and topic);
  - `members`: confirmed bookings, earliest first, each `{ person: MemberPerson, source: 'direct' | 'vouch' | 'public', invitedBy: MemberPerson | null, joinedAt }`. Full names, because the viewer is a member (PRD Q12);
  - `viewer`: `{ booking: { id, ref, status }, canInvite }`. `ref` only for the viewer's own booking. `canInvite` is true for a confirmed member before start (S8 adds the holdout);
  - `invites`: every invite in the Plan, each `{ id, rail, inviteeName, createdBy: MemberPerson, status: 'created' | 'opened' | 'claimed' | 'expired', opens, claims, paused, pausedReason, createdAt }`, plus `code`, `link` and `note` only on invites the viewer created [Proposal]. A removed viewer gets `invites: []` and `canInvite: false`.
- **Invite status:** vouch: `claimed` if claimed, otherwise `expired` after start, otherwise `opened` if any open is recorded, otherwise `created`. Public: `expired` after start, `claimed` once it has any claim, `opened` once opened, otherwise `created` (PRD Lifecycles: Claimed ↔ Opened for public links; the counts carry the detail).
- Live through S3: invite created, opened, claimed and paused, and members joining or being removed, all send `notifyPlan`.
- Contact hashes are never returned.

### 4.10 Metrics and events

Labels only as listed; never invite, plan, user or activity IDs, and never codes (parent SEC-011).

| Instrument | Type | Labels |
| --- | --- | --- |
| `invites_created_total` | counter | `rail` |
| `invite_opens_total` | counter | `rail`, `outcome` (`recorded`, `duplicate`, `member`, `bot`) |
| `booking_attempts_total`, `booking_duration_seconds` | (S2) | `path="claim"`, with the new outcome values |
| `rate_limited_total` | counter | `scope` (`code`, `link`) |
| `invite_auto_paused_total` | counter | none |
| `vouch_contact_mismatch_total` | counter | none |
| `chain_audit_breaks` | (S8) | — |

**Events** (PRD Success metrics funnel): `invite_created`, `invite_opened`, `invite_claimed`, `vouch_contact_mismatch`, each with user, activity, invite, rail, generation and platform where known.

### 4.11 Tests

`bun test` against Compose Postgres, through a real `Bun.serve` for the races:

- Invite creation rules (member, non-member, removed member, after start, vouch and public bodies, public link reuse, code format, chain fields set).
- Invite view status precedence, public names only, no invitee name or contact, normalised code input.
- Open beacon: recorded once per device, bot UA, Plan member, unknown code, sold-out invite still recorded.
- Claims: new guest (generation, attribution, session cookie and mobile token), existing user by session, existing user by contact, D4 (public claim then a vouch for another activity → trust edge, attribution unchanged), every rejection code and precedence, replay without a session.
- **Races:** 20 users claim one vouch in parallel → one `201`, 19 `already_claimed`, one spot taken (parent AC-002). 200 new guests on a public link with N ∈ {1, 5, 14} spots → exactly N claims, N attributions, `chain_seq` 1…N with no gaps, audit clean. The same new contact claiming 10 times in parallel with one key → one user, one booking. Invite creation racing claims on one activity → both chains intact.
- Rate limits: the 11th invalid code in an hour → `429`, and a valid code is then refused too; the window rolls over with the injected clock. Per-link and auto-pause thresholds once Q2 is answered.
- Hash chain: tamper with a row as the owner after disabling the trigger → `audit_chain` reports the first broken `chain_seq`; delete a row → reported as a gap. Insert-only grants still reject `UPDATE`/`DELETE` for `velio_api` (parent AC-007).
- Plan view by audience; live `plan` hints through S3 on create, open, claim and pause.
- Read APIs (§4.12): audience rules (no contacts, notes or other members' refs; `PublicPerson` on public endpoints), ordering, upcoming/past split, caps, attendance marking before and after start and on removed bookings, latest mark wins, live `attendance` hint through S3.

### 4.12 Read APIs (PRD L2, H1, H2, Q9, Q10, Q11, A6)

Added by the decision on §12, Q3: S4 owns every read API that no other spec owned, so S5, S6 and S7 can build screens against a finished API. They share one card shape and the audience rules of PRD Q12 and D5.

**`ActivityCard`** (public): `{ id, title, startsAt, timezone, priceMinor, currency, photoUrl, capacity, spotsLeft, version, status, community: { slug, name }, location: { venueName, lat, lng }, members: { count, preview: PublicPerson[] } }`, built by the S3 snapshot module so the two never disagree.

| Endpoint | Who | Returns | PRD |
| --- | --- | --- | --- |
| `GET /api/me/plans` | Signed in | The caller's Plans (bookings of any status), split into `upcoming` and `past` by start time, soonest upcoming first and most recent past first. Each: `planId`, `ActivityCard`, own `booking { id, ref, status }`, `members { count, preview: MemberPerson[] }` | L2, Q14 |
| `GET /api/host/activities` | Signed in | The caller's hosted activities, split into `upcoming` and `past`, each `ActivityCard` plus `bookedCount` | H3 screen (UI design); W1 |
| `GET /api/host/activities/:id/attendance` | The host (`403` otherwise) | `activity { id, capacity, spotsLeft, version, startsAt, timezone, started }` and `attendees`: confirmed and removed bookings, booking time order, each `{ bookingId, ref, status, person: MemberPerson, bookedAt, source, invitedBy: MemberPerson \| null, planId, mark: 'attended' \| 'no_show' \| null, markedAt }`. Never contacts, hashes or notes | H1, D5 |
| `POST /api/host/bookings/:id/attendance` | The host | Body `{ mark: 'attended' \| 'no_show' }`. Inserts an `attendance_marks` row (insert-only; latest wins). Before start → `409 activity_not_started` (new code); removed booking → `409 booking_removed`. Calls S3's `notifyAttendance`. Returns the attendee row | H2; parent FR-015 |
| `GET /api/communities` | Public | Every community: `slug`, `name`, `blurb`, `coverPhotoUrl`, `upcomingCount` | Q11 |
| `GET /api/communities/:slug` | Public | The community and its upcoming activities as `ActivityCard`s, soonest first, sold-out ones included with their status, coordinates for the map view; at most 100 [Proposal] | Q11, A6; parent FR-029 |
| `GET /api/users/:id/profile` | Public | `person: PublicPerson`, `memberSince` (month and year), upcoming hosted activities as `ActivityCard`s. Never bookings or Plans | Q10; parent FR-031 |
| `GET /api/activities/:id/next-steps` | Public | `hostOtherDates`: the host's other upcoming activities with spots, soonest first, at most 3 [Proposal: the PRD caps only "More in"]; `moreInCommunity`: up to 3 upcoming activities in the same community with spots, soonest first, excluding this one | Q9, Edge cases; parent FR-030 |

- **Started** means the start time has passed, from the database clock, as everywhere else.
- **Attendance marks** follow parent FR-015: a later mark supersedes an earlier one without deleting it. Marking a booking the host has since removed is refused.
- **Removed attendees** stay in the host's list with `status: removed`, so the host can see who was removed (PRD Host removal).
- **Photos** are `null` until S5 adds uploads (S2 §4.5).
- **Indexes** [Proposal]: `bookings (user_id)` for My plans and `activities (starts_at)` for next-steps, added in the same migration.

## 5. Architectural considerations

- **Correctness:** claims add no second write path (PRD I6). Single use is the partial unique index; first-claim-wins is the `attributions` primary key; chain order is a unique `(activity_id, chain_seq)`. All are database rules.
- **Security:** codes are 6 characters from 31 (about 887 million, PRD R10); device limits stop guessing, and a locked device can't distinguish valid from invalid codes. Claim-time sign-in by contact is the same unverified model as `POST /api/sessions` (SEC-008, prototype only). Codes appear in URL paths, which logs already redact.
- **Privacy:** vouch contacts stored only as keyed hashes (§12, Q1). Hosts and public pages never see contacts or notes; the note is shown only on the vouch page (to whoever holds the code) and to its creator in the Plan (PRD D5; UX FR-004).
- **Performance:** a claim is the S2 transaction plus three or four single-row inserts while the row lock is held (R2). Invite creation now takes the activity row lock too, briefly; it's rare next to bookings. S9's `invite_claims` scenario measures both.
- **Operations:** the chain audit is a SQL function S8 can schedule; pause state lives in `invite_controls`, outside the insert-only table.
- **Accessibility:** no UI in S4.

## 6. Components and files affected

| Path | Change |
| --- | --- |
| `apps/api/migrations/20261104xxxxxx_invites_attribution.sql` | New migration (§4.2) |
| `apps/api/src/db/types.ts` | Regenerated |
| `apps/api/src/modules/invites/*` | New |
| `apps/api/src/modules/plans/*`, `attendance/*`, `communities/*` | New (§4.12) |
| `apps/api/src/modules/bookings/engine.ts`, `metrics.ts` | New-user path; claim error mapping and outcome values |
| `apps/api/src/app.ts`, `config.ts`, `errors.ts`, `.env.example` | Mount routes; `PUBLIC_BASE_URL`, `LINK_CLAIMS_PER_MINUTE`, `AUTO_PAUSE_MIN_OPENS`; status for `activity_not_started` |
| `infra/docker-compose.prod.yml` | `PUBLIC_BASE_URL` for production |
| `packages/contracts/src/{invites,plans,attendance,communities,errors,index}.ts` | `InviteCreate`, `Invite`, `InviteView`, `ClaimCreate`, `ClaimResponse`, `PlanView`, `MyPlans`, `ActivityCard`, `HostActivityList`, `Attendance`, `AttendanceMark`, `Community`, `CommunityPage`, `Profile`, `NextSteps`; error code `activity_not_started` |
| `packages/contracts/openapi.json` | Regenerated |
| `apps/api/test/invites/*`, `test/plans/*`, `test/concurrency/claims.test.ts`, `test/db/chain.test.ts`, `test/helpers/` | New tests and fixtures |
| `README.md`, `CHANGELOG.md`, `ROADMAP.md` | Docs |

**No new npm dependencies** [Proposal]: hashing is in Postgres (`sha256()`), and codes use `node:crypto`.

## 7. Implementation phases and ordered tasks

| # | Task | Verified by |
| --- | --- | --- |
| T1 | Migration: chain columns, triggers, audit functions, checks, public-link index, `paused_reason`, opens index; regenerate DB types | V-DB-1…4 |
| T2 | Contracts and `PUBLIC_BASE_URL` | V-CON-1 |
| T3 | Codes and invite creation | V-INV-1…3 |
| T4 | Invite view and device rate limit | V-VIEW-1…3, V-RL-1 |
| T5 | Open beacon | V-OPEN-1…3 |
| T6 | Engine new-user path and claim error mapping | V-CLM-1…6 |
| T7 | Claim route: identity resolution, prechecks, extend, session | V-CLM-1…6 |
| T8 | Pause, resume, per-link limit, auto-pause | V-PAUSE-1, V-RL-2, V-RL-3 |
| T9 | Plan view | V-PLAN-1…3 |
| T10 | Metrics and events | V-OBS-1, V-EVT-1 |
| T11 | Concurrency tests | V-CC-1…4 |
| T12 | Read APIs: My plans, host activity list | V-READ-1, V-READ-2 |
| T13 | Read APIs: attendance list and marks | V-READ-3, V-READ-4 |
| T14 | Read APIs: communities, profile, next-steps | V-READ-5…7 |
| T15 | OpenAPI regeneration, README, full CI command set | V-CI-1 |
| T16 | Record results; CHANGELOG, ROADMAP | Part B |

## 8. Dependencies and prerequisites

- S2 implemented [Verified, ROADMAP].
- **S3's snapshot builder** (`activities/snapshot.ts`, used in `InviteView` and `ActivityCard`), **`notifyPlan`** and **`notifyAttendance`**. Recommended order: S3, then S4. If S4 must go first, it would ship the snapshot builder itself and S3 would reuse it.
- Production needs `PUBLIC_BASE_URL` set to the distribution's hostname at the next deploy.
- No AWS, Grafana Cloud or Google Maps work.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| A vouch claimed twice (I6) | Partial unique index inside the booking transaction; V-CC-1 |
| Two parallel claims with the same new contact create two users | `users.contact_hash` is unique; the loser retries as the existing user; V-CC-3 |
| Attribution rewritten (R11) | Grants, triggers and the per-activity hash chain; `audit_chain`; V-DB-3 |
| Chain forked by concurrent writers | Activity row lock in the trigger, plus unique `(activity_id, chain_seq)` as a backstop |
| Code guessing (R10) | Device limit with full lockout; IP fallback when no device ID; lengthening codes is the PRD fallback |
| Device IDs rotated to dodge the limit | Accepted for the prototype (the IP fallback only applies without a device ID); PRD fallback is longer codes and a 24 h lockout |
| Spam link (R7) | Per-link limit and auto-pause, with numbers from Q2 |
| Invite creation slows bookings on a hot activity | One short trigger under the row lock; measured in S9 |
| Wrong recipient claims a vouch | Accepted by the PRD (the code is the credential); mismatch event; host removal |
| Server-rendered invite page hides the viewer's device and IP | S6 forwards both (recorded dependency) |

## 10. Alternatives considered

- **Compute hashes in the API:** easier to read, but anything that inserts could write any hash. The trigger keeps the rule in the database (MVP plan §4.1, principle 1).
- **Order the chain by `created_at`:** `created_at` is the transaction start time, so a transaction that waited for the lock can carry an earlier timestamp than the row before it. `chain_seq` avoids that.
- **Chain claims and trust edges too:** more coverage, more triggers. Claims are protected by grants, triggers and their link to bookings; the parent requirement names attribution.
- **Store raw vouch contacts in a mutable side table and purge them after the activity plus 30 days (PRD Q7):** needed only if Velio delivered invites itself. The booker sends invites from their own share sheet, so the server never needs the raw value (§12, Q1).
- **A new public link each time "Share link" is tapped:** more links per member make per-link limits and stats meaningless.
- **Separate claim endpoint logic:** rejected by the PRD (I6).

## 11. Estimated complexity

Large, and larger than the MVP plan's S4 because of the read APIs (§12, Q3). Most of the risk is in T1 (triggers), T6–T7 (claim path) and T11. T12–T14 are routine reads and come last, so the invite work can be checked first.

## 12. Assumptions and open questions

**Decisions** (answered by the user on 2026-11-04; the text of each question is kept):

1. **Q1: Store raw vouch contacts at all?** **Decided: hash only, as recommended.** The PRD says a vouch stores the contact "only to deliver and match" and keeps the raw value until the activity ends plus 30 days (Q7). Velio never delivers invites (the booker's share sheet does), and matching needs only the hash. **Recommendation:** store only the keyed hash, never the raw contact. Q7's retention then has nothing to purge, which is stricter than the PRD and needs no purge job. This would be a note on PRD Q7, raised with you rather than edited in.
2. **Q2: R7 numbers.** **Decided: 200 opens per trailing hour and 60 claim attempts per minute, as proposed.** The PRD gives "claims under 2%" but no spike threshold and no per-link limit. **Proposal for you to accept or change:** auto-pause a public link when its trailing 60 minutes hold at least **200 opens** and claims ÷ opens is below 2%; limit claim attempts on one public link to **60 per minute**. Both are config values, not code.
3. **Q3: Who owns the Plan and host read APIs?** **Decided: all of them in S4** (§4.12), including the host's activity list that the H3 screen needs. No delivery spec owns `GET /plans/:id` (L1), `GET /me/plans` (L2), the attendance list and marks (H1, H2), communities, profiles or next-steps; S5 owns the screens. **Recommendation:** S4 owns `GET /plans/:id`, because invite status is S4's data. The others go to S5 as an API part, written before its screens. This departs from the MVP plan's delivery table, as S2's activities API did.
4. **Q4: One public link per member per Plan?** **Decided: yes.** **Recommendation:** yes (§4.3).
5. **Q5: Holdout gating in S8?** **Decided: yes.** **Recommendation:** yes. S4 builds invites for everyone; S8 adds the flag, assignment and the server-side removal of invite tools.
6. **Q6: Note length.** **Decided: 280 and 80, as proposed.** The PRD and UI design give no limit. **Proposal:** 280 characters, and 80 for the invitee name.
7. **Q7: Opens by the Plan's own members** **Decided: not recorded.** (for example, Tunde previewing his link) aren't recorded. **Recommendation:** yes, so "Opened" means someone else opened it.

**Assumptions:**

- CloudFront's rightmost `X-Forwarded-For` entry is the viewer IP (checked at implementation).
- `sha256(bytea)` is built into Postgres 18 [Verified, Postgres has had `sha256()` since 11; Compose runs `postgres:18.6`].
- The invites, attributions and claims tables are empty in production, so `NOT NULL` columns can be added without a backfill.
- Old `rate_limits` windows are cleaned up by S8.

## 13. Related specs and PRD sections

- PRD: I1–I6, L1, B3, D2 (no hold), D4, D5, Business rules (Plans, Identity, names by audience), Lifecycles (Invite), Edge cases, NFR Immutable attribution and Privacy, Operations (public-link pause, attribution audit), Success metrics (funnel events, K-factor), R4, R5, R7, R9, R10, R11, Q3, Q7, Q12.
- MVP plan §4.3, §4.4, §4.6, §4.7, §4.8, §4.9; parent FR-006–FR-012, FR-020, FR-022, FR-024, FR-026, SEC-001–SEC-006, SEC-011, SEC-012, AC-002, AC-005 (beacon part), AC-006, AC-007.
- S2 booking core (engine, `extend`); S3 realtime (snapshot, `notifyPlan`); S1 (schema, identity, redaction).
- Next: S5 (Plan and invite screens; read APIs per Q3), S6 (invite page, forwards device and IP), S7 (code entry, claim), S8 (holdout, audit job, rate-limit cleanup, admin pause).

## 14. Change log

- 2026-11-04 11:42: created.
- 2026-11-04: open questions answered by the user (§12).
  - **Q1:** vouch contacts are stored only as a keyed hash. This is stricter than PRD Q7 (raw contact kept until the activity ends plus 30 days), and leaves Q7's retention with nothing to purge. A note for the PRD is raised with the user rather than edited in.
  - **Q2:** 200 opens in the trailing hour with claims under 2% auto-pauses a public link; 60 claim attempts per link per minute. Both are config values.
  - **Q3:** S4 owns every unowned read API (§4.12): My plans, the host's activity list, attendance and marks, communities, profiles and next-steps. This departs from the MVP plan's delivery table (S5 lists the screens). It adds the `activity_not_started` error code, two indexes and an attendance hint through S3's new `attendance_changed` channel. The title now reads "Invites, attribution and read APIs"; the directory name is unchanged.
  - **Q4–Q7:** accepted as recommended.
  - Status stays In review until the spec is approved.
- 2026-11-04: **approved** by the user. The PRD now carries the Q7 amendment (raw contact never stored). Implementation follows S3.
- 2026-11-04: **implementation authorized** by the user, after S3.
- 2026-11-04: **implemented.** Results are in `VALIDATION.md` Part B. Changes made during implementation, all within the approved scope:
  - **Chain column defaults (§4.2).** `chain_seq`, `prev_hash`, `row_hash` and `attributions.activity_id` have placeholder defaults (0, empty bytes, the nil UUID) that the triggers always replace, so generated types and inserts can leave them out. A row the trigger didn't touch would fail the foreign key or the audit.
  - **Expiry (§4.4, §4.6).** An invite counts as expired when its activity's `starts_at` has passed. `invites.expires_at` still stores the same instant; the activity is read because it is the source (the start time locks once anyone books).
  - **Claim rejections outside the engine (§4.6).** The engine exposes `rejectClaim`, so `invalid_code`, `invite_paused`, `already_claimed` (precheck), `invite_expired` (precheck) and `rate_limited` are counted in `booking_attempts_total{path="claim"}` and recorded as `booking_rejected` like engine rejections. A new guest whose contact a parallel request created first gets the outcome `retry`, then is claimed as that user.
  - **Contracts layout.** `invites.ts`, `plans.ts`, `attendance.ts` and `communities.ts`, as listed in §6.
  - **Production config.** `infra/docker-compose.prod.yml` sets `PUBLIC_BASE_URL`, defaulting to `https://depimls1pcvv4.cloudfront.net`, so the next deploy needs no new secret.
  - **Audit function.** `audit_chain` loops over row-typed variables; the first draft cast a generic record and failed. The fix is in the migration file, which hasn't shipped.
  - **Tests.** The S2 engine test that threw `already_claimed` from `extend` now throws a plain error: `already_claimed` became a recorded rejection, which changed the event count that test compares. Its intent (rollback) is unchanged.
