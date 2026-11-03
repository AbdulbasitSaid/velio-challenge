-- migrate:up

-- Roles are cluster-wide, so creation is idempotent (every database migrates the same file).
-- velio_owner owns the schema; later migrations switch to it with SET LOCAL ROLE.
-- velio_api is the runtime role; velio_readonly reads metrics views (S8).
-- No passwords here: local Postgres uses trust auth; production sets them from the secret store (S10).
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'velio_owner') THEN
    CREATE ROLE velio_owner NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'velio_api') THEN
    CREATE ROLE velio_api LOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'velio_readonly') THEN
    CREATE ROLE velio_readonly LOGIN;
  END IF;
END
$$;

ALTER SCHEMA public OWNER TO velio_owner;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO velio_api, velio_readonly;

-- migrate:down
