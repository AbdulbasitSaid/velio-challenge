# Velio Group Bookings

Hosts list activities with fixed spots, bookers reserve and invite friends into a shared Plan, and guests claim spots from a link or code. Product intent: [`Velio Group Bookings PRD.md`](Velio%20Group%20Bookings%20PRD.md). Development rules: [`CLAUDE.md`](CLAUDE.md). Status: [`ROADMAP.md`](ROADMAP.md).

Built so far: the S1 foundation ([spec](spec/2026-11-03_09-29_s1-foundations/)), which covers the workspace, database schema, lightweight identity, contracts, telemetry base and CI; and the S2 booking core ([spec](spec/2026-11-03_22-30_s2-booking-core/)), which covers the activity create and edit API, direct booking, host removal and capacity changes, all of which cannot oversell. It has no invite, realtime or UI behaviour yet.

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
bun run web:dev    # http://localhost:3000 (Next.js; proxies /api/* to :3001, the socket connects to :3001)
```

## Layout

| Path                     | What                                                                        |
| ------------------------ | --------------------------------------------------------------------------- |
| `apps/api`               | Bun + Hono API. Routes live under `/api`.                                   |
| `apps/api/migrations`    | Forward-only SQL migrations, run by dbmate.                                 |
| `apps/api/src/db/types.ts` | Kysely types, generated from the migrated database. Do not edit.          |
| `apps/web`               | Next.js web app (App Router, run on Node): pages, design-system components, API and realtime clients. Vitest tests in `test/`. |
| `apps/mobile`            | Flutter app for iOS and Android (S7, S7b): code entry, invite, claim, Plan, My plans, offline cache, native map, App Links, plus the web's booker and host flows (communities, booking, Host / Booker toggle, create and edit, live attendance). Not a Bun workspace member. |
| `packages/contracts`     | Zod schemas shared by API and clients, and the generated `openapi.json`.    |
| `packages/api-client-dart` | Dart client `velio_api`, generated from `openapi.json`. Do not edit `lib/`. |
| `packages/design-tokens` | The approved `tokens.json` and its generated outputs: `css/theme.css` (Tailwind 4 theme) and `dart/` (the `velio_tokens` Flutter package). Shared avatar hash fixtures. |
| `load`                   | k6 load tests: `seed.ts` and `check.ts` (Bun), `scenarios/` (k6). Results go to `load/results/` (git-ignored). |
| `infra`                  | Local Docker Compose (Postgres, MinIO, OpenTelemetry Collector), and the production Compose and collector configs. |
| `infra/aws`              | CDK app for the AWS stack (`VelioApp`), its tests, and the instance scripts (`scripts/`). |
| `.github/workflows/ci.yml` | Format, lint, types, migrations, codegen drift, tests, OpenAPI drift.     |
| `.github/workflows/deploy.yml` | Builds the images and deploys `master` after CI passes.               |

## Scripts

| Command                     | Does                                                                     |
| --------------------------- | ------------------------------------------------------------------------ |
| `bun run db:migrate`        | Applies pending migrations to `velio` and `velio_test`.                  |
| `bun run db:codegen`        | Regenerates `apps/api/src/db/types.ts`. Add `--verify` to check only.    |
| `bun run contracts:openapi` | Regenerates `packages/contracts/openapi.json` from the mounted routes.   |
| `bun run contracts:dart`    | Regenerates the Dart client from `openapi.json` (Docker and Flutter). CI fails on drift. |
| `bun test`                  | Unit and integration tests, against the Compose Postgres.                |
| `bun run typecheck`         | `tsc --noEmit` for every workspace.                                      |
| `bun run lint` · `bun run format` · `bun run format:check` | ESLint and Prettier.                      |
| `bun run dev`               | API with reload.                                                         |
| `bun run web:dev` · `web:build` · `web:test` | Next.js dev server, production build, Vitest.            |
| `bun apps/api/scripts/seed-invites.ts` | Local only: one invite per invite-page state (S6), printed as links. Needs `bun run dev` and `web:dev`. |
| `bun run tokens:build`      | Regenerates the token outputs from `packages/design-tokens/tokens.json`. CI fails on drift. |
| `bun run load:smoke`        | k6 `last_spot_race` smoke against the local API (needs `bun run dev` running). |
| `bun run load:viewers`      | k6 `viewers` smoke: 250 sockets watch a `last_spot_race` (needs `bun run dev` running). |
| `bun run aws:synth` · `aws:diff` · `aws:deploy` · `aws:destroy` | CDK for the `VelioApp` stack in eu-west-2. Each needs `-c alertEmail=…`. |

After changing a migration or a route, run `db:codegen` or `contracts:openapi` (then `contracts:dart`) and commit the result; CI fails on drift.

## Mobile app

Flutter 3.47.9 (pinned in `.fvmrc`; `fvm` or a matching `flutter` on PATH). iOS 15+ and Android 8 (API 26)+. Design and checks: [`spec/2026-11-04_12-50_s7-flutter-app/`](spec/2026-11-04_12-50_s7-flutter-app/).

```bash
cd apps/mobile
flutter pub get
flutter test                                  # unit and widget tests (360 px and 200% text)
flutter run                                   # against the deployed stack
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001   # Android emulator → local Compose
flutter run --dart-define=API_BASE_URL=http://localhost:3001  # iOS simulator → local Compose
flutter test integration_test --dart-define=SMOKE_CODE=<claimable vouch code>   # books a spot
flutter test integration_test/parity_test.dart --dart-define=API_BASE_URL=http://localhost:3001   # local only: books, publishes, removes
```

- **Maps:** without keys the app shows the address and directions instead of a map. To show native maps, put `MAPS_ANDROID_KEY=…` in `apps/mobile/android/secrets.properties` and `MAPS_IOS_KEY = …` in `apps/mobile/ios/Flutter/Secrets.xcconfig` (both git-ignored), and add `--dart-define=MAPS=true` (exactly `true`: `MAPS=1` leaves maps off).
- **Places search (host create form):** add `--dart-define=PLACES_KEY=…` (a key with Places API (New), ideally restricted to the app; on Android also `--dart-define=ANDROID_CERT_SHA1=…` for the restriction). Without it, hosts drop a pin or type the coordinates.
- **App Links (Android):** links to `https://<host>/i/<code>` open the app when the host's `/.well-known/assetlinks.json` lists the package and the SHA-256 of the keystore that signed the build (`ANDROID_PACKAGE`, `ANDROID_CERT_SHA256` on the web container). Builds are signed with the local debug keystore. iOS opens the web page; the app is reached by code entry (no Apple Developer account).
- The app isn't distributed: run it from here on a simulator, emulator or cabled phone.

