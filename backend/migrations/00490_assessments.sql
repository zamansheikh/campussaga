-- +goose Up
-- Tests and deadlines of a class group: class tests, quizzes, assignments,
-- lab reports, presentations, mid and final exams. Any member adds one; the
-- member who added it and the CRs can change or delete it.
CREATE TABLE assessments (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id     uuid        NOT NULL REFERENCES class_groups (id) ON DELETE CASCADE,
    kind         text        NOT NULL CHECK (kind IN ('class_test', 'quiz', 'assignment', 'lab_report',
                                                      'presentation', 'midterm', 'final', 'other')),
    course_code  text        NOT NULL CHECK (char_length(course_code) BETWEEN 1 AND 20),
    course_title text        NOT NULL DEFAULT '' CHECK (char_length(course_title) <= 100),
    date         date        NOT NULL,
    -- Minutes after midnight, Bangladesh time. NULL = no time set; for an
    -- assignment, starts_min is the due time.
    starts_min   smallint    CHECK (starts_min BETWEEN 0 AND 1439),
    ends_min     smallint    CHECK (ends_min BETWEEN 1 AND 1440),
    room         text        NOT NULL DEFAULT '' CHECK (char_length(room) <= 30),
    topics       text        NOT NULL DEFAULT '' CHECK (char_length(topics) <= 500),
    created_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_min IS NULL OR (starts_min IS NOT NULL AND ends_min > starts_min))
);
CREATE INDEX assessments_group_date_idx ON assessments (group_id, date);
CREATE TRIGGER assessments_set_updated_at BEFORE UPDATE ON assessments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE assessments;
