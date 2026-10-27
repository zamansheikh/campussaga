-- +goose Up
-- public / private, and the official website (shown in the app).
ALTER TABLE universities
    ADD COLUMN kind    text CHECK (kind IN ('public', 'private')),
    ADD COLUMN website text CHECK (website ~ '^[a-z0-9-]+(\.[a-z0-9-]+)+$');

-- +goose Down
ALTER TABLE universities DROP COLUMN website, DROP COLUMN kind;
