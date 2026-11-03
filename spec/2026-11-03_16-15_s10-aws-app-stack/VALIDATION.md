# Validation: S10a AWS App Stack

## Part A: Planned checks

### Spec review checklist

- [ ] Every FR, NFR, SEC and AC maps to a check below.
- [ ] Nothing outside the S10a scope (PLANNING §4.1) is included.
- [ ] Open questions in PLANNING §11 are answered before implementation.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, NFR-003 | V-CDK-1, V-AWS-1 |
| FR-002, AC-001 | V-AWS-2, V-CI-1 |
| FR-003 | V-CDK-1, V-AWS-3 |
| FR-004, FR-005, NFR-004 | V-CI-1 |
| FR-006, AC-004 | V-BAK-1 |
| FR-007, NFR-002, AC-003, SEC-007 | V-OBS-1 |
| FR-008 | V-DOC-1 |
| NFR-001 | V-PIN-1 |
| SEC-001, SEC-002, AC-002 | V-SEC-1 |
| SEC-003, SEC-004 | V-SEC-2 |
| SEC-005, SEC-006 | V-CDK-1, V-SEC-1 |
| AC-005 | V-CDK-1 |
| FR-009 | V-ALM-1 |
| FR-010 | V-PUB-1 |
| FR-011 | V-BUD-1 |
| SEC-008 | V-SEC-3 |
| SEC-009 | V-SEC-4 |

### Checks

| ID | Check | Expected |
| --- | --- | --- |
| V-IMG-1 | Build `api` and `migrate` for arm64 locally; run `migrate` then `api` against local Compose; `curl /api/readyz` | 200 |
| V-CMP-1 | `docker compose -f infra/docker-compose.prod.yml config` with a sample env file; collector `validate` on the prod config | Valid |
| V-CDK-1 | `bun test` in `infra/aws` (CDK assertions): SG ingress only port 3001 from the prefix list; no port 22; IMDSv2; buckets block public access and are encrypted; behaviors and cache policies as FR-003; OIDC trust condition; SNS email subscription from context; no plaintext secret or email in the template committed to the repo | All pass |
| V-AWS-1 | `bun run aws:deploy` from the laptop | Stack `CREATE_COMPLETE` |
| V-AWS-2 | First manual deploy through SSM; `curl https://<domain>/api/healthz` and `/api/readyz` | 200 and 200 |
| V-AWS-3 | `curl https://<domain>/api/nope` (404 envelope), `http://<domain>/api/healthz` (redirect to HTTPS), `https://<domain>/photos/x` (403/404 from S3, not the API) | As described |
| V-SEC-1 | From the laptop: `curl --max-time 5 http://<eip>:3001/api/healthz` → timeout. Through SSM on the instance: `curl localhost:3001/api/readyz` → 403; with the right header → 200; `ss -ltn` shows Postgres not published | As described |
| V-SEC-2 | Inspect the template (`cdk synth`) and the repo for secret values; inspect the role trust policy; run a deploy from a non-`master` branch with `workflow_dispatch` | No secret values; assume-role denied off `master` |
| V-OBS-1 | Call `/api/me` through CloudFront; find the trace, metric point and log line in Grafana Cloud (Explore); check the time to appear; grep exported logs for the test contact | All three share a `trace_id` within 1 minute; no contact |
| V-CI-1 | Push a trivial change to `master`; watch CI then deploy; time the deploy; rerun the deploy for the previous SHA with `workflow_dispatch` | Both green; deploy < 10 min; rollback works |
| V-BAK-1 | Run `backup.sh` through SSM; restore the dump into a scratch database; compare row counts; check one DLM snapshot exists after a day | Counts equal; snapshot present |
| V-ALM-1 | Confirm the SNS subscription email; publish a test message to the topic | Email received |
| V-PUB-1 | After the user makes the packages public: `docker logout ghcr.io && docker pull ghcr.io/abdulbasitsaid/velio-api:<sha>` | Pull succeeds |
| V-BUD-1 | Inspect the budget and its notification (last) | Present, with the user's amount and email |
| V-SEC-3 | Review `deploy.yml`'s job condition; actionlint | Only `push` on `master` from this repository deploys |
| V-SEC-4 | gitleaks (latest) over git history and the working tree; grep the repo for the alarm email | No leaks; no email |
| V-PIN-1 | Review every image reference, action reference, AMI and dependency | All exact |
| V-DOC-1 | Follow the README's deploy section from a clean shell | Works as written |

