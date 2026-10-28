-- Superadmin panel. Reads across modules on purpose: the panel sees
-- everything. Changes keep the same database rules the app relies on
-- (a group keeps a CR, verified needs a university, domain guards).

-- ---- dashboard --------------------------------------------------------------

-- name: UserCounts :one
SELECT count(*)::int AS total,
       (count(*) FILTER (WHERE verified_at IS NOT NULL))::int AS verified,
       (count(*) FILTER (WHERE verified_at IS NULL))::int AS not_verified,
       (count(*) FILTER (WHERE role = 'admin'))::int AS admins,
       (count(*) FILTER (WHERE blocked_at IS NOT NULL))::int AS blocked,
       (count(*) FILTER (WHERE created_at > sqlc.arg(since)::timestamptz))::int AS new_since
FROM users;

-- name: OtherCounts :one
SELECT (SELECT count(*) FROM class_groups)::int AS groups,
       (SELECT count(*) FROM class_group_members)::int AS memberships,
       (SELECT count(*) FROM routine_slots)::int AS slots,
       (SELECT count(*) FROM announcements)::int AS announcements,
       (SELECT count(*) FROM device_tokens WHERE platform = 'android')::int AS android,
       (SELECT count(*) FROM device_tokens WHERE platform = 'ios')::int AS ios,
       (SELECT count(*) FROM universities WHERE is_active AND NOT is_demo)::int AS universities_active,
       (SELECT count(*) FROM universities WHERE NOT is_demo)::int AS universities_total;

-- Sign-ups per Bangladesh day from first_day to last_day, zero days included.
-- name: SignupsByDay :many
SELECT to_char(d, 'YYYY-MM-DD')::text AS day, count(u.id)::int AS count
FROM generate_series(sqlc.arg(first_day)::text::date, sqlc.arg(last_day)::text::date, interval '1 day') AS d
LEFT JOIN users u ON (u.created_at AT TIME ZONE 'Asia/Dhaka')::date = d::date
GROUP BY d
ORDER BY d;

-- name: TopUniversities :many
SELECT un.id, un.name, count(u.id)::int AS users
FROM universities un
JOIN users u ON u.university_id = un.id
WHERE NOT un.is_demo
GROUP BY un.id
ORDER BY users DESC, un.name
LIMIT 10;

-- ---- users --------------------------------------------------------------------

