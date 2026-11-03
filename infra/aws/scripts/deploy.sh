#!/bin/bash
# Deploys one commit on the app instance. Runs as root through SSM, started by
# .github/workflows/deploy.yml (or by hand, README "Deploy"):
#   deploy.sh <commit sha>
# The bundle s3://$DEPLOY_BUCKET/<sha>/ holds this script, the Compose file, the collector
# configs and backup.sh. Order: write .env from Secrets Manager, pull, start Postgres and the
# collector, migrate, then restart the API. If the new API never becomes healthy, the previous
# release is started again and the script still fails.
set -euo pipefail

SHA="${1:-}"
if [[ ! "$SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "usage: deploy.sh <40-character commit sha>" >&2
  exit 2
fi

# AWS_REGION, DEPLOY_BUCKET, BACKUP_BUCKET: written by user data.
# shellcheck source=/dev/null
source /opt/velio/stack.env
export AWS_REGION

REL=/opt/velio/releases/$SHA
mkdir -p "$REL"
aws s3 cp --recursive --quiet "s3://$DEPLOY_BUCKET/$SHA/" "$REL/"

secret() { aws secretsmanager get-secret-value --secret-id "velio/prod/$1" --query SecretString --output text; }

db_superuser_password=$(secret db-superuser-password)
db_api_password=$(secret db-api-password)
db_readonly_password=$(secret db-readonly-password)
contact_pepper=$(secret contact-pepper)
origin_verify=$(secret origin-verify)

# Export to Grafana Cloud only once its secret is filled in (README "Grafana Cloud").
grafana=$(secret grafana)
grafana_endpoint=$(jq -r '.endpoint // empty' <<<"$grafana")
grafana_auth=""
collector_overlay=/etc/otelcol/empty.yaml
if [[ -n "$grafana_endpoint" ]]; then
  grafana_auth=$(jq -r '"\(.instanceId):\(.token)"' <<<"$grafana" | tr -d '\n' | base64 -w0)
  collector_overlay=/etc/otelcol/grafana.yaml
fi

# $1: image tag. The file is root-only: mktemp creates it with mode 600.
write_env() {
  local tmp
  tmp=$(mktemp /opt/velio/.env.XXXXXX)
  cat >"$tmp" <<EOF
IMAGE_TAG='$1'
DB_SUPERUSER_PASSWORD='$db_superuser_password'
DB_API_PASSWORD='$db_api_password'
DB_READONLY_PASSWORD='$db_readonly_password'
CONTACT_PEPPER='$contact_pepper'
ORIGIN_VERIFY_SECRET='$origin_verify'
OTEL_COLLECTOR_EXTRA_CONFIG='$collector_overlay'
GRAFANA_OTLP_ENDPOINT='$grafana_endpoint'
GRAFANA_OTLP_AUTH='$grafana_auth'
EOF
  mv "$tmp" /opt/velio/.env
}

# $1: release directory; the rest are Compose arguments.
dc() {
  local dir=$1
  shift
  docker compose --project-name velio --project-directory "$dir" -f "$dir/docker-compose.prod.yml" \
    --env-file /opt/velio/.env "$@"
}

previous=$(cat /opt/velio/current 2>/dev/null || true)

write_env "$SHA"
dc "$REL" --profile deploy pull --quiet
dc "$REL" up -d --wait --wait-timeout 120 postgres otel-collector
# A failing migration stops here, before the API restarts.
dc "$REL" --profile deploy run --rm migrate

if ! dc "$REL" up -d --wait --wait-timeout 120 api; then
  echo "deploy: the API for $SHA did not become healthy" >&2
  dc "$REL" logs --no-color --tail 100 api >&2 || true
  if [[ -n "$previous" && -d "/opt/velio/releases/$previous" ]]; then
    echo "deploy: starting the previous release $previous again" >&2
    write_env "$previous"
    dc "/opt/velio/releases/$previous" up -d --wait --wait-timeout 120 api otel-collector || true
  fi
  exit 1
fi
echo "$SHA" >/opt/velio/current

# Nightly backup at 02:00 UTC (README "Backups and restore").
install -m 700 "$REL/backup.sh" /opt/velio/backup.sh
cat >/etc/systemd/system/velio-backup.service <<'EOF'
[Unit]
Description=Dump the Velio database to S3
After=docker.service

[Service]
Type=oneshot
ExecStart=/opt/velio/backup.sh
EOF
cat >/etc/systemd/system/velio-backup.timer <<'EOF'
[Unit]
Description=Nightly Velio database dump

[Timer]
OnCalendar=*-*-* 02:00:00 UTC
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now velio-backup.timer

# Housekeeping: keep the five newest releases and drop images no container uses.
ls -1t /opt/velio/releases | tail -n +6 | xargs -r -I{} rm -rf "/opt/velio/releases/{}"
docker image prune -af --filter until=72h >/dev/null

echo "deploy: $SHA is live"
