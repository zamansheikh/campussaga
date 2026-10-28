-- +goose Up
-- A demo university exists only for app-store reviewers (see docs/BETA.md,
-- "Reviewer access"). It is hidden from every list other students see.
ALTER TABLE universities ADD COLUMN is_demo boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE universities DROP COLUMN is_demo;
