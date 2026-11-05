# Production (AWS): operations runbook

One `t4g.small` instance in eu-west-2 runs Docker Compose (Postgres, the API, the web app, the OpenTelemetry Collector) behind CloudFront on its `cloudfront.net` hostname. The instance accepts only CloudFront on port 3001, and the API rejects requests without CloudFront's `X-Origin-Verify` header. It has no SSH; use SSM. Design and checks: [`spec/2026-11-03_16-15_s10-aws-app-stack/`](../../spec/2026-11-03_16-15_s10-aws-app-stack/).

## First-time setup

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

## AWS quotas

The security group admits CloudFront on two ports through the `com.amazonaws.global.cloudfront.origin-facing` prefix list. The list counts as about 55 rules each time it's used. The default of 60 rules per security group fits one use, so eu-west-2 needs the quota raised to 120 before the stack has both (once per account):

```sh
aws service-quotas request-service-quota-increase --region eu-west-2 \
  --service-code vpc --quota-code L-0EA8095F --desired-value 120
```

## Deploys and rollback

Every push to `master` that passes CI deploys:

1. The images are built for arm64.
2. The bundle (Compose file, collector configs, `deploy.sh`, `backup.sh`) is uploaded to the deploy bucket.
3. `deploy.sh <sha> <photos bucket>` runs on the instance through SSM. The bucket is the stack's `PhotosBucket` output.
4. The script writes `/opt/velio/.env` (root only) from Secrets Manager, migrates, then restarts the API. If the new API never becomes healthy, it starts the previous release again and the workflow fails.
5. The workflow ends by checking `/api/healthz` and `/api/readyz` through CloudFront.

To roll back, run the Deploy workflow by hand (Actions → Deploy → Run workflow, on `master`) with the earlier commit's SHA.

## Grafana Cloud

Until the `velio/prod/grafana` secret is filled in, the collector exports nothing and deploys still succeed. To turn export on:

1. Sign up at [grafana.com](https://grafana.com) (free tier) and create a stack in an EU region (London if offered).
2. In the stack, go to Connections → OpenTelemetry (OTLP). Note the OTLP endpoint and instance ID, and create an access-policy token with only `metrics:write`, `logs:write` and `traces:write`.
3. Store them, then redeploy (rerun the Deploy workflow):

```sh
aws secretsmanager put-secret-value --region eu-west-2 --secret-id velio/prod/grafana \
  --secret-string '{"endpoint":"https://otlp-gateway-<zone>.grafana.net/otlp","instanceId":"<id>","token":"<token>"}'
```

Traces are tail-sampled: every error, everything over 1 s, and 10% of the rest. API logs carry `trace_id`, so a log line links to its trace.

## Dashboards and alerts

Three dashboards (Goals; Booking and realtime; Host and database) and four alert rules live as JSON in `infra/grafana/`. The rules cover oversell, booking success under 99.5% over 1 h, live-update p95 over 2 s for 15 min, and a broken hash chain. To push them:

1. In the stack, go to Administration → Users and access → Service accounts → Add service account, with role Admin (the alert provisioning API needs it). Add a token with a short expiry.
2. Put `GRAFANA_URL=https://<stack>.grafana.net` and `GRAFANA_SA_TOKEN=glsa_…` in the root `.env` (git-ignored).
3. Run `GRAFANA_ALERT_EMAIL=you@example.com bun run grafana:push` (or put `GRAFANA_ALERT_EMAIL` in `.env`).

The push is idempotent:

- Dashboards are matched by UID.
- The `velio-goals` rule group is replaced as a whole.
- The `velio-email` contact point is updated; without `GRAFANA_ALERT_EMAIL`, an existing one is kept.

Everything lands in the Velio folder.

The Velio rules notify `velio-email` directly; the stack's own notification policy isn't changed. Dashboards and alerts show production only. The API tags its telemetry with `deployment.environment` from `NODE_ENV`, and the collectors tag everything they forward (`development` locally, `production` on EC2).

## Admin token

The production `ADMIN_TOKEN` is the generated `velio/prod/admin-token` secret:

```sh
aws secretsmanager get-secret-value --region eu-west-2 --secret-id velio/prod/admin-token --query SecretString --output text
```

## Shell access

```sh
aws ssm start-session --region eu-west-2 --target <InstanceId output>
sudo -i
cd /opt/velio && cat current     # the live commit
docker compose -p velio ps
docker logs --tail 100 velio-api-1
```

## Backups and restore

`velio-backup.timer` dumps the database at 02:00 UTC to the backups bucket (`pg_dump -Fc`, kept 14 days). The instance's volume is also snapshotted daily at 03:00 UTC, keeping 7. To dump now, run `sudo /opt/velio/backup.sh`.

To restore a dump, on the instance:

```sh
source /opt/velio/stack.env
aws s3 ls "s3://$BACKUP_BUCKET/"                                 # pick a file
aws s3 cp "s3://$BACKUP_BUCKET/<file>.dump" /tmp/velio.dump
docker cp /tmp/velio.dump velio-postgres-1:/tmp/velio.dump
docker exec velio-postgres-1 createdb -U postgres velio_restore
docker exec velio-postgres-1 pg_restore -U postgres -d velio_restore --no-owner /tmp/velio.dump
```

Check `velio_restore`. To make it live:

1. Stop the API: `docker stop velio-api-1`.
2. Rename the databases: `ALTER DATABASE velio RENAME TO velio_old; ALTER DATABASE velio_restore RENAME TO velio;`.
3. Rerun the Deploy workflow. The rerun restores ownership, grants and role passwords through migrations.

## Updating the AMI

The AMI ID is pinned in `infra/aws/bin/app.ts`. To move to a newer Amazon Linux 2023 release, look up `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64` in SSM Parameter Store. Changing it replaces the instance and its root volume: take a fresh backup first, restore it afterwards, then redeploy.

## Teardown

```sh
bun run aws:destroy -c alertEmail=you@example.com
```

This keeps the backups bucket and the instance's root volume, which hold the data. Delete them by hand when you no longer need them.

The secrets enter a 7–30 day recovery window that reserves their names. Before redeploying sooner, delete each one:

```sh
aws secretsmanager delete-secret --force-delete-without-recovery --secret-id velio/prod/<name>
```