## Environment

All variables are documented in [`.env.example`](.env.example). The API refuses to start, naming the variable, if one is missing or invalid.

| Variable                      | Notes                                                                   |
| ----------------------------- | ----------------------------------------------------------------------- |
| `DATABASE_URL`                | Runtime connection as `velio_api`.                                      |
| `DATABASE_LISTEN_URL`         | Direct connection for realtime `LISTEN`. Never through a pooler.        |
| `CONTACT_PEPPER`              | Secret keying contact hashes. Changing it orphans every existing user.  |
| `ORIGIN_VERIFY_SECRET`        | CloudFront's `X-Origin-Verify` value. Required in production only.      |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Local collector: `http://localhost:4318`. Empty disables export.        |
| `LOG_LEVEL`                   | pino level.                                                             |
| `SESSION_IDLE_DAYS`, `SESSION_ABSOLUTE_DAYS` | Session lifetimes, default 30 and 90.                    |
| `PUBLIC_BASE_URL` | Origin of invite links (`<origin>/i/<code>`). Required in production; defaults to `http://localhost:3000`. |
| `LINK_CLAIMS_PER_MINUTE`, `AUTO_PAUSE_MIN_OPENS` | Public-link abuse limits (PRD R7), default 60 and 200. |

## Database

- Roles: `velio_owner` owns the schema (migrations switch to it), `velio_api` is the runtime role, `velio_readonly` is for metrics views. Locally they have no passwords: the Compose Postgres uses trust auth on `127.0.0.1` only.
- Insert-only tables (`invites`, `invite_claims`, `attributions`, `trust_edges`, `attendance_marks`, `booking_removals`) reject `UPDATE` and `DELETE` twice: `velio_api` lacks the grants, and a trigger rejects them for every role.
- `invites` and `attributions` carry a hash chain per activity. A `BEFORE INSERT` trigger sets `chain_seq`, `prev_hash` and `row_hash` under the activity row lock, whatever the caller sent. `SELECT * FROM audit_chain('<activity id>')` (or `audit_all_chains()`) recomputes both chains and returns the first broken `chain_seq` per table; a clean chain returns no rows.
- Trigger errors use SQLSTATE class `VL`: `VL001` location locked, `VL002` insert-only, `VL003` immutable column, `VL004` invalid time zone.

## Booking engine

`apps/api/src/modules/bookings/engine.ts` is the only code that writes `activities.spots_left`. A booking takes its spot with one conditional `UPDATE … WHERE spots_left > 0`, inside the transaction that creates the Plan and the booking, so the last spot can be taken only once. The `CHECK` constraint is the backstop. Retries send the same `Idempotency-Key` header and get the original booking back with `200`. Every committed change to `spots_left` bumps `activities.version` and sends `pg_notify('activity_spots', …)`.

