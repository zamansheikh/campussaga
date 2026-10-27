-- +goose Up
-- Courses a member doesn't take in a group (e.g. joined another section
-- for one retake course). Keys are course codes in upper case, no spaces.
CREATE TABLE class_member_hidden_courses (
    group_id   uuid NOT NULL,
    user_id    uuid NOT NULL,
    course_key text NOT NULL CHECK (char_length(course_key) BETWEEN 1 AND 20),
    PRIMARY KEY (group_id, user_id, course_key),
    FOREIGN KEY (group_id, user_id) REFERENCES class_group_members (group_id, user_id) ON DELETE CASCADE
);

-- A student's own entries (tuition, a job, a lab with another section).
-- Only the owner ever sees them.
CREATE TABLE personal_slots (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title      text        NOT NULL CHECK (char_length(title) BETWEEN 1 AND 40),
    details    text        NOT NULL DEFAULT '' CHECK (char_length(details) <= 100),
    place      text        NOT NULL DEFAULT '' CHECK (char_length(place) <= 40),
    weekday    smallint    NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    starts_min smallint    NOT NULL CHECK (starts_min BETWEEN 0 AND 1439),
    ends_min   smallint    NOT NULL CHECK (ends_min BETWEEN 1 AND 1440),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_min > starts_min)
);
CREATE INDEX personal_slots_user_idx ON personal_slots (user_id, weekday, starts_min);
CREATE TRIGGER personal_slots_set_updated_at BEFORE UPDATE ON personal_slots
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Safety net: a group with members always has a CR. When the last CR
-- disappears (e.g. deleted their account), the longest member becomes CR.
-- +goose StatementBegin
CREATE FUNCTION class_group_keep_a_cr() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM class_group_members
                   WHERE group_id = OLD.group_id AND role = 'cr') THEN
        UPDATE class_group_members SET role = 'cr'
        WHERE (group_id, user_id) = (
            SELECT group_id, user_id FROM class_group_members
            WHERE group_id = OLD.group_id
            ORDER BY joined_at, user_id LIMIT 1);
    END IF;
    RETURN NULL;
END $$;
-- +goose StatementEnd
CREATE TRIGGER class_group_members_keep_a_cr AFTER DELETE ON class_group_members
    FOR EACH ROW WHEN (OLD.role = 'cr') EXECUTE FUNCTION class_group_keep_a_cr();

-- +goose Down
DROP TRIGGER class_group_members_keep_a_cr ON class_group_members;
DROP FUNCTION class_group_keep_a_cr();
DROP TABLE personal_slots;
DROP TABLE class_member_hidden_courses;
