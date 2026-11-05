-- migrate:up

-- S8 (spec/2026-11-05_08-36_s8-metrics-flags-admin, PLANNING §4.3). Views for the PRD's success
-- metrics. Each row is one fact with the timestamp a reporting window applies to; the admin
-- endpoint aggregates them per window, and analysts can query them directly.
SET LOCAL ROLE velio_owner;

-- The latest attendance mark per booking (the table is insert-only; the newest mark wins).
CREATE VIEW v_latest_mark AS
SELECT DISTINCT ON (booking_id) booking_id, mark
  FROM attendance_marks
 ORDER BY booking_id, created_at DESC, id DESC;

-- PRD "Never oversell": activities whose confirmed bookings exceed capacity. Must stay empty.
CREATE VIEW v_oversell AS
SELECT a.id AS activity_id, a.capacity, count(b.id)::int AS confirmed
  FROM activities a
  JOIN bookings b ON b.activity_id = a.id AND b.status = 'confirmed'
 GROUP BY a.id, a.capacity
HAVING count(b.id) > a.capacity;

-- PRD "Bookings succeed": attempts on available spots. Typed refusals (sold out, already booked,
-- paused, …) are answers, not failures, so only successes and server errors count.
CREATE VIEW v_booking_success AS
SELECT at, CASE name WHEN 'booking_succeeded' THEN 'success' ELSE 'error' END AS outcome
  FROM events
 WHERE name IN ('booking_succeeded', 'booking_failed');

-- PRD "Bookers invite": one row per booker with a group_invites exposure, and whether they created
-- an invite of each rail within 24 h of their first booking.
CREATE VIEW v_invite_rate AS
WITH bookers AS (
  SELECT user_id, min(created_at) AS first_booked_at FROM bookings GROUP BY user_id
)
SELECT k.user_id,
       e.arm,
       k.first_booked_at,
       EXISTS (SELECT 1 FROM invites i
                WHERE i.inviter_id = k.user_id AND i.rail = 'vouch'
                  AND i.created_at < k.first_booked_at + interval '24 hours') AS invited_vouch,
       EXISTS (SELECT 1 FROM invites i
                WHERE i.inviter_id = k.user_id AND i.rail = 'public'
                  AND i.created_at < k.first_booked_at + interval '24 hours') AS invited_public
  FROM bookers k
  JOIN exposures e ON e.user_id = k.user_id AND e.flag = 'group_invites';

-- PRD "Invites convert", per rail (D1): unique human opens (one per invite and device, from the
-- render beacon) and claims, per invite.
CREATE VIEW v_open_to_claim_by_rail AS
SELECT i.id AS invite_id,
       i.rail,
       i.created_at,
       (SELECT count(*) FROM invite_opens o WHERE o.invite_id = i.id)::int AS opens,
       (SELECT count(*) FROM invite_claims c WHERE c.invite_id = i.id)::int AS claims
  FROM invites i;

-- PRD core metric, K-factor per rail: new users each invite brought in (attributions are written
-- only for a new user's first claim; later vouches are trust edges and don't count, D4).
CREATE VIEW v_k_factor_by_rail AS
SELECT i.id AS invite_id,
       i.inviter_id,
       i.rail,
       i.created_at,
       (SELECT count(*) FROM attributions a WHERE a.invite_id = i.id)::int AS new_users
  FROM invites i;

-- PRD guardrail "Plans happen": Plans whose activity has started, and whether every confirmed
-- member was marked attended. `arm` is the Plan owner's (the booker), null if never exposed.
CREATE VIEW v_plans_happened AS
SELECT p.id AS plan_id,
       a.starts_at,
       e.arm,
       count(b.id) FILTER (WHERE b.status = 'confirmed')::int AS members,
       count(b.id) FILTER (WHERE b.status = 'confirmed' AND m.mark = 'attended')::int AS attended,
       (count(b.id) FILTER (WHERE b.status = 'confirmed') > 0
        AND count(b.id) FILTER (WHERE b.status = 'confirmed')
          = count(b.id) FILTER (WHERE b.status = 'confirmed' AND m.mark = 'attended')) AS happened
  FROM plans p
  JOIN activities a ON a.id = p.activity_id AND a.starts_at <= now()
  LEFT JOIN bookings b ON b.plan_id = p.id
  LEFT JOIN v_latest_mark m ON m.booking_id = b.id
  LEFT JOIN exposures e ON e.user_id = p.owner_id AND e.flag = 'group_invites'
 GROUP BY p.id, a.starts_at, e.arm;

-- PRD guardrail: no-show and host-removal rate, invited vs organic, for started activities.
CREATE VIEW v_guardrail AS
SELECT b.id AS booking_id,
       a.starts_at,
       b.source <> 'direct' AS invited,
       (b.status = 'removed' OR m.mark = 'no_show') AS bad
  FROM bookings b
  JOIN activities a ON a.id = b.activity_id AND a.starts_at <= now()
  LEFT JOIN v_latest_mark m ON m.booking_id = b.id;

-- PRD Holdout design: per exposed user, their arm, whether they booked, and the new users they
-- brought in. Analysed at the booker level, intention-to-treat (R12).
CREATE VIEW v_holdout AS
SELECT e.user_id,
       e.arm,
       e.first_exposed_at,
       EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = e.user_id) AS booked,
       (SELECT count(*) FROM attributions a WHERE a.inviter_id = e.user_id)::int AS new_users
  FROM exposures e
 WHERE e.flag = 'group_invites';

GRANT SELECT ON v_latest_mark, v_oversell, v_booking_success, v_invite_rate, v_open_to_claim_by_rail,
  v_k_factor_by_rail, v_plans_happened, v_guardrail, v_holdout TO velio_api, velio_readonly;

-- The booking-success and invite-rate windows.
CREATE INDEX invites_inviter_id_idx ON invites (inviter_id);

RESET ROLE;

-- migrate:down
SET LOCAL ROLE velio_owner;
DROP INDEX invites_inviter_id_idx;
DROP VIEW v_holdout, v_guardrail, v_plans_happened, v_k_factor_by_rail, v_open_to_claim_by_rail,
  v_invite_rate, v_booking_success, v_oversell, v_latest_mark;
RESET ROLE;
