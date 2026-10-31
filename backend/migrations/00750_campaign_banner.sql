-- +goose Up
-- A campaign's banner photo (docs/GROWTH.md): the stored JPEG's key and a
-- version for cache-busting URLs. Null: the app draws its own banner.
ALTER TABLE campaigns ADD COLUMN banner_key text, ADD COLUMN banner_version text;

-- +goose Down
ALTER TABLE campaigns DROP COLUMN banner_version, DROP COLUMN banner_key;
