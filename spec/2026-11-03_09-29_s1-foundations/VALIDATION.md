# Validation: S1 Foundations

## Part A: Planned checks

### Spec review checklist

- [ ] Every FR, NFR and SEC requirement maps to a check below.
- [ ] Nothing outside parent S1 scope is included.
- [ ] Open questions in PLANNING §10 are answered before implementation.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001 | Removed (the user owns git) |
| FR-002, NFR-005, AC-001 | V-DX-1 |
| FR-003 | V-DX-2 |
| FR-004, FR-005 | V-DB-1 |
| NFR-001, AC-002 | V-DB-2, V-DB-3, V-DB-4, V-DB-5 |
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

Not run. Implementation has not been authorized.

**Final validation status:** Not run.
