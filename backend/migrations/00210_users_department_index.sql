-- +goose Up
-- Department suggestions group by lower(department) within a university.
CREATE INDEX users_university_department_idx ON users (university_id, lower(department))
    WHERE department IS NOT NULL;

-- +goose Down
DROP INDEX users_university_department_idx;
