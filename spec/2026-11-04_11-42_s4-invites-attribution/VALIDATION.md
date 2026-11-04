# Validation: S4 Invites, attribution and read APIs

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] Scope matches parent S4 (codes, opens, claims, attribution, trust edges, hash chain, rate limits, pause), plus every unowned read API (PLANNING §12, Q3, decided 2026-11-04; a departure from the MVP plan's delivery table).
- [x] No invented product targets: 10 per hour, 2% and the code alphabet come from the PRD; N ∈ {1, 5, 14} from PRD Q4. The R7 spike threshold (200 opens per hour) and per-link limit (60 per minute), and the 280 and 80 character limits, were set by the user on 2026-11-04 (Q2, Q6). The caps of 3 host dates and 100 community activities are proposals.
- [x] Open questions Q1–Q7 (PLANNING §12) answered before implementation (2026-11-04).
- [ ] S3 implemented first, or S4's plan amended to ship the snapshot builder.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001 | V-INV-1, V-INV-2 |
| FR-002 | V-INV-3 |
| FR-003 | V-INV-1, V-INV-4 |
| FR-004 | V-EVT-1, V-PLAN-3 |
| FR-005, SEC-003 | V-VIEW-1, V-VIEW-2 |
| FR-006, AC-007 | V-OPEN-1…3 |
| FR-007 | V-CLM-1 |
| FR-008, FR-009, FR-014 | V-CLM-1, V-CLM-2, V-CLM-3 |
| FR-010 | V-CLM-4 |
| FR-011, AC-002 | V-CLM-5 |
| FR-012, AC-001 | V-CC-1 |
| FR-013 | V-EVT-1 |
| FR-015, SEC-005 | V-DB-2 |
| FR-016, AC-004 | V-DB-3 |
| FR-017, AC-006 | V-RL-1 |
| FR-018 | V-RL-2, V-RL-3 |
| FR-019 | V-PAUSE-1 |
| FR-020 | V-PLAN-1, V-PLAN-2 |
| FR-021 | V-DB-1 |
| FR-022 | V-READ-1 |
| FR-023 | V-READ-2 |
| FR-024, SEC-007 | V-READ-3 |
| FR-025, AC-009 | V-READ-4 |
| FR-026 | V-READ-5 |
| FR-027, AC-010 | V-READ-6 |
| FR-028 | V-READ-7 |
| FR-029 | V-READ-5, V-READ-6, V-CON-1 |
| NFR-005 | V-READ-8 |
| NFR-001, AC-003 | V-CC-2 |
| NFR-002 | Code review; V-CC-1…4 (no deadlocks) |
| NFR-003, SEC-004 | V-OBS-1 |
| NFR-004 | Code review |
| AC-005 | V-DB-4 |
| AC-008, SEC-001, SEC-002 | V-SEC-1 |
| SEC-006 | Covered by parent SEC-008; no check in S4 |

### Checks

`bun test` against Compose Postgres, a fresh database per file (S1 helpers); races through a real `Bun.serve` with a pool of 20 (as S2).

| ID | Check | Expected |
| --- | --- | --- |
| V-DB-1 | `bun run db:migrate` on a fresh database and on the test template; regenerate DB types | Applies cleanly; columns, checks, indexes, triggers and functions present; types match |
| V-DB-2 | Insert invites and attributions directly as `velio_api`, supplying fake `chain_seq` and hashes; insert across two activities | Trigger overwrites them; per-activity `chain_seq` 1, 2, 3; first `prev_hash` is 32 zero bytes; each `row_hash` recomputes |
| V-DB-3 | AC-004 using an admin connection | Tampered row's `chain_seq` reported; deleted row reported as a gap; a clean chain reports nothing |
| V-DB-4 | AC-005 as `velio_api` | Each statement fails (permission denied) |
| V-CON-1 | Schema tests for `Invite`, `InviteView`, `ClaimResponse`, `PlanView` and the read-API schemas; `bun run contracts:openapi` and diff | No contact or hash fields; `InviteView` has no `inviteeName`; CI drift check passes |
| V-INV-1 | Member creates a vouch with name, contact and note | `201`; code matches the alphabet; link uses `PUBLIC_BASE_URL`; `expires_at = starts_at`; contact stored only as a 32-byte hash |
| V-INV-2 | Non-member; removed member; unknown Plan; after start; vouch without a name; public body with a note; 281-character note | `403`; `403`; `404`; `409 activity_started`; `400` ×3; nothing inserted |
| V-INV-3 | Same member requests a public link twice; another member requests one | `201` then `200` with the same code; the other member gets a different code |
| V-INV-4 | Unit: 10,000 codes match the pattern; forced collision with a stubbed generator; more than 5 collisions | All valid; second code used; `internal`, nothing inserted |
| V-VIEW-1 | View a claimable vouch, a claimed vouch (as claimer and as someone else), an expired invite, a paused link, a sold-out activity | Statuses per FR-005; `claimedByViewer` only for the claimer; sold out shows in `activity.status`, invite still `claimable` |
| V-VIEW-2 | Lowercase code, code with a hyphen and spaces, 5-character code, unknown code | First two resolve; last two `404 invalid_code` and counted |
| V-OPEN-1 | Same device twice; a second device | One row then no new row (`204` both); second device adds a row; one `invite_opened` per new row |
| V-OPEN-2 | AC-007: WhatsApp and Twitterbot user agents; the inviter's session; another Plan member's session | `204`, no rows |
| V-OPEN-3 | Open a sold-out invite and an expired invite; missing `X-Device-Id` | Rows recorded; `400 validation_failed` |
| V-CLM-1 | New guest claims a vouch (web), then a public link with `X-Client: mobile` as another new guest | `201`; booking `source` = rail, in the invite's Plan; user created with the right generation; cookie set (web) or token in body (mobile); one `invite_claims` row each |
| V-CLM-2 | Signed-in existing user claims; existing user without a session but with a matching contact | Booking under the existing user; display name unchanged; no new user; session issued only in the second case |
| V-CLM-3 | Replay without a session after a successful new-guest claim (same contact and key) | `200`, same booking; a new session issued; no second user |
| V-CLM-4 | Each rejection in FR-010, and one case per adjacent pair in the order | Codes and statuses as FR-010; nothing written on rejection, including no user |
| V-CLM-5 | AC-002; D4: a user who claimed a public link claims a vouch on another activity; an existing gen-0 user claims a vouch | Attribution unchanged in the second claim; a trust edge for each vouch by an existing user; no attribution for existing users |
| V-CC-1 | AC-001 | As stated; one `invite_claims` row |
| V-CC-2 | NFR-001 for N ∈ {1, 5, 14}, 3 rounds each | As stated |
| V-CC-3 | One new contact, 10 parallel claims with one key; then 10 parallel claims with 10 keys | One user, one booking in both; the second set returns one `201` and `already_booked` or replays for the rest |
| V-CC-4 | Invite creation (20 in parallel) racing 50 claims on one activity | Both chains have contiguous `chain_seq`; `audit_chain` clean; no deadlocks |
| V-RL-1 | AC-006 with the injected clock; then advance past the window | `429` for the 11th and for a valid code; allowed again after the window |
| V-RL-2 | 61 claim attempts on one public link within a minute | `429 rate_limited`; spots untouched |
| V-RL-3 | Auto-pause: record 200 opens in the trailing hour with claims below 2%; then 200 with claims at or above 2%; then 199 with no claims | Paused with `paused_reason = 'auto'` and a `plan` hint in the first case only |
| V-PAUSE-1 | Creator pauses and resumes; host pauses; another member pauses; pause a vouch; claim a paused link | `204`s with `paused_reason` `owner`/`host`; `403`; `400`; `409 invite_paused` |
| V-PLAN-1 | Plan view as the owner, as a claimed guest, as a removed member, as an outsider | Members with full names and sources; own ref only; `code`, `link`, `note` only on own invites; removed: no invites, `canInvite: false`; outsider `403` |
| V-PLAN-2 | Invite status for each lifecycle state, vouch and public | Per PLANNING §4.9 |
| V-PLAN-3 | Socket on `plan:P` (S3); create, open, claim and pause invites in P | One `plan` hint for each |
| V-READ-1 | My plans for a user with an upcoming confirmed booking, a past one and a removed one; signed out | Split and order per FR-022; own ref only; members as `MemberPerson`; `401` signed out |
| V-READ-2 | Host activity list for a host with upcoming and past activities; for a user hosting none | Split per FR-023 with `bookedCount`; empty lists |
| V-READ-3 | Attendance list as host (confirmed, removed, vouch, public and direct attendees, one marked); as another user | Fields and order per FR-024, "via" inviter set, latest mark shown; `403` |
| V-READ-4 | AC-009; mark a removed booking; mark as a non-host; host socket on `host:A` (S3) during a mark | As AC-009; `409 booking_removed`; `403`; one `attendance` hint |
| V-READ-5 | Communities list; a community page with open, sold-out and past activities; unknown slug | `upcomingCount` correct; upcoming only, soonest first, sold out included with status, coordinates present; `404` |
| V-READ-6 | AC-010: profile of a host with upcoming and past hosted activities and their own bookings | Upcoming hosted only; `memberSince` month and year; no bookings or Plans; `PublicPerson` only |
| V-READ-7 | Next-steps for an activity whose host has 5 other dates (2 sold out) and whose community has 5 others with spots | At most 3 each, with spots, soonest first, current activity excluded |
| V-READ-8 | Query count through the Kysely log hook for each list endpoint at 1 and 20 rows | Same count at both sizes (NFR-005) |
| V-EVT-1 | After V-INV-1, V-OPEN-1, V-CLM-1 and a contact-mismatch claim | `invite_created`, `invite_opened`, `invite_claimed` (with `is_new_user`) and `vouch_contact_mismatch` rows with user, activity, invite, rail, generation and platform where known |
| V-OBS-1 | In-memory metric reader over the checks above | Instruments per NFR-003 with only the listed labels; no codes, IDs, contacts or notes in labels, span attributes or logs (activity ID allowed) |
| V-SEC-1 | AC-008: scan every response body in the suite for the test contacts, their hashes, notes (outside the allowed places) and other members' refs | No matches |
| V-CI-1 | `bun run format:check`, `bun run lint`, `bun run typecheck`, `bun test`, OpenAPI drift check | All pass |

### Static analysis and formatting

ESLint, Prettier and `tsc --noEmit` as in CI.

### Security checks

V-DB-2…4 (chain and insert-only), V-RL-1 (guessing lockout), V-SEC-1 (no contacts or misplaced notes), V-OBS-1 (no codes or IDs in telemetry), V-OPEN-2 (bots and members).

### Manual verification

After the user deploys with `PUBLIC_BASE_URL` set: create a vouch through the API, check its link uses the `cloudfront.net` hostname, view it anonymously, and claim it as a new guest. May be recorded as not run.

### Preconditions and test data

Compose Postgres migrated with the new migration. S3 implemented (snapshot builder, `notifyPlan`, `notifyAttendance`). The injected clock moves time past an activity's start for V-READ-4.

### Known limitations

- The audit catches edits that bypass the triggers, not a consistent rewrite of a whole chain by a superuser (PLANNING §4.8).
- Device IDs are client-generated, so a determined guesser can rotate them; the PRD's fallback (longer codes, 24 h lockout) isn't built.
- The full-scale `invite_claims` k6 scenario is S9.

## Part B: Executed checks

All checks run on 2026-11-04 on macOS (Bun 1.4.4, Compose `postgres:18.6`), and the full suite also in a Linux container (`oven/bun:1.4.4` on the Compose network), as CI runs it.

| ID | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| V-DB-1 | `bun run db:migrate`; dbmate on a fresh database (`velio_fresh`, then dropped); `velio_test` rebuilt from the migration files; `bun run db:codegen --verify` | **Pass.** All four migrations apply from scratch; the rebuilt template's chain and audit function definitions match (same md5) the database the tests ran on before; generated types up to date. | FR-021 |
| V-DB-2…4 | `bun test apps/api/test/db/chain.test.ts` | **Pass,** 4 tests. Inserts as `velio_api` with fake `chain_seq` and hashes get 1, 2, 3 per activity, a 32-zero-byte genesis, linked `prev_hash`, and `row_hash` that recomputes in the test from `invite_canonical`; a second activity starts its own chain. Attributions take their activity from the invite even when the caller sends another. AC-004: an edited attribution is reported at its `chain_seq` (2), a deleted one as the gap after it (3), an edited invite note in the invites chain; `audit_all_chains()` lists both activities. AC-005: `UPDATE` and `DELETE` on `invites`, `invite_claims`, `attributions`, `trust_edges` fail with permission denied for `velio_api`. | FR-015, FR-016, SEC-005, AC-004, AC-005 |
| V-CON-1 | `bun test packages/contracts`; `bun run contracts:openapi`; `bun run format:check` | **Pass,** 9 tests. No contact, hash, email or phone field in any S4 schema; `InviteView` has no `inviteeName`; public list schemas have no `displayName`; attendees have no note. OpenAPI regenerated. | FR-029, SEC-001–SEC-003 |
| V-INV-1…4, V-VIEW-1…2, V-OPEN-1…3, V-PAUSE-1, V-RL-1…3, V-OBS-1, V-EVT-1 (part) | `bun test apps/api/test/invites/invites.test.ts` | **Pass,** 16 tests. Vouch: code in the alphabet, link on `PUBLIC_BASE_URL`, `expires_at = starts_at`, contact only as its HMAC and the raw value in no invite row. Rejections: non-member and removed member `403`, unknown Plan `404`, after start `409 activity_started`, missing name, 81-character name and 281-character note `400` (a public link ignores a stray `note`). Public link `201` then `200` with the same code; another member gets their own. View: status order claimed > expired > paused > claimable, sold out only in `activity.status`, inviter as "Tunde A.", no invitee name, surname or contact; typed code normalised; short and unknown codes `invalid_code`. Opens: once per device, WhatsApp/Twitterbot/facebookexternalhit and the inviter not recorded, an outside signed-in viewer recorded, sold-out and expired recorded, missing device `400`. Pause by creator (`owner`) and host (`host`), resume, others `403`, vouch `400`, paused claim `invite_paused`. AC-006: the 11th invalid code `429`, then a valid code `429` for view, open and claim; another device unaffected; allowed again an hour later (injected clock). Per-link limit (3 per minute in the test) → the 4th `429` with no spot taken, allowed in the next minute. Auto-pause at the threshold (20 in the test) with no claims, `paused_reason = 'auto'`, `paused_by` null; not at 5% claims. Metrics labels as NFR-003; open outcomes `recorded`, `duplicate`, `member`, `bot`; claim outcomes include `invite_paused` and `rate_limited`. | FR-001–FR-006, FR-017–FR-019, NFR-003, AC-006, AC-007, SEC-001, SEC-003, SEC-004 |
| V-CLM-1…5, V-EVT-1 (part), V-SEC-1 | `bun test apps/api/test/invites/claims.test.ts` | **Pass,** 8 tests. New guest (web): `201`, cookie, booking in the invite's Plan with `source = vouch`, generation 1, attribution with `chain_seq` 1; mobile: 43-character token that works on `/api/me`, no cookie. Generation 2 through a guest's own vouch into the same Plan. Existing users by session and by contact: no new user, stored name kept, generation 0, no attribution. Replay without a session: `200`, same booking, new session. Rejections and their order: `invalid_code`, missing identity and key `400`, host `forbidden`, inviter `already_booked`, other person `already_claimed`, claimer's own vouch `200` with their booking, `sold_out`, `booking_removed`, `bookings_paused`, `invite_expired`; no rejected claim created a user; `booking_rejected` reasons recorded. D4: a later vouch for a public-rail guest leaves the attribution and adds a trust edge; an organic user's vouch claim adds a trust edge and keeps generation 0. Events `invite_created`, `invite_claimed` (`is_new_user`), `vouch_contact_mismatch`, `booking_succeeded`; none for a matching contact. AC-008: no response body in the file contains a test contact, any user's contact hash, or a `contact_hash` key. | FR-007–FR-014, AC-002, AC-008, SEC-001, SEC-002 |
| V-CC-1…4 | `bun test apps/api/test/concurrency/claims.test.ts` (real `Bun.serve`, pool of 20) | **Pass on Linux,** 6 tests: 20 parallel claims of one vouch → one `201`, 19 `already_claimed`, 1 spot taken (AC-001); 200 new guests on a public link with 1, 5 and 14 spots, 3 rounds each → exactly N claims, the rest `sold_out`, N new users, attribution `chain_seq` 1…N, audit clean (AC-003); one contact 10× with one key → one user, one `201`, nine `200`; with 10 keys → one `201`, nine `already_booked`; 20 invite creations racing 50 claims → invites `chain_seq` 1…21, attributions 1…50, audit clean, no deadlocks. On macOS 2 of the 200-guest rounds fail with refused connections (below). | FR-012, NFR-001, NFR-002, AC-001, AC-003 |
| V-PLAN-1…3 | `bun test apps/api/test/plans` (real server with S3 realtime) | **Pass,** 3 tests. Owner sees members with full names, sources and "via Tunde", own ref, own invites' code and note, no code, link or note on another member's invite; the guest sees only their own ref; a removed member sees `removed`, no invites, `canInvite: false`; outsider `403`, unknown `404`. Status created → opened → claimed for a vouch; opened and claimed with counts for a public link; expired after start (a claimed vouch stays claimed). A `plan` hint on the Plan topic for invite creation, open, claim and pause. | FR-004, FR-006, FR-019, FR-020 |
| V-READ-1…8 | `bun test apps/api/test/read` | **Pass,** 8 tests. My plans split and ordered, removed booking included, `401` signed out. Host activity list with `bookedCount`, empty for a non-host. Attendance: names, sources, inviter, refs, removed attendee listed; no note, contact or hash text; non-host `403`, unknown `404`. AC-009: mark before start `409 activity_not_started`; `no_show` then `attended`, both rows kept, list shows `attended`; removed booking `409 booking_removed`; non-host `403`; bad mark `400`. Communities: `upcomingCount`; page with upcoming only, soonest first, sold out included, coordinates, short names only; unknown slug `404`. AC-010: profile with "Profile P.", `YYYY-MM`, upcoming hosted only, none of the person's own bookings. Next-steps: 3 host dates with spots soonest first (sold-out ones skipped), 3 more in the community, current excluded. Query counts equal at 1 and 20 rows for My plans, the host list and profiles; the community page at most 4. | FR-022–FR-029, NFR-005, AC-009, AC-010, SEC-007 |
| V-CI-1 | `bun run format:check`, `bun run lint`, `bun run typecheck`, `bun test` (macOS and Linux) | **Pass with one environment exception.** Format, lint and typecheck pass. Linux: **244 pass, 0 fail** across 20 files. macOS: 242 pass, 2 fail: two rounds of the new 200-guest claim race, refused connections (`ECONNREFUSED`) from macOS's `kern.ipc.somaxconn = 128`, as recorded for S2's race in S3's Part B. | — |

**Checks not run:**

- Manual verification through CloudFront: needs a deploy (the user's). Production now sets `PUBLIC_BASE_URL` in `infra/docker-compose.prod.yml`, defaulting to the distribution's hostname.
- CI on GitHub: the changes aren't pushed yet.
- SEC-006 has no S4 check; it is the parent's SEC-008 (unverified identity, prototype only).

**Deviations from the plan** (also in PLANNING's change log):

- The chain columns (`chain_seq`, `prev_hash`, `row_hash`, and `attributions.activity_id`) have placeholder defaults that the triggers always replace, so inserts can leave them out.
- An invite is expired when its activity has started (`activities.starts_at`); `invites.expires_at` holds the same instant and is still stored.
- `booking_attempts_total` gains the outcome `retry` (a new guest whose contact a parallel request created first; the claim is retried as that user). It is a new value, not a new label.

**Known limitations:**

- The audit catches edits that bypass the triggers, not a consistent rewrite of a whole chain by a superuser (PLANNING §4.8).
- Device IDs are client-generated; the IP fallback applies only when no device ID is sent.
- Old `rate_limits` windows are not cleaned up yet (S8).
- No holdout gating yet (S8, decided in PLANNING §12, Q5).

**Final validation status: Passed with exceptions** (the macOS connection-backlog failures in the 200-parallel race tests; GitHub CI pending the push).
