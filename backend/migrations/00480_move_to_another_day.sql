-- +goose Up
-- A class moved to another day (a teacher moves Friday's class to
-- Wednesday): one "moved" change on the class's own date, with the day it
-- happens instead. NULL = the same day (time or room change).
ALTER TABLE routine_changes ADD COLUMN new_date date;
ALTER TABLE routine_changes ADD CONSTRAINT routine_changes_new_date_check
    CHECK (new_date IS NULL OR (kind = 'moved' AND new_date <> date));
CREATE INDEX routine_changes_group_new_date_idx ON routine_changes (group_id, new_date)
    WHERE new_date IS NOT NULL;

-- +goose Down
DROP INDEX routine_changes_group_new_date_idx;
DELETE FROM routine_changes WHERE new_date IS NOT NULL;
ALTER TABLE routine_changes DROP CONSTRAINT routine_changes_new_date_check;
ALTER TABLE routine_changes DROP COLUMN new_date;
