-- +goose Up
-- A group an admin publishes from an official routine (for example a
-- department's whole program) stays when its last member leaves; other
-- groups are deleted then, as before.
ALTER TABLE class_groups ADD COLUMN keep_when_empty boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE class_groups DROP COLUMN keep_when_empty;
