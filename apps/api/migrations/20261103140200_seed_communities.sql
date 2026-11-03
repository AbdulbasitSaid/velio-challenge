-- migrate:up

-- Reference data (PRD Q11). Blurbs and cover photos are placeholders until S5.
SET LOCAL ROLE velio_owner;

INSERT INTO communities (slug, name, blurb) VALUES
  ('explore-kenya', 'Explore Kenya', 'Activities shared by the Explore Kenya community.'),
  ('the-tanzania-experience', 'The Tanzania Experience', 'Activities shared by The Tanzania Experience community.'),
  ('the-medina-collective', 'The Medina Collective', 'Activities shared by The Medina Collective community.');

-- dbmate records the migration in this transaction, as the connecting role.
RESET ROLE;

-- migrate:down