**Preconditions:** AWS CLI session valid; CDK bootstrap done; Grafana stack and token (for V-OBS-1); Docker with Buildx.

**Known limitations:** V-BAK-1's snapshot part needs a day to pass. V-SEC-2's negative OIDC check needs a non-`master` branch, which the user creates (Claude runs no branch commands).

## Part B: Executed checks

In progress. All checks below ran on 2026-11-03 on the laptop (macOS arm64, Docker 29.8.1).

| Check | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| V-IMG-1 | `docker buildx build --platform linux/arm64` of `apps/api/Dockerfile` and `apps/api/migrate.Dockerfile`; then the V-CMP-1 dry run | Pass. The frozen production install passes under Bun 1.4.4. | FR-010 (partly) |
| V-CMP-1 | `docker compose config` on the prod file; `otelcol-contrib validate` (0.164.0) with both overlays; a full local run of the prod Compose with an override for host paths: migrate, `api` healthy, `/api/healthz` 200, `/api/readyz` 403 without the header and 200 with it, migrate rerun idempotent | Pass | SEC-002 (app side), SEC-005 (passwords) |
| V-CMP-1 (logs) | Collector with a debug overlay, fed a Docker json-file line with the API's label and one without | Pass: only the API line is exported, with body, severity, timestamp, `trace_id` and `span_id` set from the pino fields | FR-007 (partly) |
| V-CDK-1 | `bun test infra/aws` | Pass, 14 tests | FR-003, SEC-001, SEC-002 (template), SEC-003, SEC-004, SEC-006, FR-006 (config), FR-009 (config), AC-005 |
| V-CDK-1 (synth) | `cdk synth -q -c alertEmail=…` | Pass; `cdk.out/` confirmed git-ignored | FR-001 (partly) |
| V-SEC-3 | actionlint 1.7.12 (with ShellCheck) over `.github/workflows` | Pass: no findings | SEC-008 (static) |
| V-PIN-1 | Review of every image, action, AMI, binary and dependency reference | Pass. Images use exact tags (`postgres:18.6`, `otel/opentelemetry-collector-contrib:0.164.0`, `oven/bun:1.4.4-slim`, `amacneil/dbmate:2.37.0`); app images are tagged with the commit SHA. Actions are pinned by commit SHA. The AMI ID is pinned and, with it, the AL2023 package repository. Compose v5.7.0 is checksum-verified. All npm versions are exact. | NFR-001 |
| V-SEC-4 (part) | `git grep` and `grep -r` (excluding `node_modules`, `cdk.out`, `.git`) for the alarm email | Pass: no match | SEC-009 (partly) |
| V-DOC-1 (review) | README "Production (AWS)" sections checked against the synthesised template (deletion policies, outputs) and the scripts | Pass on review. Following it from a clean shell needs the deployed stack. | FR-008 (partly) |
| Static | `bun run format:check`, `bun run lint`, `bun run typecheck`; ShellCheck (stable) on the four scripts | Pass. ShellCheck reports only info-level notes: SC2012 on release-directory names, which are SHAs. | NFR-001 (partly) |

Not yet run: V-AWS-1 to 3, V-SEC-1, V-SEC-2, V-OBS-1, V-CI-1, V-BAK-1, V-ALM-1, V-PUB-1, V-BUD-1 (all need the AWS stack), and V-DOC-1 run from a clean shell. The gitleaks 8.30.1 part of V-SEC-4 was attempted, but Docker Desktop stopped during the run; it must run before the repository goes public.

