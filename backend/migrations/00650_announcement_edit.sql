-- +goose Up
-- A CR can fix an announcement's text; the app shows "Edited" (pinning
-- doesn't count as an edit, so updated_at isn't enough).
ALTER TABLE announcements ADD COLUMN edited_at timestamptz;

-- +goose Down
ALTER TABLE announcements DROP COLUMN edited_at;
