-- +goose Up
-- Profile photos. google_photo_url: the Google account photo, refreshed at
-- each Google sign-in. photo_key: a photo the student uploaded (media store
-- key, re-encoded, metadata removed); it wins over the Google one. Shown to
-- the student, to classmates sharing a class group, and to admins.
ALTER TABLE users
    ADD COLUMN google_photo_url text
        CHECK (google_photo_url ~ '^https://' AND char_length(google_photo_url) <= 500),
    ADD COLUMN photo_key text CHECK (photo_key ~ '^[a-z0-9-]{8,80}\.jpg$');

-- +goose Down
ALTER TABLE users
    DROP COLUMN photo_key,
    DROP COLUMN google_photo_url;
