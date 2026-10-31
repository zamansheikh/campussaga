-- +goose Up
-- Optional extras for a course of a group, set by the CR: the class chat
-- group, the Google Classroom code, a materials folder, the teacher's
-- email and a short note. One row per course (course_key as for hidden
-- courses: upper case, no spaces); no row = nothing added.
CREATE TABLE group_courses (
  group_id       uuid NOT NULL REFERENCES class_groups (id) ON DELETE CASCADE,
  course_key     text NOT NULL CHECK (char_length(course_key) BETWEEN 1 AND 20),
  chat_link      text NOT NULL DEFAULT '' CHECK (char_length(chat_link) <= 300),
  classroom_code text NOT NULL DEFAULT '' CHECK (char_length(classroom_code) <= 20),
  materials_link text NOT NULL DEFAULT '' CHECK (char_length(materials_link) <= 300),
  teacher_email  text NOT NULL DEFAULT '' CHECK (char_length(teacher_email) <= 120),
  notes          text NOT NULL DEFAULT '' CHECK (char_length(notes) <= 500),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, course_key)
);

-- +goose Down
DROP TABLE group_courses;
