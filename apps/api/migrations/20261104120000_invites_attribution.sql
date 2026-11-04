-- migrate:up

-- S4 (spec/2026-11-04_11-42_s4-invites-attribution, PLANNING §4.2, §4.8). invites, attributions
-- and invite_claims are empty in every environment when this runs (nothing wrote to them before
-- S4), so the NOT NULL columns need no backfill.
SET LOCAL ROLE velio_owner;

-- ---------------------------------------------------------------------------
-- Hash chain: one per activity per table. The BEFORE INSERT triggers below assign chain_seq,
-- prev_hash and row_hash under the activity row lock, overwriting anything the caller sent.
-- ---------------------------------------------------------------------------

-- UTC with microseconds, independent of the session's TimeZone setting.
CREATE FUNCTION chain_ts(ts timestamptz) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT to_char(ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
$$;

-- The first row of a chain points at 32 zero bytes.
CREATE FUNCTION chain_genesis() RETURNS bytea
LANGUAGE sql IMMUTABLE AS $$ SELECT decode(repeat('00', 32), 'hex') $$;

-- The defaults are placeholders the trigger always replaces; they let inserts omit the columns.
ALTER TABLE invites
  ADD COLUMN chain_seq bigint NOT NULL DEFAULT 0,
  ALTER COLUMN prev_hash SET DEFAULT '\x'::bytea,
  ALTER COLUMN prev_hash SET NOT NULL,
  ALTER COLUMN row_hash SET DEFAULT '\x'::bytea,
  ALTER COLUMN row_hash SET NOT NULL,
  ADD CONSTRAINT invites_chain_seq UNIQUE (activity_id, chain_seq),
  ADD CONSTRAINT invites_vouch_named CHECK (
    rail <> 'vouch'
    OR (invitee_name IS NOT NULL AND btrim(invitee_name) <> '' AND char_length(invitee_name) <= 80)),
  ADD CONSTRAINT invites_public_anonymous CHECK (
    rail <> 'public' OR (invitee_name IS NULL AND invitee_contact_hash IS NULL AND note IS NULL)),
  ADD CONSTRAINT invites_note_length CHECK (note IS NULL OR char_length(note) <= 280),
  ADD CONSTRAINT invites_contact_hash_length CHECK (
    invitee_contact_hash IS NULL OR octet_length(invitee_contact_hash) = 32);

-- One public link per member per Plan (S4 §12, Q4).
CREATE UNIQUE INDEX invites_one_public_per_member ON invites (plan_id, inviter_id) WHERE rail = 'public';

-- jsonb's text form is deterministic; timestamps and bytea are pre-formatted.
CREATE FUNCTION invite_canonical(i invites) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT jsonb_build_array(
    i.id::text, i.code, i.rail, i.activity_id::text, i.plan_id::text, i.inviter_id::text,
    i.invitee_name, encode(i.invitee_contact_hash, 'hex'), i.note, chain_ts(i.expires_at),
    chain_ts(i.created_at), i.chain_seq)::text
$$;

CREATE FUNCTION invites_chain() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  prev record;
BEGIN
  -- Serializes this activity's chain; booking transactions already hold this lock.
  PERFORM 1 FROM activities WHERE id = NEW.activity_id FOR UPDATE;
  SELECT chain_seq, row_hash INTO prev FROM invites
   WHERE activity_id = NEW.activity_id ORDER BY chain_seq DESC LIMIT 1;
  NEW.chain_seq := coalesce(prev.chain_seq, 0) + 1;
  NEW.prev_hash := coalesce(prev.row_hash, chain_genesis());
  NEW.row_hash := sha256(NEW.prev_hash || convert_to(invite_canonical(NEW), 'UTF8'));
  RETURN NEW;
END
$$;

CREATE TRIGGER invites_chain BEFORE INSERT ON invites
  FOR EACH ROW EXECUTE FUNCTION invites_chain();

-- activity_id is set by the trigger from the invite. The placeholder default makes it optional on
-- insert; the foreign key would reject it if the trigger didn't replace it.
ALTER TABLE attributions
  ADD COLUMN activity_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES activities (id),
  ADD COLUMN chain_seq bigint NOT NULL DEFAULT 0,
  ALTER COLUMN prev_hash SET DEFAULT '\x'::bytea,
  ALTER COLUMN prev_hash SET NOT NULL,
  ALTER COLUMN row_hash SET DEFAULT '\x'::bytea,
  ALTER COLUMN row_hash SET NOT NULL,
  ADD CONSTRAINT attributions_chain_seq UNIQUE (activity_id, chain_seq);

CREATE FUNCTION attribution_canonical(a attributions) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT jsonb_build_array(
    a.invitee_id::text, a.inviter_id::text, a.invite_id::text, a.rail, a.generation,
    a.activity_id::text, chain_ts(a.created_at), a.chain_seq)::text
$$;

CREATE FUNCTION attributions_chain() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  prev record;
BEGIN
  -- The activity comes from the invite, so the two can't disagree.
  SELECT activity_id INTO STRICT NEW.activity_id FROM invites WHERE id = NEW.invite_id;
  PERFORM 1 FROM activities WHERE id = NEW.activity_id FOR UPDATE;
  SELECT chain_seq, row_hash INTO prev FROM attributions
   WHERE activity_id = NEW.activity_id ORDER BY chain_seq DESC LIMIT 1;
  NEW.chain_seq := coalesce(prev.chain_seq, 0) + 1;
  NEW.prev_hash := coalesce(prev.row_hash, chain_genesis());
  NEW.row_hash := sha256(NEW.prev_hash || convert_to(attribution_canonical(NEW), 'UTF8'));
  RETURN NEW;
END
$$;

CREATE TRIGGER attributions_chain BEFORE INSERT ON attributions
  FOR EACH ROW EXECUTE FUNCTION attributions_chain();

-- The audit (PRD Operations, R11): recomputes both chains for one activity and returns, per table,
-- the first chain_seq that doesn't match or follows a gap. A clean activity returns no rows.
CREATE FUNCTION audit_chain(p_activity_id uuid)
RETURNS TABLE (table_name text, first_bad_seq bigint)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  ri invites;
  ra attributions;
  expected_seq bigint;
  expected_prev bytea;
BEGIN
  expected_seq := 1;
  expected_prev := chain_genesis();
  FOR ri IN SELECT * FROM invites WHERE activity_id = p_activity_id ORDER BY chain_seq LOOP
    IF ri.chain_seq <> expected_seq OR ri.prev_hash <> expected_prev
       OR ri.row_hash <> sha256(ri.prev_hash || convert_to(invite_canonical(ri), 'UTF8')) THEN
      table_name := 'invites';
      first_bad_seq := ri.chain_seq;
      RETURN NEXT;
      EXIT;
    END IF;
    expected_seq := expected_seq + 1;
    expected_prev := ri.row_hash;
  END LOOP;

  expected_seq := 1;
  expected_prev := chain_genesis();
  FOR ra IN SELECT * FROM attributions WHERE activity_id = p_activity_id ORDER BY chain_seq LOOP
    IF ra.chain_seq <> expected_seq OR ra.prev_hash <> expected_prev
       OR ra.row_hash <> sha256(ra.prev_hash || convert_to(attribution_canonical(ra), 'UTF8')) THEN
      table_name := 'attributions';
      first_bad_seq := ra.chain_seq;
      RETURN NEXT;
      EXIT;
    END IF;
    expected_seq := expected_seq + 1;
    expected_prev := ra.row_hash;
  END LOOP;
END
$$;

CREATE FUNCTION audit_all_chains()
RETURNS TABLE (activity_id uuid, table_name text, first_bad_seq bigint)
LANGUAGE sql STABLE AS $$
  SELECT a.id, c.table_name, c.first_bad_seq
    FROM activities a, LATERAL audit_chain(a.id) c
   WHERE EXISTS (SELECT 1 FROM invites i WHERE i.activity_id = a.id)
$$;

-- ---------------------------------------------------------------------------
-- Pause reason (the UI shows a different message for an automatic pause) and indexes.
-- ---------------------------------------------------------------------------

ALTER TABLE invite_controls
  ADD COLUMN paused_reason text CHECK (paused_reason IN ('owner', 'host', 'auto'));

-- The R7 trailing-window count of opens per link.
CREATE INDEX invite_opens_invite_rendered_idx ON invite_opens (invite_id, first_rendered_at);
-- My plans and next-steps (S4 §4.12).
CREATE INDEX bookings_user_id_idx ON bookings (user_id);
CREATE INDEX activities_starts_at_idx ON activities (starts_at);

RESET ROLE;

-- migrate:down
