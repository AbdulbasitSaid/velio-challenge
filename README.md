# Velio Group Bookings

Hosts list activities with fixed spots, bookers reserve and invite friends into a shared Plan, and guests claim spots from a link or code. Product intent: [`Velio Group Bookings PRD.md`](Velio%20Group%20Bookings%20PRD.md). Development rules: [`CLAUDE.md`](CLAUDE.md). Status: [`ROADMAP.md`](ROADMAP.md).

This is the S1 foundation ([spec](spec/2026-11-03_09-29_s1-foundations/)): the workspace, database schema, lightweight identity, contracts, telemetry base and CI. It has no booking, invite, realtime or UI behaviour yet.

## Setup

You need [Bun](https://bun.com) 1.4.4 and Docker. From a fresh clone:

```sh
bun install && docker compose -f infra/docker-compose.yml up -d
bun run db:migrate && bun test
```

`db:migrate` migrates two databases: `velio` (development) and `velio_test` (the template each test file clones).

To run the API, copy `.env.example` to `.env`, set `CONTACT_PEPPER` (`openssl rand -base64 48`), then:

```sh
bun run dev        # http://localhost:3001/api/healthz
```

## Layout

| Path                     | What                                                                        |
| ------------------------ | --------------------------------------------------------------------------- |
| `apps/api`               | Bun + Hono API. Routes live under `/api`.                                   |
| `apps/api/migrations`    | Forward-only SQL migrations, run by dbmate.                                 |
| `apps/api/src/db/types.ts` | Kysely types, generated from the migrated database. Do not edit.          |
| `packages/contracts`     | Zod schemas shared by API and clients, and the generated `openapi.json`.    |
| `infra`                  | Local Docker Compose (Postgres, MinIO, OpenTelemetry Collector).            |
| `.github/workflows/ci.yml` | Format, lint, types, migrations, codegen drift, tests, OpenAPI drift.     |

## Scripts

| Command                     | Does                                                                     |
| --------------------------- | ------------------------------------------------------------------------ |
| `bun run db:migrate`        | Applies pending migrations to `velio` and `velio_test`.                  |
| `bun run db:codegen`        | Regenerates `apps/api/src/db/types.ts`. Add `--verify` to check only.    |
| `bun run contracts:openapi` | Regenerates `packages/contracts/openapi.json` from the mounted routes.   |
| `bun test`                  | Unit and integration tests, against the Compose Postgres.                |
| `bun run typecheck`         | `tsc --noEmit` for every workspace.                                      |
| `bun run lint` · `bun run format` · `bun run format:check` | ESLint and Prettier.                      |
| `bun run dev`               | API with reload.                                                         |

After changing a migration or a route, run `db:codegen` or `contracts:openapi` and commit the result; CI fails on drift.

## Environment

All variables are documented in [`.env.example`](.env.example). The API refuses to start, naming the variable, if one is missing or invalid.

| Variable                      | Notes                                                                   |
| ----------------------------- | ----------------------------------------------------------------------- |
| `DATABASE_URL`                | Runtime connection as `velio_api`.                                      |
| `DATABASE_LISTEN_URL`         | Direct connection for `LISTEN` (used from S3).                          |
| `CONTACT_PEPPER`              | Secret keying contact hashes. Changing it orphans every existing user.  |
| `ORIGIN_VERIFY_SECRET`        | CloudFront's `X-Origin-Verify` value. Required in production only.      |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Local collector: `http://localhost:4318`. Empty disables export.        |
| `LOG_LEVEL`                   | pino level.                                                             |
| `SESSION_IDLE_DAYS`, `SESSION_ABSOLUTE_DAYS` | Session lifetimes, default 30 and 90.                    |

## Database

- Roles: `velio_owner` owns the schema (migrations switch to it), `velio_api` is the runtime role, `velio_readonly` is for metrics views. Locally they have no passwords: the Compose Postgres uses trust auth on `127.0.0.1` only.
- Insert-only tables (`invites`, `invite_claims`, `attributions`, `trust_edges`, `attendance_marks`, `booking_removals`) reject `UPDATE` and `DELETE` twice: `velio_api` lacks the grants, and a trigger rejects them for every role.
- Trigger errors use SQLSTATE class `VL`: `VL001` location locked, `VL002` insert-only, `VL003` immutable column, `VL004` invalid time zone.

## Telemetry

The API exports traces and metrics over OTLP to the local collector, which prints them (`docker compose -f infra/docker-compose.yml logs -f otel-collector`). Logs are JSON on stdout with `trace_id` and `request_id`. Contacts, tokens, cookies, notes and invite codes are redacted.

To also send to Grafana Cloud from your machine, set `OTEL_COLLECTOR_EXTRA_CONFIG=/etc/otelcol/grafana.yaml`, `GRAFANA_OTLP_ENDPOINT` and `GRAFANA_OTLP_AUTH` (see `infra/otel-collector.grafana.yaml`) and restart the collector. Production wiring is S10.

## Repository

Protect `main` so the CI workflow must pass before merging.
