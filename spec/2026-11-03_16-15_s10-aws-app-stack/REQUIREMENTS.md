# Requirements: S10a AWS App Stack

## Purpose and scope

The hosted environment for the API on AWS eu-west-2, its automatic deploy, Grafana Cloud export and backups. Parent IDs refer to `spec/2026-11-03_07-42_group-bookings-mvp-plan/REQUIREMENTS.md`.

## Goals and non-goals

- **Goals:** a reproducible CDK stack; the S1 API live behind CloudFront; deploy on every green push to `master`; telemetry in Grafana Cloud; nightly backups with a tested restore.
- **Non-goals:** the web app and its origin (S5), deep-link files (S5/S6), Google Maps secrets (S2/S5), dashboards and alerts (S8), the load-runner stack (S10b), a custom domain, the encrypted origin hop (parent SEC-009, before GA).

## Functional requirements

| ID | Requirement | Parent |
| --- | --- | --- |
| FR-001 | `bun run aws:deploy` creates or updates the `VelioApp` stack in eu-west-2, after a one-time CDK bootstrap. `bun run aws:destroy` removes it, except the retained data volume and backup bucket. | Plan §4.11 |
| FR-002 | `https://<distribution>.cloudfront.net/api/healthz` and `/api/readyz` return 200 from the live API. | ROADMAP Phase 1 |
| FR-003 | CloudFront routes `/api/*` and `/ws` to the API without caching, forwarding cookies, headers (except `Host`) and query strings; `/photos/*` to the photos bucket through OAC, cached; the default behavior to the API until S5. HTTP redirects to HTTPS. | Plan §4.11 |
| FR-004 | A push to `master` that passes CI builds the `api` and `migrate` images, runs migrations, restarts the API and smoke-checks `/api/healthz` and `/api/readyz` through CloudFront. A failed step fails the workflow. | Plan §4.11 |
| FR-005 | The deploy can be rerun for any earlier commit with `workflow_dispatch`. | — |
| FR-006 | Postgres is dumped nightly to the backups bucket and kept 14 days; the volume is snapshotted daily and kept 7 days. A documented restore procedure recovers a dump. | Plan §4.11 |
| FR-007 | The collector on the instance exports API traces, API and host metrics, Postgres metrics and API logs to Grafana Cloud, with tail sampling as in parent §4.12. | Plan §4.12, NFR-010, NFR-011 |
| FR-008 | The README documents: bootstrap, first deploy, Grafana Cloud setup, shell access through SSM, restore and teardown. | — |
| FR-009 | A failed EC2 status check triggers automatic recovery and an email to the address given at deploy time. | Plan §4.11 |
| FR-010 | The `api` and `migrate` images are published to GHCR and can be pulled anonymously once the user makes the packages public. | Plan §4.11 |
| FR-011 | An AWS budget sends an email alert at the amount the user chooses. Done last. | — |

## Non-functional requirements

| ID | Requirement | Parent |
| --- | --- | --- |
| NFR-001 | Every image, AMI, action and library version is pinned exactly (image tag or digest, cached AMI ID, action commit SHA, lockfile). | CLAUDE.md |
| NFR-002 | Telemetry from the live API appears in Grafana Cloud within 1 minute of the request. | Parent NFR-010 |
| NFR-003 | The stack is defined entirely in code; no console-only resources except the Grafana Cloud stack and the Grafana secret's value. | Plan §4.11 |
| NFR-004 | A routine deploy (no infrastructure change) completes in under 10 minutes [Assumption: target for speed, not from the PRD]. | — |

## Security and privacy

| ID | Requirement | Parent |
| --- | --- | --- |
| SEC-001 | The instance accepts inbound traffic only on port 3001 from CloudFront's origin-facing prefix list. No SSH port is open; shell access is through SSM only. IMDSv2 is required. | Parent SEC-009 |
| SEC-002 | Requests to the origin without the correct `X-Origin-Verify` header get 403, except `/api/healthz`. The header value is not in the CloudFormation template, the repository or GitHub. | Parent SEC-009 |
| SEC-003 | All app secrets are generated in Secrets Manager (Grafana token entered by hand) and reach containers only through a root-owned, mode-600 env file on the instance. No AWS keys or app secrets are stored in GitHub. | Parent SEC-004 |
| SEC-004 | GitHub Actions authenticates through OIDC to a role trusted only for `refs/heads/master` of `AbdulbasitSaid/velio-challenge`, with only deploy-bucket write and SSM `SendCommand` to the app instance. | — |
| SEC-008 | The deploy workflow runs only for CI runs triggered by a push to `master` of this repository; runs from fork pull requests never deploy. | — |
| SEC-009 | Nothing secret is committed to the public repository, including the alarm email address; a gitleaks scan of history and working tree is clean before the repository goes public and before each spec closes. | — |
| SEC-005 | Postgres is not reachable from outside the Compose network. `velio_api` has a password in production. | Parent SEC-001 |
| SEC-006 | S3 buckets block public access and are encrypted; photos are readable only through CloudFront OAC. | — |
| SEC-007 | The Grafana token has only `metrics:write`, `logs:write` and `traces:write`. Exported telemetry keeps S1's redaction (no contacts, tokens, cookies, notes or codes). | Parent SEC-011 |

## Acceptance criteria

- **AC-001:** after a push to `master`, CI and deploy both go green on GitHub, and `curl https://<domain>/api/readyz` returns `{"status":"ok"}`.
- **AC-002:** a direct request to the instance's public IP on port 3001 from outside AWS times out (security group), and on the instance a request without the correct `X-Origin-Verify` header gets 403.
- **AC-003:** a request through CloudFront shows up in Grafana Cloud as a trace, an `http_server_duration_seconds` point and a log line with the same `trace_id`.
- **AC-004:** a backup file from the nightly script restores into a scratch database with the same table row counts.
- **AC-005:** the stack synthesises and its assertion tests pass in CI.

## Business rules and edge cases

- A failing migration stops the deploy before the API restarts.
- If the Grafana secret is empty, the collector still starts and the deploy succeeds (export disabled), so the API can go live before the Grafana stack exists.

## Error handling

Deploy failures surface as a failed workflow with the SSM command output. Backup failures are logged to the journal and, from S8, alerted on.

## Performance and reliability

Single instance, single point of failure (accepted, parent §4.11). EC2 auto-recovery on a failed system status check.

## Compatibility

Pinned versions recorded in `VALIDATION.md` Part B.

## Data and migration

The production database starts empty and is migrated by the `migrate` image on every deploy (idempotent).

## Dependencies and integrations

AWS (EC2, VPC, CloudFront, S3, Secrets Manager, SSM, DLM, IAM, CloudWatch, SNS, Budgets), GHCR, GitHub Actions OIDC, Grafana Cloud OTLP.

## Explicitly excluded

Web origin, deep-link files, Maps keys, dashboards and alerts, load-runner stack, custom domain, origin TLS, nothing else; the AWS budget alarm is in scope as the last task (FR-011).
