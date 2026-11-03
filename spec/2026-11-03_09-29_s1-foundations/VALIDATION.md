# Validation: S1 Foundations

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR and SEC requirement maps to a check below.
- [x] Nothing outside parent S1 scope is included.
- [x] Open questions in PLANNING §10 are answered before implementation.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001 | Removed (the user owns git) |
| FR-002, NFR-005, AC-001 | V-DX-1 |
| FR-003 | V-DX-2 |
| FR-004, FR-005 | V-DB-1 |
| NFR-001, AC-002 | V-DB-2, V-DB-3, V-DB-4, V-DB-5 |
| FR-015 | V-DB-6 |
| FR-006 | V-API-1 |
| FR-010, FR-012 | V-API-2, V-API-3 |
| FR-007–FR-009, AC-003 | V-ID-1, V-ID-2, V-ID-3, V-ID-4 |
| FR-013, FR-014, AC-006 | V-ID-6, V-ID-7 |
| SEC-001, SEC-002 | V-ID-5 |
| FR-011, SEC-005 | V-CON-1, V-CON-2 |
| NFR-002, NFR-003, AC-004 | V-OBS-1 |
| SEC-003 | V-OBS-2 |
| SEC-004 | V-SEC-1 |
| NFR-004, AC-005 | V-CI-1 |

### Checks

Automated tests use `bun test`. Integration tests run against Compose Postgres with a fresh database per test file.

| ID | Check | Expected |
| --- | --- | --- |
| V-DX-1 | Fresh copy of the project in a temp dir: `bun install`, compose up, `bun run db:migrate`, `bun test` | All pass |
| V-DX-2 | `docker compose ps` | All three services healthy |
| V-DB-1 | Migrate an empty database; list tables, roles and communities | Every table in parent §4.3 plus `communities` and `rate_limits`; three roles; three communities |
| V-DB-2 | UPDATE and DELETE on each insert-only table as `velio_api`, then as `velio_owner` | Permission error, then trigger error |
| V-DB-3 | UPDATE `users.invite_generation` and `created_at` | Trigger error |
| V-DB-4 | Insert an activity with `spots_left` < 0, > capacity, capacity 0, or an invalid time zone | Check or trigger error each time |
| V-DB-5 | Duplicate confirmed booking per user and activity; duplicate vouch claim; duplicate `ref`; duplicate `attributions.invitee_id` | Unique violation each time; a non-confirmed duplicate booking is allowed |
| V-DB-6 | Insert an activity with `lat` 91, `lng` -181, empty `venue_name`, a 141-character `meeting_point`; then add a confirmed booking and update `lat`, `meeting_point` and `starts_at`, then `title` | Check error for each bad insert; `location_locked` for each locked field; the title update succeeds |
| V-API-1 | `healthz` with the DB down; `readyz` with the DB up and down | 200; 200 then 503 |
| V-API-2 | Throw an unknown error in a test route | `internal` envelope with `requestId`, no stack |
| V-API-3 | Boot with `CONTACT_PEPPER` unset | Exits non-zero, message names the variable |
| V-ID-1 | Unit: email and phone normalisation table (case, whitespace, `+254 712…` / `0712…` with KE hint, invalid input) | As expected per row; invalid → `invalid_contact` |
| V-ID-2 | AC-003 | Same user ID |
| V-ID-3 | Session cookie flow (web) and bearer flow (`X-Client: mobile`), then `/api/me` | Both return the same `MemberPerson` shape |
| V-ID-4 | `/api/me` with no token, an unknown token, or a deleted session | 401 `unauthenticated` |
| V-ID-5 | Inspect the `users` and `sessions` rows after V-ID-2 | No raw contact or token stored; hashes have the expected length |
| V-ID-6 | With an injected clock: use at day 29 (extended), idle to day 31 (rejected), keep active to day 91 (rejected); two requests within 24 h (one renewal write) | As described |
| V-ID-7 | Sign in again while sending an existing session; sign out | Old token rejected after re-sign-in; after sign-out the token is rejected and the cookie is cleared |
| V-CON-1 | Regenerate `openapi.json`; diff against committed | No diff |
| V-CON-2 | Schema test: `PublicPerson` keys do not include `displayName` | Pass |
| V-OBS-1 | Run the API with the local collector; call `/api/me` | Span, metric point and log line share `trace_id` (AC-004); metric labels limited to route template, method and status class |
| V-OBS-2 | Call sessions with a contact, token and cookie; grep the collector output and logs for the raw values | No matches |
| V-SEC-1 | `git grep` for the pepper and secret values from the local `.env` | No matches |
| V-CI-1 | Run each CI step's command locally, and lint the workflow with `actionlint` if it's available | All pass. Green on GitHub is confirmed after the user pushes. |

**Preconditions:** Bun and Docker installed; `.env` copied from `.env.example` with local values.

