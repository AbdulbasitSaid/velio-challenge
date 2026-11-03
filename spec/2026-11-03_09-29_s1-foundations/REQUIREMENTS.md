# Requirements: S1 Foundations

## Purpose and scope

The repository, workspace, database schema, identity, contracts, telemetry base and CI that all later delivery specs build on. Parent IDs (for example, parent SEC-001) refer to `spec/2026-11-03_07-42_group-bookings-mvp-plan/REQUIREMENTS.md`.

## Goals and non-goals

- **Goals:** reproducible setup; the complete schema with integrity enforced in Postgres; working lightweight identity; a single source for API contracts; telemetry from day one; green CI.
- **Non-goals:** booking, invites, realtime, metrics views, web or mobile apps, design tokens, AWS, k6. Those belong to S2–S10.

## Functional requirements

| ID | Requirement | Parent |
| --- | --- | --- |
| FR-001 | ~~The project is a git repository on `main`, with the existing docs as its first commit.~~ Removed 2026-11-03: the user owns git. S1 provides `.gitignore` only. | — |
| FR-002 | A Bun workspace contains `apps/api` and `packages/contracts`. `bun install` from a clean clone succeeds with the committed lockfile. | Plan §6 |
| FR-003 | `docker compose -f infra/docker-compose.yml up -d` starts healthy Postgres, MinIO and OTel Collector containers. | Plan §4.11 |
| FR-004 | `bun run db:migrate` applies every migration to an empty database. It creates the roles `velio_owner`, `velio_api` and `velio_readonly`, and every table in parent §4.3, including `communities`, `bookings.ref` and `rate_limits`. | Plan §4.3 |
| FR-005 | The three communities are present after migration. | PRD Q11 |
| FR-006 | `GET /api/healthz` returns 200 without touching the database. `GET /api/readyz` returns 200 only when a database query succeeds, and 503 otherwise. | — |
| FR-007 | `POST /api/sessions { displayName, contact }` normalises the contact, finds or creates the user (generation 0 when new), creates a session, and returns `MemberPerson`. Web clients get an httpOnly cookie; clients sending `X-Client: mobile` get a bearer token in the body. | Plan §4.6 |
| FR-008 | `GET /api/me` returns the caller's `MemberPerson` for a valid cookie or bearer token, and `401 unauthenticated` otherwise. | Plan §4.6 |
| FR-009 | The same contact in different formats (case, spaces, `+254…` versus `0…` with a country hint) maps to the same user. | R5 |
| FR-010 | All API errors use `{ error: { code, message, requestId } }`, with codes from the contracts union. Unknown errors return `internal`, never a stack trace. | Plan §4.4 |
| FR-011 | `packages/contracts` exports `ErrorEnvelope`, the error-code union, `PublicPerson`, `MemberPerson`, `SessionCreate`, `SessionResponse` and `Health`. `openapi.json` is generated from the mounted routes. | Plan §4.8 |
| FR-012 | The API fails to start, with a message naming the missing or invalid variable, if the configuration is invalid. | — |
| FR-013 | Sessions expire after 30 days without use (sliding; renewal at most once per 24 h) and 90 days after creation regardless of use. Both values are config. An expired session gets `401 unauthenticated`. | PLANNING §4.4 |
| FR-014 | `POST /api/sessions` always issues a fresh token and revokes any session presented with the request. `DELETE /api/sessions/current` revokes the caller's session and clears the cookie. | PLANNING §4.4 |
| FR-015 | `activities` stores `place_id` (nullable), `venue_name`, `address_text`, `lat`, `lng` and `meeting_point` (nullable, ≤ 140 chars) with range checks. Once an activity has a confirmed booking, a trigger rejects changes to its date, time zone or any location field with `location_locked`. | PRD A1, A4, Q2, Q13; Maps spec FR-005 |

## Non-functional requirements

| ID | Requirement | Parent |
| --- | --- | --- |
| NFR-001 | Database integrity is enforced by Postgres: insert-only tables reject UPDATE and DELETE for every role (trigger) and lack those grants for `velio_api`; `users.invite_generation` and `created_at` cannot change; the check constraints in PLANNING §4.3 hold. | Parent NFR-001, SEC-001 |
| NFR-002 | Every HTTP request produces a span and `http_server_duration_seconds`, labelled by route template, method and status class only. DB calls produce child spans named by operation only. | Parent NFR-010, NFR-011 |
| NFR-003 | Logs are JSON, carrying `trace_id` and `request_id`. | Parent NFR-011 |
| NFR-004 | CI runs format, lint, type check, migrations, codegen drift, tests and OpenAPI drift on every push and PR, and blocks merge to `main` on failure. | Plan §5 |
| NFR-005 | A fresh clone reaches green tests in two documented commands, given only Bun and Docker. | — |

## Security and privacy

| ID | Requirement | Parent |
| --- | --- | --- |
| SEC-001 | Contacts are stored only as `HMAC-SHA256(CONTACT_PEPPER, normalised)`. S1 stores no raw contact anywhere; raw vouch contacts arrive in S4. | Parent SEC-004 |
| SEC-002 | Session tokens are 32 random bytes; only their SHA-256 is stored. The cookie is `HttpOnly; Secure; SameSite=Lax; Path=/`, with `Max-Age` equal to the idle timeout. | Parent SEC-007 |
| SEC-003 | Logs, spans and metrics never contain contact, token, cookie, authorization or note values, or invite codes. | Parent SEC-011 |
| SEC-004 | No secret is committed. `.env.example` holds placeholders only. | — |
| SEC-005 | Public schemas (`PublicPerson`) contain no `displayName` field. | Parent SEC-012 |

## Acceptance criteria

- **AC-001:** on a clean machine with Bun and Docker, the README's two commands result in `bun test` passing.
- **AC-002:** UPDATE and DELETE on each insert-only table fail for both `velio_api` and `velio_owner`.
- **AC-003:** `POST /api/sessions` twice with `Zainab@Example.com ` and `zainab@example.com` returns the same user ID.
- **AC-004:** a request appears in the local collector as a span plus an `http_server_duration_seconds` data point, and its log line carries the same `trace_id`.
- **AC-005:** every CI step's command passes locally. Green on GitHub is confirmed once the user pushes.
- **AC-006:** a session idle beyond 30 days, or older than 90 days, is rejected. A session used within the window is extended, at most once per 24 h.

## Error handling

Covered by FR-010 and FR-012. Database unavailability results in `readyz` 503 and `internal` on data routes.

## Compatibility

The latest stable releases at implementation time, each pinned exactly:
- Bun, in `package.json` `engines` and CI;
- Postgres and dbmate, by exact image tag;
- npm dependencies, through `bun.lock`.

The chosen versions are recorded in Part B of `VALIDATION.md`.

## Data and migration

New schema. Forward-only migrations. The seeded communities are reference data.

## Dependencies

hono, @hono/zod-openapi, zod, kysely, postgres (postgres.js), kysely-codegen, libphonenumber-js, pino, @opentelemetry/* packages and @hono/otel (subject to T3), dbmate (container image), eslint, prettier, typescript.

## Explicitly excluded

Booking transaction, invite logic, the hash-chain computation, LISTEN/NOTIFY, WebSocket routes, metrics views, rate-limit logic (the table only), web app, Flutter, design tokens, AWS, Grafana dashboards, k6.
