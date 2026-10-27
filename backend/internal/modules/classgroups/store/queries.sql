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

-- ---- changes (one date) ------------------------------------------------------

-- name: ListChangesForUser :many
SELECT c.* FROM routine_changes c
JOIN class_group_members m ON m.group_id = c.group_id
WHERE m.user_id = @user_id AND c.date >= @from_date
ORDER BY c.date, c.starts_min NULLS FIRST, c.id;

-- name: CountUpcomingChanges :one
SELECT count(*) FROM routine_changes WHERE group_id = @group_id AND date >= @from_date;

-- name: GetSlot :one
SELECT * FROM routine_slots WHERE id = @id AND group_id = @group_id;

-- name: DeleteSlotChangeOn :exec
DELETE FROM routine_changes WHERE slot_id = @slot_id AND date = @date;

-- A class moved to another weekday: its one-date changes no longer apply.
-- name: DeleteSlotChanges :exec
DELETE FROM routine_changes WHERE slot_id = @slot_id;

-- name: CreateChange :one
INSERT INTO routine_changes (group_id, slot_id, date, kind, course_code, course_title, teacher,
                             class_kind, room, starts_min, ends_min, note, created_by)
VALUES (@group_id, @slot_id, @date, @kind, @course_code, @course_title, @teacher,
        @class_kind, @room, @starts_min, @ends_min, @note, @created_by)
RETURNING *;

-- name: DeleteChange :execrows
DELETE FROM routine_changes WHERE id = @id AND group_id = @group_id;

-- ---- announcements -----------------------------------------------------------

-- The pinned one and recent ones, per group newest first.
-- name: ListAnnouncementsForUser :many
SELECT a.* FROM announcements a
JOIN class_group_members m ON m.group_id = a.group_id
WHERE m.user_id = @user_id AND (a.pinned OR a.created_at >= @since)
ORDER BY a.group_id, a.pinned DESC, a.created_at DESC, a.id;

-- name: CreateAnnouncement :one
INSERT INTO announcements (group_id, body, pinned, created_by)
VALUES (@group_id, @body, @pinned, @created_by)
RETURNING *;

-- name: UnpinAnnouncements :exec
UPDATE announcements SET pinned = false WHERE group_id = @group_id AND pinned;

-- name: SetAnnouncementPinned :one
UPDATE announcements SET pinned = @pinned WHERE id = @id AND group_id = @group_id
RETURNING *;

-- name: DeleteAnnouncement :execrows
DELETE FROM announcements WHERE id = @id AND group_id = @group_id;

-- ---- notifications -------------------------------------------------------------

-- name: ListMemberIDs :many
SELECT user_id FROM class_group_members WHERE group_id = @group_id;

-- name: GetGroup :one
SELECT * FROM class_groups WHERE id = @id;

-- name: GetChange :one
SELECT * FROM routine_changes WHERE id = @id AND group_id = @group_id;

-- ---- members (CR) ----------------------------------------------------------

-- Names only (no emails): what a CR needs to manage the group.
-- name: ListMembers :many
SELECT m.user_id, m.role, m.joined_at, u.display_name
FROM class_group_members m
JOIN users u ON u.id = m.user_id
WHERE m.group_id = @group_id
ORDER BY (m.role = 'cr') DESC, m.joined_at, m.user_id;

-- name: SetRole :execrows
UPDATE class_group_members SET role = @role WHERE group_id = @group_id AND user_id = @user_id;

-- ---- hidden courses ----------------------------------------------------------

-- name: ListHiddenForUser :many
SELECT group_id, course_key FROM class_member_hidden_courses WHERE user_id = @user_id
ORDER BY group_id, course_key;

-- name: ClearHidden :exec
DELETE FROM class_member_hidden_courses WHERE group_id = @group_id AND user_id = @user_id;

-- name: AddHidden :exec
INSERT INTO class_member_hidden_courses (group_id, user_id, course_key)
VALUES (@group_id, @user_id, @course_key) ON CONFLICT DO NOTHING;

-- ---- new semester ------------------------------------------------------------

-- name: DeleteGroupSlots :exec
DELETE FROM routine_slots WHERE group_id = @group_id;

-- name: SetSemester :exec
UPDATE class_groups SET semester = @semester WHERE id = @id;

-- ---- personal classes --------------------------------------------------------

-- name: ListPersonal :many
SELECT * FROM personal_slots WHERE user_id = @user_id ORDER BY weekday, starts_min, title, id;

-- name: CountPersonal :one
SELECT count(*) FROM personal_slots WHERE user_id = @user_id;

-- name: CreatePersonal :one
INSERT INTO personal_slots (user_id, title, details, place, weekday, starts_min, ends_min)
VALUES (@user_id, @title, @details, @place, @weekday, @starts_min, @ends_min)
RETURNING *;

-- name: UpdatePersonal :one
UPDATE personal_slots
SET title = @title, details = @details, place = @place, weekday = @weekday,
    starts_min = @starts_min, ends_min = @ends_min
WHERE id = @id AND user_id = @user_id
RETURNING *;

-- name: DeletePersonal :execrows
DELETE FROM personal_slots WHERE id = @id AND user_id = @user_id;