2026-11-03: deployment deferred at the user's request (see PLANNING change log). The AWS checks above stay not run until it resumes. After the `AWS_DEPLOY_ROLE_ARN` guard was added to `deploy.yml`, `bun run format:check` and `bun run lint` passed. actionlint (V-SEC-3) wasn't rerun because Docker was down; rerun it with gitleaks.

2026-11-03, deployment resumed:

| Check | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| T4 bootstrap | `cdk bootstrap aws://<account>/eu-west-2` as the root user | Pass: `CDKToolkit` created | — |
| V-AWS-1 | `cdk diff` reviewed (52 resources, all additions, none modified or removed), then `bun run aws:deploy -c alertEmail=…` | Pass: `VelioApp` `CREATE_COMPLETE` in 386 s. Outputs: distribution `depimls1pcvv4.cloudfront.net`, instance `i-053cf33042f6be633`, role `velio-deploy` | FR-001, NFR-003 |
| SSM | `aws ssm describe-instance-information` | Pass: instance `Online` | FR-004 (partly) |
| V-SEC-1 (laptop part) | `curl --max-time 5 http://<eip>:3001/api/healthz` | Pass: timed out | SEC-001 (partly) |
| V-AWS-3 (redirect part) | `curl http://<domain>/api/healthz` | Pass: `301` to HTTPS | FR-003 (partly) |
| Pre-app | `curl https://<domain>/api/healthz` | `504`, as expected: no release is on the instance until the first Deploy run (T5) | — |
| T5 / V-CI-1 (first part) | Deploy workflow run 41729508359 (after the OIDC trust fix, triggered by CI run 41728945517) | Pass: success in 1 m 50 s | FR-002, FR-004 (partly) |
| V-AWS-2 | `curl https://<domain>/api/healthz` and `/api/readyz` | Pass: `200 {"status":"ok"}` for both | FR-002, AC-001 |
| V-AWS-3 | `curl https://<domain>/api/nope`; `curl https://<domain>/photos/x` | Pass: `404` error envelope from the API; `403` with `server: AmazonS3` for photos | FR-003 |

2026-11-03, follow-ups:

| Check | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| T10 / V-BUD-1 | AWS Budgets `CreateBudget`, then `DescribeBudget` and `DescribeNotificationsForBudget` | Pass: `velio-monthly`, COST, MONTHLY, 20 USD. Email alerts to the account address at ACTUAL > 80% and FORECASTED > 100%, both state `OK` | FR-011 |
| V-BAK-1 (snapshot part) | `ec2 DescribeSnapshots` (owner self), `dlm GetLifecyclePolicies` | Not yet: policy `Velio daily EBS snapshots` is `ENABLED`, and no snapshot exists yet. The first runs at 03:00 UTC after the stack was created (about 22:00 UTC). Recheck tomorrow | FR-006 (partly) |
| T8 / V-BAK-1 (dump and restore), V-SEC-1 (on-instance part) | One SSM `SendCommand`: run `backup.sh`, restore the newest dump into a scratch `velio_restore_check`, compare row counts, drop it; then `curl localhost:3001/api/readyz` with and without the origin header, and `ss -ltn` | **Not run:** the command was blocked by the session's permission policy before it was sent. It needs the user's permission (or the user runs it through Session Manager) | FR-006, AC-004, SEC-001, SEC-002 |

Still not run: T8 / V-BAK-1 and V-SEC-1 (on-instance part), both blocked as above; V-SEC-2 (the off-`master` deploy needs a branch, which only the user creates; the trust-policy inspection part can run without one); V-OBS-1 (T6: the user stores the Grafana secret, then a redeploy); V-CI-1 (timed deploy and rollback, after the user's next push); V-ALM-1 (confirm the SNS subscription email and publish a test message).

**Final validation status:** Not run (in progress: stack deployed and serving; budget in place; T6 and T8 outstanding).
