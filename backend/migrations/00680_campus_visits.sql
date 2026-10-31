-- +goose Up
-- Visit other campuses (docs/CAMPUS_VISITS.md): posts, questions and polls are
-- readable by students of other universities unless the author keeps them
-- inside ("Only my university"). Issues never leave their university.
ALTER TABLE issues ADD COLUMN campus_only boolean NOT NULL DEFAULT false;
UPDATE app_config SET value = jsonb_set(value, '{visitCampus}', 'true') WHERE key = 'features';

-- +goose Down
UPDATE app_config SET value = value - 'visitCampus' WHERE key = 'features';
ALTER TABLE issues DROP COLUMN campus_only;
