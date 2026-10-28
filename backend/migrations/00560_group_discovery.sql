-- +goose Up
-- "Find your class": students search their university's class groups and
-- join a whole section or only some of its courses.

-- Findable by students of the same university; the CR can make a group
-- "code only" (still joinable with its code).
ALTER TABLE class_groups ADD COLUMN discoverable boolean NOT NULL DEFAULT true;

-- A member who joined for some courses only: courses the CR adds later
-- stay hidden for them (class_member_hidden_courses), like the rest.
ALTER TABLE class_group_members ADD COLUMN courses_only boolean NOT NULL DEFAULT false;

-- Search by department, batch, section, course code/title and teacher.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX class_groups_department_trgm ON class_groups USING gin (department gin_trgm_ops);
CREATE INDEX class_groups_batch_trgm ON class_groups USING gin (batch gin_trgm_ops);
CREATE INDEX class_groups_section_trgm ON class_groups USING gin (section gin_trgm_ops);
CREATE INDEX routine_slots_course_code_trgm ON routine_slots USING gin (course_code gin_trgm_ops);
CREATE INDEX routine_slots_course_title_trgm ON routine_slots USING gin (course_title gin_trgm_ops);
CREATE INDEX routine_slots_teacher_trgm ON routine_slots USING gin (teacher gin_trgm_ops);
CREATE INDEX class_groups_university_discoverable_idx ON class_groups (university_id) WHERE discoverable;

-- +goose Down
DROP INDEX class_groups_university_discoverable_idx;
DROP INDEX routine_slots_teacher_trgm;
DROP INDEX routine_slots_course_title_trgm;
DROP INDEX routine_slots_course_code_trgm;
DROP INDEX class_groups_section_trgm;
DROP INDEX class_groups_batch_trgm;
DROP INDEX class_groups_department_trgm;
ALTER TABLE class_group_members DROP COLUMN courses_only;
ALTER TABLE class_groups DROP COLUMN discoverable;
