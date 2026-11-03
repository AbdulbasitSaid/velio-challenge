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
| `bun test`                  | Unit and integration tests, against the Compose Postgres.                |
| `bun run typecheck`         | `tsc --noEmit` for every workspace.                                      |
| `bun run lint` · `bun run format` · `bun run format:check` | ESLint and Prettier.                      |
| `bun run dev`               | API with reload.                                                         |
| `bun run aws:synth` · `aws:diff` · `aws:deploy` · `aws:destroy` | CDK for the `VelioApp` stack in eu-west-2. Each needs `-c alertEmail=…`. |

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

### Deploys and rollback

Every push to `master` that passes CI deploys: the images are built for arm64, the bundle (Compose file, collector configs, `deploy.sh`, `backup.sh`) is uploaded to the deploy bucket, and `deploy.sh <sha>` runs on the instance through SSM. It writes `/opt/velio/.env` (root only) from Secrets Manager, migrates, then restarts the API. If the new API never becomes healthy, it starts the previous release again and the workflow fails. The workflow ends by checking `/api/healthz` and `/api/readyz` through CloudFront.

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
