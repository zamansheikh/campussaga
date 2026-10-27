-- +goose Up
-- A change to the routine on one date, made by the CR:
--   cancelled: that class doesn't happen on that date
--   moved:     it happens at another time and/or room on that date
--   extra:     an extra (makeup) class on that date, not in the weekly routine
CREATE TABLE routine_changes (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id     uuid        NOT NULL REFERENCES class_groups (id) ON DELETE CASCADE,
    slot_id      uuid        REFERENCES routine_slots (id) ON DELETE CASCADE,
    date         date        NOT NULL,
    kind         text        NOT NULL CHECK (kind IN ('cancelled', 'moved', 'extra')),
    -- Extra classes only (moved and cancelled classes keep the slot's).
    course_code  text        NOT NULL DEFAULT '' CHECK (char_length(course_code) <= 20),
    course_title text        NOT NULL DEFAULT '' CHECK (char_length(course_title) <= 100),
    teacher      text        NOT NULL DEFAULT '' CHECK (char_length(teacher) <= 60),
    class_kind   text        NOT NULL DEFAULT 'theory' CHECK (class_kind IN ('theory', 'lab')),
    -- Moved and extra: the new times; room '' = unchanged (moved) / none (extra).
    room         text        NOT NULL DEFAULT '' CHECK (char_length(room) <= 30),
    starts_min   smallint    CHECK (starts_min BETWEEN 0 AND 1439),
    ends_min     smallint    CHECK (ends_min BETWEEN 1 AND 1440),
    note         text        NOT NULL DEFAULT '' CHECK (char_length(note) <= 200),
    created_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CHECK ((kind = 'extra') = (slot_id IS NULL)),
    CHECK (kind = 'cancelled' OR (starts_min IS NOT NULL AND ends_min > starts_min)),
    CHECK (kind <> 'extra' OR char_length(course_code) >= 1)
);
-- One change per class per date (a new one replaces it).
CREATE UNIQUE INDEX routine_changes_slot_date_key ON routine_changes (slot_id, date)
    WHERE slot_id IS NOT NULL;
CREATE INDEX routine_changes_group_date_idx ON routine_changes (group_id, date);
CREATE TRIGGER routine_changes_set_updated_at BEFORE UPDATE ON routine_changes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE routine_changes;