**Known limitations:**
- V-CI-1 can only be confirmed on GitHub after the user pushes. Claude runs no git commands.
- V-OBS-1 checks the local collector only; Grafana Cloud export is verified in S10.

## Part B: Executed checks

All checks below ran on 2026-11-03 on macOS (Apple silicon) with Docker 29.8.1. Tests use `bun test` against the Compose Postgres; every test file gets a fresh database cloned from `velio_test`.

### Versions pinned

| Component | Version | Notes |
| --- | --- | --- |
| Bun | 1.4.4 | `packageManager`, `engines`, CI |
| Postgres | `postgres:18.6` | Latest stable tag |
| dbmate | `amacneil/dbmate:2.37.0` | Latest stable |
| OpenTelemetry Collector | `otel/opentelemetry-collector-contrib:0.164.0` | Latest stable |
| MinIO | `cgr.dev/chainguard/minio@sha256:3c60a2a8…5597` (RELEASE.2026-10-23T20-06-51Z) | Official images discontinued |
| hono · @hono/zod-openapi · @hono/otel | 4.13.16 · 1.6.3 · 1.3.0 | Latest |
| zod · kysely · kysely-postgres-js | 4.6.7 · 0.29.8 · 5.0.1 | Latest |
| postgres (postgres.js) | 3.4.9 | **Not latest:** 4.0.0 is outside `kysely-postgres-js`'s peer range |
| libphonenumber-js · pino | 1.13.15 · 10.4.0 | Latest |
| @opentelemetry/api · sdk-trace · sdk-metrics · resources · core · context-async-hooks | 1.10.0 · 3.0.0 · 3.0.0 · 3.0.0 · 3.0.0 · 3.0.0 | Latest |
| OTLP HTTP exporters · semantic-conventions | 0.300.0 · 1.44.0 | Latest |
| TypeScript | 6.0.3 | **Not latest:** 7.0.2 is outside typescript-eslint's peer range |
| eslint · typescript-eslint · prettier · kysely-codegen · pg | 10.14.0 · 8.72.1 · 3.9.10 · 0.20.0 · 8.23.1 | Latest |
| actions/checkout · oven-sh/setup-bun | v7.0.1 · v2.2.0 | Pinned by commit SHA |

### Results

