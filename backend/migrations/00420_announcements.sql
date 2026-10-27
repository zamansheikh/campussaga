-- +goose Up
-- Short messages from the CR to the class group ("Bring a calculator
-- tomorrow"). At most one is pinned to the top.
CREATE TABLE announcements (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id   uuid        NOT NULL REFERENCES class_groups (id) ON DELETE CASCADE,
    body       text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
    pinned     boolean     NOT NULL DEFAULT false,
    created_by uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX announcements_group_created_idx ON announcements (group_id, created_at DESC);
CREATE UNIQUE INDEX announcements_one_pinned_key ON announcements (group_id) WHERE pinned;
CREATE TRIGGER announcements_set_updated_at BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE announcements;