- `bun test` includes `apps/api/test/concurrency/last-spot.test.ts`: 200 parallel HTTP bookers for 1, 5 and 14 spots, exactly N succeed. It also covers same-key retries, removal and capacity races.
- `bun run load:smoke` runs the same race through k6 (25 VUs per activity, the `grafana/k6` image under the Compose `load` profile), then checks the database for oversold activities. Seeded data stays in the development database, named `Load <runId> …`.
- The kill switch is `activities.bookings_paused`. Until S8 adds the admin endpoint, set it in SQL.

## Invites and claims

- `POST /api/plans/:id/invites` creates a vouch (one named person, single use; the contact is stored only as a keyed hash) or returns the member's public link. `GET /api/invites/:code` is the public invite page's data; `POST /api/invites/:code/opens` is the beacon the page sends after rendering.
- `POST /api/invites/:code/claims` is a booking through the same engine as a direct booking (`Idempotency-Key` required). A guest without a session sends `displayName` and `contact`; a new guest is created inside the claim transaction with generation = inviter's + 1, and gets the attribution row and a session. Two parallel claims of one vouch give one booking.
- More than 10 unknown codes from one device (`X-Device-Id`, else the client IP) in an hour lock that device out of every code until the hour ends. Public links take at most `LINK_CLAIMS_PER_MINUTE` claim attempts a minute and pause themselves after `AUTO_PAUSE_MIN_OPENS` opens in an hour with under 2% claimed; the creator or host resumes them with `DELETE /api/invites/:code/pause`.
- Read APIs for the clients: `GET /api/plans/:id`, `/api/me/plans`, `/api/host/activities`, `/api/host/activities/:id/attendance` (and `POST /api/host/bookings/:id/attendance` to mark), `/api/communities`, `/api/communities/:slug`, `/api/users/:id/profile` and `/api/activities/:id/next-steps`.

## Realtime

`GET /api/activities/:id` is the public snapshot (spots left, `version`, members as "Tunde A."). `GET /api/ws?platform=web|ios|android` upgrades to a WebSocket. Clients subscribe to `activity:<id>` (anyone), `plan:<id>` (Plan members) or `host:<activityId>` (the host), and receive `spots`, `plan`, `attendance` and `resync` messages. The protocol and the client rules (subscribe before fetching the snapshot, ignore older versions, poll every 10 s while disconnected) are in `packages/contracts/src/realtime.ts`.

- Each API process holds one `LISTEN` connection (`apps/api/src/modules/realtime/listener.ts`) on `activity_spots`, `plan_changed` and `attendance_changed`. If it drops, the listener reconnects and sends `resync` to every subscribed topic. `/api/readyz` returns 503 while it isn't listening.
- Clients send `{type:"rendered", activityId, version}` after painting; `realtime_commit_to_ack_seconds` is the PRD's live-update latency, measured on the server clock.
- Try it from a browser console on a running API: `ws = new WebSocket('ws://localhost:3001/api/ws?platform=web'); ws.onmessage = (e) => console.log(e.data); ws.onopen = () => ws.send(JSON.stringify({type: 'subscribe', topics: ['activity:<id>']}))`.

## Telemetry

The API exports traces and metrics over OTLP to the local collector, which prints them (`docker compose -f infra/docker-compose.yml logs -f otel-collector`). Logs are JSON on stdout with `trace_id` and `request_id`. Contacts, tokens, cookies, notes and invite codes are redacted.

