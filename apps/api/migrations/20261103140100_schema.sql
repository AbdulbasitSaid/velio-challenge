-- migrate:up

-- Every object below is owned by velio_owner.
SET LOCAL ROLE velio_owner;

-- Custom SQLSTATEs (class VL) raised by triggers; the API maps them to error codes.
--   VL001 location_locked   VL002 append_only   VL003 immutable_column   VL004 invalid_timezone

-- ---------------------------------------------------------------------------
-- Trigger functions
-- ---------------------------------------------------------------------------

-- Second guard for insert-only tables, after the missing grants. Applies to every role, owner included.
CREATE FUNCTION forbid_update_delete() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'append_only: % is insert-only (% rejected)', TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'VL002';
END
$$;

CREATE FUNCTION users_immutable_columns() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.invite_generation IS DISTINCT FROM OLD.invite_generation THEN
    RAISE EXCEPTION 'immutable_column: users.invite_generation' USING ERRCODE = 'VL003';
  END IF;
  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'immutable_column: users.created_at' USING ERRCODE = 'VL003';
  END IF;
  RETURN NEW;
END
$$;

CREATE FUNCTION activities_check_timezone() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_timezone_names WHERE name = NEW.timezone) THEN
    RAISE EXCEPTION 'invalid_timezone: %', NEW.timezone USING ERRCODE = 'VL004';
  END IF;
  RETURN NEW;
END
$$;

-- PRD Q2, Q13 and the Google Maps spec §5.1: once an activity has a confirmed booking,
-- its date, time zone and location cannot change.
CREATE FUNCTION activities_location_lock() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (NEW.starts_at, NEW.timezone, NEW.place_id, NEW.venue_name, NEW.address_text,
      NEW.lat, NEW.lng, NEW.meeting_point)
     IS DISTINCT FROM
     (OLD.starts_at, OLD.timezone, OLD.place_id, OLD.venue_name, OLD.address_text,
      OLD.lat, OLD.lng, OLD.meeting_point)
     AND EXISTS (SELECT 1 FROM bookings WHERE activity_id = OLD.id AND status = 'confirmed')
  THEN
    RAISE EXCEPTION 'location_locked' USING ERRCODE = 'VL001';
  END IF;
  RETURN NEW;
END
$$;

-- ---------------------------------------------------------------------------
-- Tables (MVP plan §4.3). (AO) marks insert-only tables.
-- ---------------------------------------------------------------------------

