# Planning: S10a AWS App Stack

- **Spec ID:** 2026-11-03_16-15_s10-aws-app-stack
- **Created:** 2026-11-03 16:15 (local)
- **Status:** Approved for implementation (paused: deployment deferred, see change log)
- **Parent:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (approved), delivery step S10, Phase 1 part ("app stack")
- **Builds on:** `spec/2026-11-03_09-29_s1-foundations/` (implemented)
- **PRD:** `Velio Group Bookings PRD.md`

Claims are tagged **[Verified]**, **[Assumption]**, **[Proposal]** or **[Decided]**.

## 1. Problem statement

S1 runs only on a laptop. Phase 1's exit criteria (ROADMAP) also need: CI green on GitHub, telemetry reaching Grafana Cloud, and a health endpoint served through the `cloudfront.net` hostname. Phase 4 needs a live hostname early, so deep links can be tested on real devices. S10a delivers the hosted environment and an automatic deploy of the S1 API.

## 2. Context

- [Verified] Parent §4.11 fixes the design: AWS eu-west-2, one ARM `t4g.small` EC2 instance running Docker Compose, behind CloudFront on its free hostname. The origin accepts only CloudFront traffic (managed prefix list plus an `X-Origin-Verify` header). No SSH; access through SSM. Nightly `pg_dump` to S3 (14 days) plus daily EBS snapshots. Infrastructure as CDK TypeScript in `infra/aws/`.
- [Verified] Parent §4.12: the API exports OTLP to a collector on the instance. The collector adds host and Postgres metrics, tail-samples traces (all errors, everything over 1 s, 10% of the rest), has a memory limiter, and forwards to Grafana Cloud.
- [Verified] S1 delivered: the API (`/api/healthz`, `/api/readyz`, sessions), dbmate migrations, the local collector, and `ORIGIN_VERIFY_SECRET` enforcement in production.
- [Verified 2026-11-03] The repository is `AbdulbasitSaid/velio-challenge`, default branch `master`, already pushed.
- [Decided 2026-11-03] **The repository and its Docker images become public**, so the interviewers can access them. The user changes the visibility (Claude runs no GitHub settings commands). A gitleaks 8.30.1 scan of all 6 commits and the working tree found no secrets.
- [Verified 2026-11-03] The AWS CLI is installed (2.39.3). Its default region is `us-east-1`, so S10a passes `eu-west-2` explicitly. The login session had expired when checked; the user is re-authenticating.
- [Decided 2026-11-03] No Grafana Cloud stack exists yet; S10a covers creating one.
- [Decided 2026-11-03] No branch protection; speed of execution matters (time-boxed assessment).

## 3. Desired outcome

1. `bun run aws:deploy` (CDK) creates the whole stack in eu-west-2 from an empty account (after one-time CDK bootstrap).
2. Every push to `master` that passes CI builds the API image and deploys it: migrations first, then the API restarts.
3. `https://<id>.cloudfront.net/api/healthz` returns 200; `/api/readyz` returns 200; requests that skip CloudFront are refused.
4. Traces, metrics and logs from the live API appear in Grafana Cloud.
5. Postgres is backed up nightly to S3, and the EBS volume is snapshotted daily.

## 4. Proposed solution

### 4.1 Scope split of parent S10 [Proposal]

| Parent S10 item | Where |
| --- | --- |
| CDK app stack, CloudFront behaviors, origin lockdown, prod Compose with the collector, Grafana Cloud export, backups, deploy workflow | **S10a (this spec)** |
| Deep-link files (`/.well-known/…`) on the live hostname | S5/S6 (they're served by the web app, which doesn't exist yet) |
| Google Maps keys and signing secret in the secret store | The first spec that uses Maps (S2 or S5) |
| CDK load-runner stack | S10b, in Phase 5 |

### 4.2 AWS resources (`infra/aws`, one CDK stack `VelioApp`) [Proposal]