To also send to Grafana Cloud from your machine, set `OTEL_COLLECTOR_EXTRA_CONFIG=/etc/otelcol/grafana.yaml`, `GRAFANA_OTLP_ENDPOINT` and `GRAFANA_OTLP_AUTH` (see `infra/otel-collector.grafana.yaml`) and restart the collector. Production wiring: see [Grafana Cloud](#grafana-cloud).

## Production (AWS)

One `t4g.small` instance in eu-west-2 runs Docker Compose (Postgres, the API, the OpenTelemetry Collector) behind CloudFront on its `cloudfront.net` hostname. The instance accepts only CloudFront on port 3001, and the API rejects requests without CloudFront's `X-Origin-Verify` header. It has no SSH; use SSM. Design and checks: [`spec/2026-11-03_16-15_s10-aws-app-stack/`](spec/2026-11-03_16-15_s10-aws-app-stack/).

### First-time setup

You need an AWS CLI session (`aws login`) with administrator rights, and the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for shell access.

```sh
export AWS_REGION=eu-west-2
bun run --cwd infra/aws cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/eu-west-2   # once per account
bun run aws:deploy -c alertEmail=you@example.com
```

The alarm email is passed on every deploy and never committed (the repository is public). Confirm the subscription email AWS sends. `cdk.out/` holds the synthesised template, including the email, and is git-ignored.

Then, once:

1. Set the repository variable `AWS_DEPLOY_ROLE_ARN` to the stack's `DeployRoleArn` output (GitHub → Settings → Secrets and variables → Actions → Variables).
2. Push to `master`. When CI passes, the Deploy workflow pushes `ghcr.io/abdulbasitsaid/velio-api` and `velio-migrate` for the first time.
3. Make both packages public (GitHub → your profile → Packages → package → Package settings → Change visibility). The instance pulls without credentials. Rerun the Deploy workflow if it failed on the pull.

`velio:createGithubOidcProvider` in `infra/aws/cdk.json` is `false` because this account already has GitHub's OIDC provider. Set it to `true` in an account without one.

### AWS quotas

The security group admits CloudFront on two ports through the `com.amazonaws.global.cloudfront.origin-facing` prefix list, which counts as about 55 rules each time it is used. The default of 60 rules per security group fits one, so eu-west-2 needs the quota raised to 120 before the stack has both (once per account):

```sh
aws service-quotas request-service-quota-increase --region eu-west-2 \
  --service-code vpc --quota-code L-0EA8095F --desired-value 120
```

### Deploys and rollback

Every push to `master` that passes CI deploys: the images are built for arm64, the bundle (Compose file, collector configs, `deploy.sh`, `backup.sh`) is uploaded to the deploy bucket, and `deploy.sh <sha> <photos bucket>` runs on the instance through SSM (the bucket is the stack's `PhotosBucket` output). It writes `/opt/velio/.env` (root only) from Secrets Manager, migrates, then restarts the API. If the new API never becomes healthy, it starts the previous release again and the workflow fails. The workflow ends by checking `/api/healthz` and `/api/readyz` through CloudFront.

To roll back, run the Deploy workflow by hand (Actions → Deploy → Run workflow, on `master`) with the earlier commit's SHA.

### Grafana Cloud

Until the `velio/prod/grafana` secret is filled in, the collector exports nothing and deploys still succeed. To turn export on:

1. Sign up at [grafana.com](https://grafana.com) (free tier) and create a stack in an EU region (London if offered).
2. In the stack: Connections → OpenTelemetry (OTLP). Note the OTLP endpoint and instance ID, and create an access-policy token with only `metrics:write`, `logs:write` and `traces:write`.
3. Store them, then redeploy (rerun the Deploy workflow):

```sh
aws secretsmanager put-secret-value --region eu-west-2 --secret-id velio/prod/grafana \
  --secret-string '{"endpoint":"https://otlp-gateway-<zone>.grafana.net/otlp","instanceId":"<id>","token":"<token>"}'
```

Traces are tail-sampled: every error, everything over 1 s, and 10% of the rest. API logs carry `trace_id`, so a log line links to its trace.

### Shell access

```sh
aws ssm start-session --region eu-west-2 --target <InstanceId output>
sudo -i
cd /opt/velio && cat current     # the live commit
docker compose -p velio ps
docker logs --tail 100 velio-api-1
```

### Backups and restore

`velio-backup.timer` dumps the database at 02:00 UTC to the backups bucket (`pg_dump -Fc`, kept 14 days). The instance's volume is also snapshotted daily at 03:00 UTC, keeping 7. To dump now: `sudo /opt/velio/backup.sh`.

To restore a dump, on the instance:

```sh
source /opt/velio/stack.env
aws s3 ls "s3://$BACKUP_BUCKET/"                                 # pick a file
aws s3 cp "s3://$BACKUP_BUCKET/<file>.dump" /tmp/velio.dump
docker cp /tmp/velio.dump velio-postgres-1:/tmp/velio.dump
docker exec velio-postgres-1 createdb -U postgres velio_restore
docker exec velio-postgres-1 pg_restore -U postgres -d velio_restore --no-owner /tmp/velio.dump
```

Check `velio_restore`. To make it live, stop the API (`docker stop velio-api-1`), rename the databases (`ALTER DATABASE velio RENAME TO velio_old; ALTER DATABASE velio_restore RENAME TO velio;`), then rerun the Deploy workflow. The rerun restores ownership, grants and role passwords through migrations.

### Updating the AMI

The AMI ID is pinned in `infra/aws/bin/app.ts`. To move to a newer Amazon Linux 2023 release, look up `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64` in SSM Parameter Store. Changing it replaces the instance and its root volume: take a fresh backup first, restore it afterwards, then redeploy.

### Teardown

```sh
bun run aws:destroy -c alertEmail=you@example.com
```

This keeps the backups bucket and the instance's root volume, which hold the data. Delete them by hand when you no longer need them. The secrets enter a 7–30 day recovery window that reserves their names. Before redeploying sooner, delete each one with `aws secretsmanager delete-secret --force-delete-without-recovery --secret-id velio/prod/<name>`.

## Repository

Protect `main` so the CI workflow must pass before merging.
