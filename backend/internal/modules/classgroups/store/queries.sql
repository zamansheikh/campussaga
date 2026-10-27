-- ---- groups ---------------------------------------------------------------

-- name: CreateGroup :one
INSERT INTO class_groups (university_id, department, batch, section, semester, join_code, created_by)
VALUES (@university_id, @department, @batch, @section, @semester, @join_code, @created_by)
RETURNING *;

-- name: UpdateGroup :one
UPDATE class_groups
SET department = @department, batch = @batch, section = @section, semester = @semester
WHERE id = @id
RETURNING *;

-- Marks the group changed (routine edits), so apps know to refresh.
-- name: TouchGroup :exec
UPDATE class_groups SET updated_at = now() WHERE id = @id;

-- name: DeleteGroup :exec
DELETE FROM class_groups WHERE id = @id;

-- name: GetGroupByCode :one
SELECT * FROM class_groups WHERE join_code = @join_code;

-- name: GetGroupForUpdate :one
SELECT * FROM class_groups WHERE id = @id FOR UPDATE;

-- ---- members --------------------------------------------------------------

-- name: AddMember :exec
INSERT INTO class_group_members (group_id, user_id, role) VALUES (@group_id, @user_id, @role)
ON CONFLICT (group_id, user_id) DO NOTHING;

-- name: RemoveMember :exec
DELETE FROM class_group_members WHERE group_id = @group_id AND user_id = @user_id;

-- name: GetRole :one
SELECT role FROM class_group_members WHERE group_id = @group_id AND user_id = @user_id;

-- name: CountUserGroups :one
SELECT count(*) FROM class_group_members WHERE user_id = @user_id;

-- name: CountMembers :one
SELECT count(*) FROM class_group_members WHERE group_id = @group_id;

-- name: CountCRs :one
SELECT count(*) FROM class_group_members WHERE group_id = @group_id AND role = 'cr';

-- name: ListMyGroups :many
SELECT sqlc.embed(g), m.role,
       (SELECT count(*) FROM class_group_members x WHERE x.group_id = g.id) AS member_count
FROM class_groups g
JOIN class_group_members m ON m.group_id = g.id
WHERE m.user_id = @user_id
ORDER BY m.joined_at, g.id;

-- ---- routine --------------------------------------------------------------

-- name: ListSlotsForUser :many
SELECT s.* FROM routine_slots s
JOIN class_group_members m ON m.group_id = s.group_id
WHERE m.user_id = @user_id
ORDER BY s.weekday, s.starts_min, s.course_code, s.id;

-- name: ListSlots :many
SELECT * FROM routine_slots WHERE group_id = @group_id
ORDER BY weekday, starts_min, course_code, id;

-- name: CountSlots :one
SELECT count(*) FROM routine_slots WHERE group_id = @group_id;

-- name: CreateSlot :one
INSERT INTO routine_slots (group_id, course_code, course_title, teacher, room, weekday, starts_min, ends_min, kind)
VALUES (@group_id, @course_code, @course_title, @teacher, @room, @weekday, @starts_min, @ends_min, @kind)
RETURNING *;

-- name: UpdateSlot :one
UPDATE routine_slots
SET course_code = @course_code, course_title = @course_title, teacher = @teacher, room = @room,
    weekday = @weekday, starts_min = @starts_min, ends_min = @ends_min, kind = @kind
WHERE id = @id AND group_id = @group_id
RETURNING *;

-- name: DeleteSlot :execrows
DELETE FROM routine_slots WHERE id = @id AND group_id = @group_id;