- **Network:** a new VPC with two public subnets and no NAT gateway (parent §4.11). IPv4 only.
- **Instance:**
  - ARM `t4g.small`, Amazon Linux 2023 (AMI resolved once and cached in `cdk.context.json`, so it's pinned).
  - Root volume: 30 GB gp3, encrypted, kept on termination. Postgres data lives on it under `/opt/velio/data`. A separate data volume is not used, for simplicity; the backups cover loss.
  - IMDSv2 required. Instance profile with `AmazonSSMManagedInstanceCore`, read access to the app secrets, read access to the deploy bucket and write access to the backup bucket. Images are public on GHCR, so pulling needs no credentials.
  - User data installs Docker and the Compose plugin (exact versions pinned), creates `/opt/velio`, and installs the backup timer (§4.6).
  - An EC2 status-check alarm triggers automatic recovery.
- **Security group:** inbound TCP 3001 (API) only from CloudFront's origin-facing managed prefix list. No port 22. All outbound allowed.
- **Elastic IP:** keeps the origin address stable when the instance is stopped and started. CloudFront needs a DNS name, so the origin is the instance's public DNS name for the Elastic IP.
- **CloudFront distribution** (default certificate, `PriceClass_100`, HTTP/2 and HTTP/3):
  - `/api/*` and `/ws` → instance on port 3001 over HTTP: caching disabled, all viewer headers (except `Host`), cookies and query strings forwarded. WebSocket upgrade works by default on CloudFront.
  - `/photos/*` → photos bucket through Origin Access Control: cached.
  - **Default behavior** → the instance on port 3001 for now. It returns the API's `not_found` envelope until S5 adds the web origin; S5 changes only this behavior.
  - Every origin request carries `X-Origin-Verify`, read from Secrets Manager with a CloudFormation dynamic reference, so the value isn't in the template.
  - Viewer protocol: redirect HTTP to HTTPS.
- **S3:**
  - `photos`: private, Block Public Access, read only through OAC. Empty until S5.
  - `backups`: private, SSE-S3, 14-day expiry lifecycle.
  - `deploy`: private, 30-day expiry; holds each deploy's bundle (Compose file, collector config).
- **Secrets Manager** (`velio/prod/*`), all generated by CDK except the Grafana entries:
  - `origin-verify` (64 random characters), `contact-pepper` (64), `db-superuser-password`, `db-api-password`;
  - `grafana` (JSON: OTLP endpoint, instance ID, token), filled in by hand after the Grafana stack exists (§4.5).
- **DLM policy:** a daily snapshot of volumes tagged `velio:backup=daily`, keeping 7.
- **GitHub OIDC:** the account's GitHub OIDC provider (created if absent) and a `velio-deploy` role. Trust is limited to `repo:AbdulbasitSaid/velio-challenge:ref:refs/heads/master`. Permissions: write to the deploy bucket, and `ssm:SendCommand` limited to the instance (by tag) and the `AWS-RunShellScript` document.
- **Alarm notifications:** an SNS topic with an email subscription. The address comes from the CDK context value `alertEmail`, passed at deploy time (`-c alertEmail=…`), **never committed**, because the repository is public. The status-check alarm notifies it. [Decided 2026-11-03: the user gave the address.]
- **AWS budget alarm:** added as the **last task** (T10), with the amount the user chooses then. [Decided 2026-11-03]
- **Outputs:** the distribution domain, instance ID, bucket names and role ARN.

### 4.3 Images [Proposal]

- `apps/api/Dockerfile`: `oven/bun:1.4.4-slim`, installs production dependencies only with `bun install --frozen-lockfile --production` from the workspace, runs as a non-root user, and starts `bun apps/api/src/index.ts`. [Verified 2026-11-03: the tag `1.4.4-slim` exists.]
- `apps/api/migrate.Dockerfile`: `amacneil/dbmate:2.37.0` with `apps/api/migrations` copied in.
- Built for `linux/arm64` and pushed to **GHCR** as `ghcr.io/abdulbasitsaid/velio-api` and `ghcr.io/abdulbasitsaid/velio-migrate`, tagged with the commit SHA (parent plan §4.11).
- **Public packages:** GHCR makes a new package private on first push. After the first deploy, the user sets both packages to public once (package settings), so anyone, including the instance, can pull without a token.

### 4.4 Production Compose (`infra/docker-compose.prod.yml`) [Proposal]

- `postgres` (`postgres:18.6`): data in `/opt/velio/data`. Not published to the host; reachable only on the Compose network. Superuser password from the secret. A healthcheck.
- `migrate` (profile `deploy`, one-off): runs `dbmate up` as the superuser, then sets the `velio_api` password from the secret (`ALTER ROLE`). Idempotent.
- `api`: the commit's image. `NODE_ENV=production`, `DATABASE_URL` as `velio_api` with its password, and `ORIGIN_VERIFY_SECRET`, `CONTACT_PEPPER` and `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318`. Publishes `3001`. Healthcheck on `/api/healthz` (exempt from the origin check).
- `otel-collector` (`otel/opentelemetry-collector-contrib:0.164.0`), config `infra/otel-collector.prod.yaml`:
  - receivers: OTLP; `hostmetrics` (CPU, memory, disk, filesystem, network); `postgresql` (as `velio_readonly`, read-only statistics); `filelog` on the Docker JSON logs of the `api` container, parsed as JSON so `trace_id` and `request_id` stay fields;
  - processors: `memory_limiter`, `batch`, `tail_sampling` (errors, latency > 1 s, 10% probabilistic) on traces only;
  - exporter: `otlphttp/grafana` with basic auth from the `grafana` secret.
- Secrets reach the containers as an env file written on the instance at deploy time (`/opt/velio/.env`, mode 600, owned by root), fetched from Secrets Manager by the deploy script. They never pass through GitHub.

### 4.5 Grafana Cloud [Decided: create one]

Creating the account and stack needs the user's browser (sign-up and email verification), so these steps are a documented, manual procedure in the README, not code:

1. Sign up at grafana.com (free tier) and create a stack in an EU region, London if offered [Decided 2026-11-03].
2. In the stack's OpenTelemetry (OTLP) connection page, create an access-policy token with `metrics:write`, `logs:write` and `traces:write` only.
3. Put the OTLP endpoint, instance ID and token into the `velio/prod/grafana` secret (one `aws secretsmanager put-secret-value` command, given in the README).

The collector picks these up on the next deploy. Dashboards and alerts stay in S8.

### 4.6 Deploy and backups [Proposal]

**`.github/workflows/deploy.yml`**, triggered by `workflow_run` when CI completes successfully, and by `workflow_dispatch`:

0. **Guard (public repository):** the job runs only when the CI run's event is `push`, its branch is `master` and its head repository is this repository. Otherwise a pull request from a fork could trigger a deploy of its code. `workflow_dispatch` is limited to `master` by the OIDC trust.

1. Assume `velio-deploy` through OIDC (`aws-actions/configure-aws-credentials`, pinned by SHA). No stored AWS keys.
2. Build and push `api` and `migrate` for `linux/arm64` on a native `ubuntu-24.04-arm` runner [Assumption: free for public repositories; verify at implementation, else QEMU], logging in to GHCR with the workflow's `GITHUB_TOKEN` (`packages: write`).
3. Upload the Compose file and collector config to `s3://<deploy>/<sha>/`.
4. `aws ssm send-command` runs `/opt/velio/deploy.sh <sha>` on the instance and waits for it:
   - download the bundle;
   - write `.env` from Secrets Manager;
   - pull the images from GHCR (public, no login);
   - `docker compose up -d postgres otel-collector`, then `docker compose run --rm migrate`;
   - `docker compose up -d api`; wait for the API healthcheck;
   - on failure, exit non-zero, so the workflow fails. The previous API container keeps running if the new one never starts.
5. A smoke check: `curl https://<domain>/api/healthz` and `/api/readyz` through CloudFront must return 200.

`deploy.sh` is installed by user data, so changing it means replacing the instance or updating it through SSM; this is acceptable for a prototype.

**Backups:** a systemd timer at 02:00 UTC runs `docker compose exec -T postgres pg_dump -Fc` into `aws s3 cp` to the backups bucket. Plus the DLM snapshots. The restore procedure is written in the README and tried once (VALIDATION).

### 4.7 Developer commands [Proposal]

- `infra/aws` is a Bun workspace package (`aws-cdk-lib`, `constructs`, `aws-cdk` CLI, latest stable, pinned).
- Root scripts: `aws:synth`, `aws:diff`, `aws:deploy` (all with `--region eu-west-2`), `aws:destroy`.
- `cdk bootstrap aws://<account>/eu-west-2` is a one-time step in the README.

## 5. Architectural considerations

- **Security:**
  - No inbound path except CloudFront → port 3001.
  - The secret header stops anyone who finds the IP but bypasses CloudFront.
  - Secrets live only in Secrets Manager and in a root-only file on the instance.
  - Postgres is never published.
  - The OIDC trust is limited to one branch of one repository, and the deploy job refuses runs that didn't come from a push to `master` (fork pull requests).
  - Public repository: CI runs fork pull requests with `pull_request` (read-only token, no secrets); nothing secret is committed, including the alarm email.
  - Known limitation (parent SEC-009): CloudFront → origin is plain HTTP. VPC origins remain the fix before real users.
- **Cost** [Assumption; check with the pricing calculator]:
  - `t4g.small` about $14/month, 30 GB gp3 about $2.50, Elastic IP (public IPv4) about $3.60;
  - six secrets about $2.40; CloudFront and S3 cents at prototype traffic; GHCR free for public images;
  - roughly $25/month.
- **Operability:** shell access through `aws ssm start-session`; logs in Grafana; container state through SSM commands.
- **Telemetry rules** (CLAUDE.md): the `filelog` receiver forwards logs that the API has already redacted, and no new labels are added.

## 6. Components and files affected

New:
- `infra/aws/` (`package.json`, `bin/app.ts`, `lib/app-stack.ts`, `cdk.json`, `cdk.context.json`, `tsconfig.json`, `scripts/user-data.sh`, `scripts/deploy.sh`, `scripts/backup.sh`)
- `infra/aws/test/app-stack.test.ts` (CDK assertions)
- `apps/api/Dockerfile`, `apps/api/migrate.Dockerfile`, `.dockerignore`
- `infra/docker-compose.prod.yml`, `infra/otel-collector.prod.yaml`
- `.github/workflows/deploy.yml`

Changed:
- Root `package.json` (workspace and `aws:*` scripts), `bun.lock`
- `README.md` (deploy, Grafana, restore)
- `ROADMAP.md`, `CHANGELOG.md` after implementation

## 7. Tasks

| # | Task | Verified by |
| --- | --- | --- |
| T1 | Dockerfiles; build both images for arm64 locally; run the API image against local Compose | V-IMG-1 |
| T2 | `infra/aws` CDK app and stack; CDK assertion tests | V-CDK-1 |
| T3 | Prod Compose, prod collector config, `deploy.sh`, `backup.sh`, user data | V-CMP-1 (local dry run of prod Compose) |
| T4 | One-time `cdk bootstrap`, then the first `cdk deploy` from the laptop | V-AWS-1 |
| T5 | First deploy by hand: push images and run `deploy.sh` through SSM | V-AWS-2, V-AWS-3 |
| T6 | Grafana Cloud: user creates the stack and token; fill the secret; redeploy | V-OBS-1 |
| T7 | `deploy.yml`; push to `master` triggers CI → deploy | V-CI-1 |
| T8 | Backup: run the timer's script once, restore it into a scratch database | V-BAK-1 |
| T9 | README sections: bootstrap, deploy, Grafana, SSM access, restore, teardown | Review |
| T10 | **Last:** AWS budget with an email alert, at the amount the user chooses then | V-BUD-1 |

## 8. Dependencies and prerequisites

- **From the user:**
  - a valid AWS CLI session (`aws login`) with rights to bootstrap CDK and create the resources above;
  - a Grafana Cloud sign-up (T6);
  - an email address for AWS alarm notifications (open question 2).
- The CDK bootstrap stack in eu-west-2 (T4, one-time).
- The account's GitHub OIDC provider. If one already exists, the stack imports it rather than creating a duplicate.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| QEMU arm64 builds are slow in CI | The image is small (Bun + deps). Use native arm64 runners if available; Buildx layer cache in GitHub Actions cache. |
| CloudFront dynamic reference to Secrets Manager in `OriginCustomHeaders` is rejected | Check during T2 synth/deploy. Fallback: a CDK context value generated at first deploy and stored in Secrets Manager, read by CDK at synth time [needs approval: it would appear in the template]. |
| Root volume loss or instance replacement loses Postgres data | `RemovalPolicy.RETAIN` on the instance volume, daily snapshots, nightly dumps, restore tested (V-BAK-1). |
| Grafana free-tier limits | Sampling and label rules from parent §4.12; check usage in V-OBS-1. |
| Deploy breaks the running API | Migrations run before the API restarts; a failed healthcheck fails the workflow; redeploy the previous SHA with `workflow_dispatch`. |
| CloudFront creation takes ~5–15 minutes | Expected; only on first deploy and behavior changes. |

## 10. Alternatives considered

- **ECR instead of GHCR:** considered while the repository was private (GHCR would have needed a GitHub token on the instance). Dropped once the user chose a public repository and public images: GHCR is free and matches the parent plan.
- **Secrets in SSM Parameter Store (free):** CloudFormation can't create SecureString parameters, and CloudFront can't resolve `ssm-secure` references, so the origin header would need a workaround. Secrets Manager costs about $0.40 per secret per month.
- **Separate EBS data volume:** cleaner instance replacement, but more user-data logic. Deferred.
- **Terraform:** the parent plan chose CDK.

## 11. Assumptions and open questions

1. ~~ECR instead of GHCR?~~ Resolved 2026-11-03: the repository and images become public, so GHCR stays (parent plan).
2. ~~Alarm email?~~ Resolved: the user's address, passed as CDK context at deploy, not committed.
3. ~~Grafana region?~~ Resolved: EU, London if offered.
4. [Assumption] The AWS account has no service control policies blocking these services, and the default limit allows one more Elastic IP.
5. ~~AWS budget alarm?~~ Resolved: yes, as the last task (T10); the user picks the amount then.
6. **The user's actions:** make the repository public (before or after implementation), and make the two GHCR packages public after the first deploy.

## 12. Estimated complexity

Medium. Most of the risk is in T4–T5 (first deploy) and T7 (OIDC plus SSM wiring).

## 13. Related

Parent plan §4.11, §4.12, §7 (S10), SEC-009, NFR-010, NFR-011 · S1 spec · ROADMAP Phase 1.

## 14. Change log

- 2026-11-03 16:15: created (draft).
- 2026-11-03: open questions answered. Repository and images public, so GHCR (no ECR); native arm64 runners; fork-safe deploy guard; alarm email from deploy-time context; Grafana in the EU; AWS budget added as the last task.
- 2026-11-03: implementation authorized; partially done (stopped at a usage limit). Design details changed during implementation:
  - A sixth secret, `db-readonly-password`, for the collector's `postgresql` receiver. The migrate image (`apps/api/scripts/migrate-prod.sh`) sets it and grants `pg_monitor` to `velio_readonly`.
  - `deploy.sh` and `backup.sh` ship in each deploy bundle instead of user data, so changing them needs no instance replacement. User data only installs Docker, Compose v5.7.0 (checksum-verified) and jq. The SSM command fetches the bundle's `deploy.sh` and runs it.
  - If the new API fails its healthcheck, `deploy.sh` starts the previous release again and still exits non-zero. Compose replaces the old container, so it cannot simply "keep running".
  - The collector exports to `nop` until the Grafana secret is set; then `infra/otel-collector.prod-grafana.yaml` is merged in.
  - Planned: pin the AMI ID and CloudFront prefix-list ID as constants instead of `cdk.context.json` lookups, which would commit the account ID to a public repository. The deploy role also needs `ssm:GetCommandInvocation` and `cloudformation:DescribeStacks` on `VelioApp`; the workflow reads its role ARN from the repository variable `AWS_DEPLOY_ROLE_ARN`.
- 2026-11-03 (continued): T1, T2, T3 and T7 written and checked locally. Further details:
  - AMI `ami-0d623184a69654e22` (al2023-ami-2023.12.20261102.0-kernel-6.18-arm64) and prefix list `pl-93a247fa` are constants in `infra/aws/bin/app.ts`; no `cdk.context.json` is needed.
  - The account already has GitHub's OIDC provider, so `cdk.json` sets `velio:createGithubOidcProvider: false` and the stack references it.
  - `cdk.out/` is git-ignored: the synthesised template holds the alarm email.
  - The collector's log receiver is `file_log/api` (the `filelog` alias is deprecated in 0.164), and the collector starts after Postgres is healthy.
  - CloudFormation Validate prints warning W9010 (hard-coded AMI ID) on every synth. It is intended (NFR-001) and is not silenced: `Annotations.acknowledgeWarning` doesn't affect this validator.
- 2026-11-03: **deployment deferred** at the user's request, to save time. T1, T2, T3, T7 and T9 are written and checked locally. T4 (bootstrap and first `cdk deploy`), T5 (first deploy), T6 (Grafana Cloud), T8 (backup restore) and T10 (budget) are not started, and no AWS resources exist. They resume when the user asks. Open items at the pause: the alarm email address, the gitleaks rerun (needs Docker), and whether to deploy as the account root user (the current CLI session) or an IAM role. Until the stack exists, Phase 1's "telemetry reaches Grafana Cloud" and "health through `cloudfront.net`" exits are unmet, and so is Phase 4's "against the deployed stack".
  - So pushes stay green while the deploy is deferred, the `deploy` job in `deploy.yml` also requires `vars.AWS_DEPLOY_ROLE_ARN != ''`. It is skipped until the repository variable is set after T4.
- 2026-11-03: **deployment resumed** at the user's request (T4–T10), so testing can start against the deployed stack. Open items at the pause, answered: deploy as the account root user for the bootstrap and first `cdk deploy` only (CI then deploys through the OIDC role); the alarm email is the user's account address, passed at deploy time and still never committed.
- 2026-11-03: the first Deploy run failed with `Not authorized to perform sts:AssumeRoleWithWebIdentity`. Cause: the repository uses GitHub's immutable OIDC subject (`use_immutable_subject: true`), so the token's `sub` is `repo:AbdulbasitSaid@16627656/velio-challenge@1443959310:ref:refs/heads/master`, not the `owner/repo` form the trust condition expected. Fix: `githubRepository` in `infra/aws/bin/app.ts` now holds the ID-qualified prefix; diff reviewed (trust condition only), redeployed.
- 2026-11-03: **T10 done** at 20 USD a month, the amount the user chose. The budget was created with the AWS Budgets API, not in the CDK stack: a budget is account-level billing configuration, and keeping it outside `VelioApp` means `cdk destroy` doesn't remove the cost alarm with the stack. Alerts go to the account address at ACTUAL > 80% and FORECASTED > 100%. T6: the user stores the Grafana secret themselves, so the token never passes through the session. T8: blocked by the session's permission policy, which refused the SSM command; it waits for the user.