CREATE TABLE communities (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  slug            text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name            text NOT NULL CHECK (btrim(name) <> ''),
  blurb           text NOT NULL,
  cover_photo_key text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id                uuid PRIMARY KEY DEFAULT uuidv7(),
  display_name      text NOT NULL CHECK (btrim(display_name) <> ''),
  -- HMAC-SHA256(CONTACT_PEPPER, normalised contact). The raw contact is never stored here.
  contact_hash      bytea NOT NULL UNIQUE CHECK (octet_length(contact_hash) = 32),
  invite_generation integer NOT NULL DEFAULT 0 CHECK (invite_generation >= 0),
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER users_immutable_columns
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION users_immutable_columns();

CREATE TABLE sessions (
  -- SHA-256 of the token. The token itself is never stored.
  token_hash          bytea PRIMARY KEY CHECK (octet_length(token_hash) = 32),
  user_id             uuid NOT NULL REFERENCES users (id),
  device_id           text,
  created_at          timestamptz NOT NULL,
  last_renewed_at     timestamptz NOT NULL,
  -- Sliding idle expiry.
  expires_at          timestamptz NOT NULL,
  -- Absolute expiry: created_at plus the absolute timeout. Never extended.
  absolute_expires_at timestamptz NOT NULL
);
CREATE INDEX sessions_user_id_idx ON sessions (user_id);
CREATE INDEX sessions_expires_at_idx ON sessions (LEAST(expires_at, absolute_expires_at));

CREATE TABLE activities (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  host_id         uuid NOT NULL REFERENCES users (id),
  community_id    uuid NOT NULL REFERENCES communities (id),
  title           text NOT NULL CHECK (btrim(title) <> ''),
  description     text NOT NULL DEFAULT '',
  photo_key       text,
  starts_at       timestamptz NOT NULL,
  timezone        text NOT NULL,
  place_id        text,
  venue_name      text NOT NULL CHECK (btrim(venue_name) <> ''),
  address_text    text NOT NULL CHECK (btrim(address_text) <> ''),
  lat             numeric(9, 6) NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng             numeric(9, 6) NOT NULL CHECK (lng BETWEEN -180 AND 180),
  meeting_point   text CHECK (char_length(meeting_point) <= 140),
  price_minor     bigint NOT NULL CHECK (price_minor > 0),
  currency        text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
  capacity        integer NOT NULL CHECK (capacity >= 1),
  spots_left      integer NOT NULL,
  version         bigint NOT NULL DEFAULT 0,
  bookings_paused boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT activities_spots_left_range CHECK (spots_left >= 0 AND spots_left <= capacity)
);
CREATE INDEX activities_host_id_idx ON activities (host_id);
CREATE INDEX activities_community_starts_idx ON activities (community_id, starts_at);

CREATE TRIGGER activities_check_timezone
  BEFORE INSERT OR UPDATE OF timezone ON activities
  FOR EACH ROW EXECUTE FUNCTION activities_check_timezone();

CREATE TRIGGER activities_location_lock
  BEFORE UPDATE ON activities
  FOR EACH ROW EXECUTE FUNCTION activities_location_lock();

CREATE TABLE plans (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  activity_id uuid NOT NULL REFERENCES activities (id),
  owner_id    uuid NOT NULL REFERENCES users (id),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX plans_activity_id_idx ON plans (activity_id);
CREATE INDEX plans_owner_id_idx ON plans (owner_id);

-- (AO)
CREATE TABLE invites (
  id                   uuid PRIMARY KEY DEFAULT uuidv7(),
  code                 text NOT NULL UNIQUE CHECK (code ~ '^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$'),
  rail                 text NOT NULL CHECK (rail IN ('vouch', 'public')),
  activity_id          uuid NOT NULL REFERENCES activities (id),
  plan_id              uuid NOT NULL REFERENCES plans (id),
  inviter_id           uuid NOT NULL REFERENCES users (id),
  invitee_name         text,
  invitee_contact_hash bytea,
  note                 text,
  expires_at           timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  -- Hash chain per activity, computed in S4.
  prev_hash            bytea,
  row_hash             bytea
);
CREATE INDEX invites_plan_id_idx ON invites (plan_id);
CREATE INDEX invites_activity_id_idx ON invites (activity_id);

-- Mutable operational state, kept out of the insert-only invites table.
CREATE TABLE invite_controls (
  invite_id  uuid PRIMARY KEY REFERENCES invites (id),
  paused     boolean NOT NULL DEFAULT false,
  paused_by  uuid REFERENCES users (id),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE invite_opens (
  invite_id         uuid NOT NULL REFERENCES invites (id),
  device_id         text NOT NULL,
  first_rendered_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (invite_id, device_id)
);

CREATE TABLE bookings (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  ref             text NOT NULL UNIQUE CHECK (ref ~ '^VLO-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$'),
  activity_id     uuid NOT NULL REFERENCES activities (id),
  user_id         uuid NOT NULL REFERENCES users (id),
  plan_id         uuid NOT NULL REFERENCES plans (id),
  source          text NOT NULL CHECK (source IN ('direct', 'vouch', 'public')),
  invite_id       uuid REFERENCES invites (id),
  idempotency_key text NOT NULL,
  status          text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'removed')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT bookings_user_idempotency_key UNIQUE (user_id, idempotency_key)
);
-- One confirmed booking per person per activity.
CREATE UNIQUE INDEX bookings_one_confirmed_per_user
  ON bookings (activity_id, user_id) WHERE status = 'confirmed';
CREATE INDEX bookings_plan_id_idx ON bookings (plan_id);

-- (AO)
CREATE TABLE invite_claims (
  booking_id uuid PRIMARY KEY REFERENCES bookings (id),
  invite_id  uuid NOT NULL REFERENCES invites (id),
  rail       text NOT NULL CHECK (rail IN ('vouch', 'public')),
  claimed_at timestamptz NOT NULL DEFAULT now()
);
-- A vouch invite is single use.
CREATE UNIQUE INDEX invite_claims_one_per_vouch ON invite_claims (invite_id) WHERE rail = 'vouch';
CREATE INDEX invite_claims_invite_id_idx ON invite_claims (invite_id);

-- (AO) First claim wins forever (PRD D4).
CREATE TABLE attributions (
  invitee_id uuid PRIMARY KEY REFERENCES users (id),
  inviter_id uuid NOT NULL REFERENCES users (id),
  invite_id  uuid NOT NULL REFERENCES invites (id),
  rail       text NOT NULL CHECK (rail IN ('vouch', 'public')),
  generation integer NOT NULL CHECK (generation >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  -- Hash chain per activity, computed in S4.
  prev_hash  bytea,
  row_hash   bytea
);
CREATE INDEX attributions_inviter_id_idx ON attributions (inviter_id);

-- (AO)
CREATE TABLE trust_edges (
  id         uuid PRIMARY KEY DEFAULT uuidv7(),
  voucher_id uuid NOT NULL REFERENCES users (id),
  vouchee_id uuid NOT NULL REFERENCES users (id),
  invite_id  uuid NOT NULL REFERENCES invites (id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX trust_edges_voucher_id_idx ON trust_edges (voucher_id);

-- (AO) The latest mark per booking wins.
CREATE TABLE attendance_marks (
  id         uuid PRIMARY KEY DEFAULT uuidv7(),
  booking_id uuid NOT NULL REFERENCES bookings (id),
  mark       text NOT NULL CHECK (mark IN ('attended', 'no_show')),
  marked_by  uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX attendance_marks_booking_idx ON attendance_marks (booking_id, created_at DESC);

-- (AO)
CREATE TABLE booking_removals (
  id         uuid PRIMARY KEY DEFAULT uuidv7(),
  booking_id uuid NOT NULL REFERENCES bookings (id),
  removed_by uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX booking_removals_booking_id_idx ON booking_removals (booking_id);

CREATE TABLE exposures (
  user_id          uuid NOT NULL REFERENCES users (id),
  flag             text NOT NULL,
  arm              text NOT NULL,
  first_exposed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, flag)
);

-- Analytics funnel events (PRD Success metrics).
CREATE TABLE events (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        text NOT NULL,
  user_id     uuid REFERENCES users (id),
  activity_id uuid REFERENCES activities (id),
  invite_id   uuid REFERENCES invites (id),
  rail        text,
  generation  integer,
  platform    text,
  props       jsonb NOT NULL DEFAULT '{}',
  at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX events_name_at_idx ON events (name, at);

-- Fixed-window counters (MVP plan §4.7). Logic arrives in S4.
CREATE TABLE rate_limits (
  key          text NOT NULL,
  window_start timestamptz NOT NULL,
  count        integer NOT NULL DEFAULT 0 CHECK (count >= 0),
  PRIMARY KEY (key, window_start)
);

-- ---------------------------------------------------------------------------
-- Insert-only enforcement: the trigger is the second guard after the grants below.
-- ---------------------------------------------------------------------------

CREATE TRIGGER invites_insert_only BEFORE UPDATE OR DELETE ON invites
  FOR EACH ROW EXECUTE FUNCTION forbid_update_delete();
CREATE TRIGGER invite_claims_insert_only BEFORE UPDATE OR DELETE ON invite_claims
  FOR EACH ROW EXECUTE FUNCTION forbid_update_delete();
CREATE TRIGGER attributions_insert_only BEFORE UPDATE OR DELETE ON attributions
  FOR EACH ROW EXECUTE FUNCTION forbid_update_delete();
CREATE TRIGGER trust_edges_insert_only BEFORE UPDATE OR DELETE ON trust_edges
  FOR EACH ROW EXECUTE FUNCTION forbid_update_delete();
CREATE TRIGGER attendance_marks_insert_only BEFORE UPDATE OR DELETE ON attendance_marks
  FOR EACH ROW EXECUTE FUNCTION forbid_update_delete();
CREATE TRIGGER booking_removals_insert_only BEFORE UPDATE OR DELETE ON booking_removals
  FOR EACH ROW EXECUTE FUNCTION forbid_update_delete();

-- ---------------------------------------------------------------------------
-- Grants. velio_api never gets DELETE, except on sessions and rate_limits.
-- ---------------------------------------------------------------------------

-- Insert-only tables.
GRANT SELECT, INSERT ON invites, invite_claims, attributions, trust_edges, attendance_marks,
  booking_removals TO velio_api;

-- Mutable tables.
GRANT SELECT, INSERT, UPDATE ON communities, users, activities, plans, invite_controls,
  invite_opens, bookings, exposures, events TO velio_api;

GRANT SELECT, INSERT, UPDATE, DELETE ON sessions, rate_limits TO velio_api;

GRANT USAGE ON SEQUENCE events_id_seq TO velio_api;

-- Explicit list: "ALL TABLES" would include dbmate's schema_migrations, which velio_owner doesn't own.
GRANT SELECT ON communities, users, sessions, activities, plans, invites, invite_controls,
  invite_opens, bookings, invite_claims, attributions, trust_edges, attendance_marks,
  booking_removals, exposures, events, rate_limits TO velio_readonly;

-- dbmate records the migration in this transaction, as the connecting role.
RESET ROLE;

-- migrate:down
