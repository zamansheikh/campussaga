-- Removes everything review-seed.sql created: the demo university and all
-- of its users (the reviewer included, with their sessions), groups, routine,
-- tests, announcements and Campus Voice issues.
--
--   docker compose exec -T postgres psql -U campus -d campus < review-unseed.sql
--
-- Only touches rows that belong to the university with slug 'demo-review'
-- and is_demo = true. Safe to run when nothing is seeded.

\set ON_ERROR_STOP on

BEGIN;

DO $unseed$
DECLARE
    v_uni uuid;
BEGIN
    SELECT id INTO v_uni FROM universities WHERE slug = 'demo-review' AND is_demo;
    IF v_uni IS NULL THEN
        RAISE NOTICE 'no demo university, nothing to remove';
        RETURN;
    END IF;

    -- Voice issues (comments, votes, authors, status updates cascade).
    DELETE FROM issues WHERE university_id = v_uni;
    -- Groups (members, routine, tests, announcements cascade). The "keep a CR"
    -- trigger only fires on member deletes, which cascade from the group here.
    DELETE FROM class_groups WHERE university_id = v_uni;
    -- Users (sessions, device tokens and the rest cascade).
    DELETE FROM users WHERE university_id = v_uni;
    DELETE FROM sign_in_codes WHERE university_id = v_uni;
    -- The university (its domains cascade).
    DELETE FROM universities WHERE id = v_uni;
END
$unseed$;

COMMIT;

SELECT count(*) AS demo_universities_left FROM universities WHERE slug = 'demo-review';
