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

Not run. Implementation has not been authorized.

**Final validation status:** Not run.