| ID | Procedure | Result | Covers |
| --- | --- | --- | --- |
| T3 spike | Bun script: `@hono/otel` + SDK exporting to the local collector | **Pass.** Spans and metrics in the collector's debug output; same trace ID in middleware and handler. Fallback not needed. | NFR-002 |
| V-DX-1 | Copied the project (no `node_modules`, `.git` or `.env`) to a temp dir after `docker compose down -v`; ran `bun install && docker compose -f infra/docker-compose.yml up -d`, then `bun run db:migrate && bun test` | **Pass.** Both commands exit 0; 106 tests pass. | FR-002, NFR-005, AC-001 |
| V-DX-2 | `docker compose ps`; `curl 127.0.0.1:13133` | **Pass with exception.** Postgres and MinIO `healthy`; the collector is `Up` with no Docker health status (no shell in its image) and its health endpoint returns 200. | FR-003 |
| V-DB-1 | `test/db/integrity.test.ts` › migrated schema | **Pass.** 17 tables owned by `velio_owner`, including `communities`, `bookings.ref` and `rate_limits`; three roles; three communities; `velio_api` has DELETE only on `sessions` and `rate_limits`. | FR-004, FR-005 |
| V-DB-2 | › insert-only tables (6 tables × 3 tests) | **Pass.** `velio_api` gets 42501 on UPDATE and DELETE; `velio_owner` gets the trigger's VL002; INSERT and SELECT still work. | NFR-001, AC-002 |
| V-DB-3 | › users immutable columns | **Pass.** VL003 on `invite_generation` and `created_at`; `display_name` updates. | NFR-001 |
| V-DB-4 | › activity checks | **Pass.** `spots_left` < 0 or > capacity, capacity 0, price 0 and lowercase currency → 23514; invalid zone → VL004; a valid activity inserts. | NFR-001 |
| V-DB-5 | › unique constraints | **Pass.** 23505 on duplicate confirmed booking, second vouch claim, duplicate `ref` and duplicate attribution; removed duplicate booking and repeated public claims allowed. | NFR-001 |
| V-DB-6 | › activity location | **Pass.** Check errors for lat 91, lng −181, blank venue, 141-char meeting point; VL001 (`location_locked`) for lat, meeting point, starts_at, time zone and place_id after a confirmed booking; title and spot updates succeed; a removed booking doesn't lock. | FR-015 |
| V-API-1 | `test/api/health.test.ts` › health | **Pass.** `healthz` 200 with the DB unreachable; `readyz` 200 up, 503 down. | FR-006 |
| V-API-2 | › error envelope | **Pass.** Unknown error → 500 `internal` with `requestId` matching `X-Request-Id`, no message or stack; unknown route → `not_found`; SQLSTATE VL001 → 409 `location_locked`. | FR-010 |
| V-API-3 | `test/api/config.test.ts` | **Pass.** Spawned API with `CONTACT_PEPPER` unset exits non-zero and names it; empty values count as unset; production requires `ORIGIN_VERIFY_SECRET`. | FR-012 |
| V-ID-1 | `test/identity/contact.test.ts` | **Pass.** 8 normalisation rows (case, spaces, `+254 712…`, `0712…` with KE, UK formats) and 7 invalid inputs → `invalid_contact`; formats of one contact hash equal. | FR-009 |
| V-ID-2 | `test/identity/sessions.test.ts` › POST /api/sessions | **Pass.** `Zainab@Example.com ` and `zainab@example.com` → same user ID; `+254 712 345 678` and `0712345678` (KE) → same user; new user generation 0. | FR-007, FR-009, AC-003 |
| V-ID-3 | › web cookie and mobile bearer flows | **Pass.** Cookie is `HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=2592000` with no body token; mobile gets a 43-char token and no cookie; `/api/me` returns the same `MemberPerson`. | FR-007, FR-008, SEC-002 |
| V-ID-4 | › GET /api/me without a valid session | **Pass.** No token, unknown token, deleted session → 401 `unauthenticated`. | FR-008 |
| V-ID-5 | › storage | **Pass.** No raw contact in the `users` row or token in the `sessions` row; both hashes 32 bytes; stored hash = SHA-256(token). | SEC-001, SEC-002 |
| V-ID-6 | › session lifetime (injected clock) | **Pass.** Day-29 use extends expiry to now + 30 d; idle to day 31 → 401; weekly use to day 84 then day 91 → 401; idle expiry capped at the absolute expiry; two requests within 24 h → one renewal; renewed web session re-sets its cookie; expired rows purged. | FR-013, AC-006 |
| V-ID-7 | › rotation and sign-out | **Pass.** Re-sign-in with an existing cookie issues a new token and the old one gets 401; sign-out → 204, cookie cleared (`Max-Age=0`), token rejected; sign-out without a session → 401. | FR-014 |
| V-CON-1 | `bun run contracts:openapi`, then diff against the committed file | **Pass.** No diff. Paths: `/api/healthz`, `/api/readyz`, `/api/sessions`, `/api/me`, `/api/sessions/current`. | FR-011 |
| V-CON-2 | `packages/contracts/test/schemas.test.ts` | **Pass.** `PublicPerson` has no `displayName` and strips one if given. | SEC-005 |
| V-OBS-1 | (a) `test/telemetry/telemetry.test.ts` with in-memory exporters. (b) Live: API on :3911 exporting to the Compose collector; sign-in, `/api/me`, then read the collector's debug output. | **Pass.** (b) `/api/me` log line `trace_id` c5e5058e… = server span `GET /api/me` = parent of its `db.select` span; `http_server_duration_seconds` point labels exactly `route=/api/me, method=GET, status_class=2xx`; `db_pool_in_use` exported; unmatched paths share `route=unmatched`. | NFR-002, NFR-003, AC-004 |
| V-OBS-2 | (a) Telemetry test › redaction. (b) Live run above: grep the collector output and API log for the contact, the token and invite code `K7M2QX` | **Pass.** 0 matches for each in both. Logged path `/api/invites/:code`; span `url.full` is the redacted path without query. | SEC-003 |
| V-SEC-1 | No `.env` exists; searched the tree (excluding `node_modules`, `.git`, `spec`) for assigned secret variables, private keys and AWS key IDs | **Pass.** `.env.example` holds empty placeholders; the only match is a documentation placeholder in `infra/otel-collector.grafana.yaml`. `git grep` was not used: the new files are untracked until the user commits. | SEC-004 |
| V-CI-1 | Each CI step locally in order: `bun install --frozen-lockfile`, `format:check`, `lint`, `typecheck`, `compose up --wait postgres`, `db:migrate`, `db:codegen --verify`, `bun test`, `contracts:openapi` + diff; `actionlint` 1.7.12 (Docker) on `ci.yml` | **Pass.** All steps pass, 9 s locally; actionlint reports nothing. | NFR-004, AC-005 |

### Checks not run

- **CI green on GitHub (V-CI-1, AC-005) and merge blocking (NFR-004):** need the user to push and to protect `main`. Claude runs no git commands.
- **Grafana Cloud export:** out of scope for S1 (V-OBS-1 limitation); the overlay `infra/otel-collector.grafana.yaml` is written but unverified. Verified in S10.

### Known defects and deviations

See the PLANNING change log entry of 2026-11-03 15:14. In short: TypeScript 6.0.3 and postgres.js 3.4.9 are the newest compatible, not the newest released; MinIO comes from Chainguard; the collector has no Docker health status; CI starts Postgres through Compose.

**Final validation status:** Passed with exceptions (GitHub CI run pending the user's push; collector health checked from the host).
