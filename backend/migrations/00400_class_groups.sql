-- +goose Up
-- A class group is one section's routine, run by its CR (class
-- representative). Students join with a 6-letter code.
CREATE TABLE class_groups (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id uuid        NOT NULL REFERENCES universities (id),
    department    text        NOT NULL CHECK (char_length(department) BETWEEN 1 AND 80),
    batch         text        NOT NULL CHECK (char_length(batch) BETWEEN 1 AND 20),
    section       text        NOT NULL DEFAULT '' CHECK (char_length(section) <= 20),
    semester      text        NOT NULL CHECK (char_length(semester) BETWEEN 1 AND 30),
    -- No I or O, so a code read aloud or from a screenshot is unambiguous.
    join_code     text        NOT NULL UNIQUE CHECK (join_code ~ '^[A-HJ-NP-Z]{6}$'),
    created_by    uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX class_groups_university_id_idx ON class_groups (university_id);
CREATE TRIGGER class_groups_set_updated_at BEFORE UPDATE ON class_groups
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE class_group_members (
    group_id  uuid        NOT NULL REFERENCES class_groups (id) ON DELETE CASCADE,
    user_id   uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role      text        NOT NULL CHECK (role IN ('cr', 'member')),
    joined_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (group_id, user_id)
);
CREATE INDEX class_group_members_user_id_idx ON class_group_members (user_id);

-- One weekly class. Times are minutes after midnight, local (Bangladesh)
-- time; weekday is ISO (1 = Monday ... 7 = Sunday).
CREATE TABLE routine_slots (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id     uuid        NOT NULL REFERENCES class_groups (id) ON DELETE CASCADE,
    course_code  text        NOT NULL CHECK (char_length(course_code) BETWEEN 1 AND 20),
    course_title text        NOT NULL DEFAULT '' CHECK (char_length(course_title) <= 100),
    teacher      text        NOT NULL DEFAULT '' CHECK (char_length(teacher) <= 60),
    room         text        NOT NULL DEFAULT '' CHECK (char_length(room) <= 30),
    weekday      smallint    NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    starts_min   smallint    NOT NULL CHECK (starts_min BETWEEN 0 AND 1439),
    ends_min     smallint    NOT NULL CHECK (ends_min BETWEEN 1 AND 1440),
    kind         text        NOT NULL DEFAULT 'theory' CHECK (kind IN ('theory', 'lab')),
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_min > starts_min)
);
CREATE INDEX routine_slots_group_idx ON routine_slots (group_id, weekday, starts_min);
CREATE TRIGGER routine_slots_set_updated_at BEFORE UPDATE ON routine_slots
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE routine_slots;
DROP TABLE class_group_members;
DROP TABLE class_groups;
