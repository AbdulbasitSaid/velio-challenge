#!/bin/sh
# Entrypoint of the migrate image (production). Runs as the Postgres superuser.
# Applies pending migrations, then sets the login roles' passwords from the secret store.
# Idempotent: runs on every deploy.
set -eu

dbmate up

# psql substitutes :'name' as a quoted literal, so the passwords never appear in the SQL text.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q \
  -v api_password="$DB_API_PASSWORD" -v readonly_password="$DB_READONLY_PASSWORD" <<'SQL'
ALTER ROLE velio_api PASSWORD :'api_password';
ALTER ROLE velio_readonly PASSWORD :'readonly_password';
-- The collector's postgresql receiver reads statistics views as velio_readonly.
GRANT pg_monitor TO velio_readonly;
SQL