-- name: ListUsers :many
SELECT u.id, u.email, u.display_name, u.department, u.batch, u.role, u.verified_at,
       u.university_email, u.university_id, un.slug AS university_slug, un.name AS university_name,
       u.blocked_at, u.created_at,
       -- 'epoch' = never (sqlc can't type a nullable subquery column).
       coalesce((SELECT max(s.last_used_at) FROM sessions s WHERE s.user_id = u.id), 'epoch'::timestamptz)::timestamptz AS last_active_at,
       (SELECT count(*) FROM class_group_members m WHERE m.user_id = u.id)::int AS groups,
       u.photo_key, u.google_photo_url
FROM users u
LEFT JOIN universities un ON un.id = u.university_id
WHERE (@q::text = '' OR u.email ILIKE @q_like OR u.display_name ILIKE @q_like OR u.university_email ILIKE @q_like)
  AND (sqlc.narg(university_id)::uuid IS NULL OR u.university_id = sqlc.narg(university_id))
  AND (@status::text = ''
       OR (@status = 'verified' AND u.verified_at IS NOT NULL)
       OR (@status = 'notVerified' AND u.verified_at IS NULL)
       OR (@status = 'blocked' AND u.blocked_at IS NOT NULL)
       OR (@status = 'admin' AND u.role = 'admin'))
ORDER BY u.created_at DESC, u.id
LIMIT @lim OFFSET @off;

-- name: CountUsers :one
SELECT count(*)::int
FROM users u
WHERE (@q::text = '' OR u.email ILIKE @q_like OR u.display_name ILIKE @q_like OR u.university_email ILIKE @q_like)
  AND (sqlc.narg(university_id)::uuid IS NULL OR u.university_id = sqlc.narg(university_id))
  AND (@status::text = ''
       OR (@status = 'verified' AND u.verified_at IS NOT NULL)
       OR (@status = 'notVerified' AND u.verified_at IS NULL)
       OR (@status = 'blocked' AND u.blocked_at IS NOT NULL)
       OR (@status = 'admin' AND u.role = 'admin'));

-- name: GetUser :one
SELECT u.id, u.email, u.display_name, u.department, u.batch, u.role, u.verified_at,
       u.university_email, u.university_id, un.slug AS university_slug, un.name AS university_name,
       u.blocked_at, u.created_at,
       -- 'epoch' = never (sqlc can't type a nullable subquery column).
       coalesce((SELECT max(s.last_used_at) FROM sessions s WHERE s.user_id = u.id), 'epoch'::timestamptz)::timestamptz AS last_active_at,
       (SELECT count(*) FROM class_group_members m WHERE m.user_id = u.id)::int AS groups,
       u.photo_key, u.google_photo_url
FROM users u
LEFT JOIN universities un ON un.id = u.university_id
WHERE u.id = @id;

-- name: UserMemberships :many
SELECT g.id, g.department, g.batch, g.section, m.role
FROM class_group_members m
JOIN class_groups g ON g.id = m.group_id
WHERE m.user_id = @user_id
ORDER BY m.joined_at;

-- name: UserDevices :many
SELECT platform, created_at FROM device_tokens WHERE user_id = @user_id ORDER BY created_at DESC;

-- name: ActiveSessions :one
SELECT count(*)::int FROM sessions
WHERE user_id = @user_id AND revoked_at IS NULL AND expires_at > @now;

-- name: LockUser :one
SELECT id, role, university_id, verified_at, blocked_at FROM users WHERE id = @id FOR UPDATE;

-- name: SetUserRole :exec
UPDATE users SET role = @role WHERE id = @id;

-- name: SetUserName :exec
UPDATE users SET display_name = NULLIF(@display_name::text, '') WHERE id = @id;

-- Moving a student to another university: the old university email no
-- longer proves anything (same as the app's "change university").
-- name: MoveUserUniversity :exec
UPDATE users SET university_id = sqlc.narg(university_id), university_email = NULL, verified_at = NULL
WHERE id = @id;

-- name: VerifyUserByHand :exec
UPDATE users SET verified_at = @now WHERE id = @id AND university_id IS NOT NULL;

-- name: UnverifyUser :exec
UPDATE users SET verified_at = NULL, university_email = NULL WHERE id = @id;

-- name: SetUserBlocked :exec
UPDATE users SET blocked_at = sqlc.narg(blocked_at) WHERE id = @id;

-- name: RevokeUserSessions :exec
UPDATE sessions SET revoked_at = @now WHERE user_id = @user_id AND revoked_at IS NULL;

-- name: DeleteUserDevices :exec
DELETE FROM device_tokens WHERE user_id = @user_id;

-- name: UserPhotoKey :one
SELECT photo_key FROM users WHERE id = @id;

-- name: DeleteUser :execrows
DELETE FROM users WHERE id = @id;

-- ---- universities ---------------------------------------------------------------

-- name: ListUniversities :many
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.kind, u.website, u.is_active,
       coalesce((SELECT array_agg(d.domain ORDER BY d.domain) FROM university_domains d WHERE d.university_id = u.id), '{}')::text[] AS domains,
       (SELECT count(*) FROM users x WHERE x.university_id = u.id)::int AS users,
       (SELECT count(*) FROM class_groups g WHERE g.university_id = u.id)::int AS groups
FROM universities u
WHERE (@q::text = '' OR u.name ILIKE @q_like OR u.slug ILIKE @q_like OR u.name_bn ILIKE @q_like
       OR EXISTS (SELECT 1 FROM university_domains d WHERE d.university_id = u.id AND d.domain ILIKE @q_like))
  AND (sqlc.narg(active)::bool IS NULL OR u.is_active = sqlc.narg(active))
ORDER BY u.name;

-- name: GetUniversity :one
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.kind, u.website, u.is_active,
       coalesce((SELECT array_agg(d.domain ORDER BY d.domain) FROM university_domains d WHERE d.university_id = u.id), '{}')::text[] AS domains,
       (SELECT count(*) FROM users x WHERE x.university_id = u.id)::int AS users,
       (SELECT count(*) FROM class_groups g WHERE g.university_id = u.id)::int AS groups
FROM universities u
WHERE u.id = @id;

-- name: InsertUniversity :one
INSERT INTO universities (slug, name, name_bn, city, kind, website)
VALUES (@slug, @name, sqlc.narg(name_bn), sqlc.narg(city), sqlc.narg(kind), sqlc.narg(website))
RETURNING id;

-- Fields left NULL are kept; an empty string clears an optional one.
-- name: UpdateUniversity :execrows
UPDATE universities SET
    name      = coalesce(sqlc.narg(name), name),
    name_bn   = CASE WHEN sqlc.narg(name_bn)::text IS NULL THEN name_bn ELSE NULLIF(sqlc.narg(name_bn), '') END,
    city      = CASE WHEN sqlc.narg(city)::text IS NULL THEN city ELSE NULLIF(sqlc.narg(city), '') END,
    kind      = CASE WHEN sqlc.narg(kind)::text IS NULL THEN kind ELSE NULLIF(sqlc.narg(kind), '') END,
    website   = CASE WHEN sqlc.narg(website)::text IS NULL THEN website ELSE NULLIF(sqlc.narg(website), '') END,
    is_active = coalesce(sqlc.narg(is_active), is_active)
WHERE id = @id;

-- name: DeleteUniversityDomains :exec
DELETE FROM university_domains WHERE university_id = @university_id;

-- name: InsertUniversityDomain :exec
INSERT INTO university_domains (domain, university_id) VALUES (@domain, @university_id);

-- ---- class groups -----------------------------------------------------------------

-- name: ListGroups :many
SELECT g.id, g.department, g.batch, g.section, g.semester, g.join_code, g.created_at, g.keep_when_empty,
       un.id AS university_id, un.slug AS university_slug, un.name AS university_name,
       (SELECT count(*) FROM class_group_members m WHERE m.group_id = g.id)::int AS members,
       (SELECT count(*) FROM routine_slots s WHERE s.group_id = g.id)::int AS slots
FROM class_groups g
JOIN universities un ON un.id = g.university_id
WHERE (@q::text = '' OR g.department ILIKE @q_like OR g.batch ILIKE @q_like OR g.section ILIKE @q_like
       OR g.join_code = upper(@q))
  AND (sqlc.narg(university_id)::uuid IS NULL OR g.university_id = sqlc.narg(university_id))
ORDER BY g.created_at DESC, g.id
LIMIT @lim OFFSET @off;

-- name: CountGroups :one
SELECT count(*)::int
FROM class_groups g
WHERE (@q::text = '' OR g.department ILIKE @q_like OR g.batch ILIKE @q_like OR g.section ILIKE @q_like
       OR g.join_code = upper(@q))
  AND (sqlc.narg(university_id)::uuid IS NULL OR g.university_id = sqlc.narg(university_id));

-- name: GetGroup :one
SELECT g.id, g.department, g.batch, g.section, g.semester, g.join_code, g.created_at, g.keep_when_empty,
       un.id AS university_id, un.slug AS university_slug, un.name AS university_name,
       (SELECT count(*) FROM class_group_members m WHERE m.group_id = g.id)::int AS members,
       (SELECT count(*) FROM routine_slots s WHERE s.group_id = g.id)::int AS slots
FROM class_groups g
JOIN universities un ON un.id = g.university_id
WHERE g.id = @id;

-- name: GroupCRs :many
SELECT m.group_id, u.id, u.display_name, u.email
FROM class_group_members m
JOIN users u ON u.id = m.user_id
WHERE m.role = 'cr' AND m.group_id = ANY(@group_ids::uuid[])
ORDER BY m.joined_at;

-- name: GroupMembers :many
SELECT u.id, u.display_name, u.email, m.role, (u.verified_at IS NOT NULL)::bool AS verified, m.joined_at
FROM class_group_members m
JOIN users u ON u.id = m.user_id
WHERE m.group_id = @group_id
ORDER BY (m.role = 'cr') DESC, m.joined_at;

-- name: LockGroupMembers :many
SELECT user_id, role FROM class_group_members WHERE group_id = @group_id FOR UPDATE;

-- name: SetMemberRole :exec
UPDATE class_group_members SET role = @role WHERE group_id = @group_id AND user_id = @user_id;

-- name: RemoveMember :execrows
DELETE FROM class_group_members WHERE group_id = @group_id AND user_id = @user_id;

-- name: SetGroupCode :exec
UPDATE class_groups SET join_code = @join_code WHERE id = @id;

-- name: JoinCodeTaken :one
SELECT EXISTS (SELECT 1 FROM class_groups WHERE join_code = @join_code AND id <> @id);

-- name: SetGroupKeep :exec
UPDATE class_groups SET keep_when_empty = @keep WHERE id = @id;

-- name: DeleteGroup :execrows
DELETE FROM class_groups WHERE id = @id;

-- ---- app settings -----------------------------------------------------------------

-- name: ListConfig :many
SELECT key, value, updated_at FROM app_config ORDER BY key;

-- name: UpdateConfig :one
UPDATE app_config SET value = @value WHERE key = @key RETURNING key, value, updated_at;

-- ---- push ------------------------------------------------------------------------

-- name: PushAudience :one
SELECT count(DISTINCT d.user_id)::int AS users, count(*)::int AS devices
FROM device_tokens d
JOIN users u ON u.id = d.user_id
WHERE u.blocked_at IS NULL AND (sqlc.narg(user_id)::uuid IS NULL OR d.user_id = sqlc.narg(user_id));

-- name: PushUsers :many
SELECT DISTINCT d.user_id
FROM device_tokens d
JOIN users u ON u.id = d.user_id
WHERE u.blocked_at IS NULL;

-- ---- audit log ---------------------------------------------------------------------

-- name: InsertAudit :exec
INSERT INTO audit_log (actor_id, action, target_type, target_id, meta)
VALUES (@actor_id, @action, @target_type, @target_id, @meta);

-- name: ListAudit :many
SELECT a.id, a.actor_id, u.email AS actor_email, u.display_name AS actor_name,
       a.action, a.target_type, a.target_id, a.meta, a.created_at
FROM audit_log a
LEFT JOIN users u ON u.id = a.actor_id
ORDER BY a.id DESC
LIMIT @lim OFFSET @off;

-- name: CountAudit :one
SELECT count(*)::int FROM audit_log;

-- ---- Campus Voice staff ----------------------------------------------------------------

-- name: ListStaff :many
SELECT s.user_id, u.email, u.display_name, s.kind, s.university_id,
       un.slug AS university_slug, un.name AS university_name, s.title, s.created_at
FROM staff s
JOIN users u ON u.id = s.user_id
LEFT JOIN universities un ON un.id = s.university_id
ORDER BY s.created_at DESC;

-- name: GetStaff :one
SELECT s.user_id, u.email, u.display_name, s.kind, s.university_id,
       un.slug AS university_slug, un.name AS university_name, s.title, s.created_at
FROM staff s
JOIN users u ON u.id = s.user_id
LEFT JOIN universities un ON un.id = s.university_id
WHERE s.user_id = @user_id;

-- name: UpsertStaff :exec
INSERT INTO staff (user_id, kind, university_id, title)
VALUES (@user_id, @kind, sqlc.narg(university_id), @title)
ON CONFLICT (user_id) DO UPDATE SET kind = EXCLUDED.kind, university_id = EXCLUDED.university_id,
    title = EXCLUDED.title;

-- name: DeleteStaff :execrows
DELETE FROM staff WHERE user_id = @user_id;

-- Counts only: never who wrote anything.
-- name: VoiceCounts :one
SELECT (SELECT count(*) FROM issues WHERE status IN ('open', 'acknowledged', 'in_progress') AND visibility <> 'removed')::int AS open,
       (SELECT count(*) FROM issues WHERE status = 'solved' AND visibility <> 'removed')::int AS solved,
       ((SELECT count(*) FROM issues WHERE visibility = 'held')
        + (SELECT count(*) FROM comments WHERE visibility = 'held'))::int AS held,
       ((SELECT count(*) FROM issues WHERE report_count > 0 AND visibility <> 'removed')
        + (SELECT count(*) FROM comments WHERE report_count > 0 AND visibility <> 'removed'))::int AS reported,
       (SELECT count(*) FROM issues x WHERE x.created_at > @since::timestamptz)::int AS issues_last_7_days;
