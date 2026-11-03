#!/bin/bash
# Dumps the velio database (custom format) to the backups bucket, which expires objects after
# 14 days. Run nightly by velio-backup.timer (installed by deploy.sh), or by hand as root.
set -euo pipefail

# AWS_REGION, BACKUP_BUCKET: written by user data.
# shellcheck source=/dev/null
source /opt/velio/stack.env
export AWS_REGION

key="velio-$(date -u +%Y-%m-%dT%H-%M-%SZ).dump"
docker exec velio-postgres-1 pg_dump -U postgres -Fc velio | aws s3 cp --quiet - "s3://$BACKUP_BUCKET/$key"
echo "backup: s3://$BACKUP_BUCKET/$key"
