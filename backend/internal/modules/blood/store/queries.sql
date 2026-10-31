-- ---- donors ---------------------------------------------------------------

-- name: GetDonor :one
SELECT * FROM blood_donors WHERE user_id = @user_id;

-- name: UpsertDonor :one
INSERT INTO blood_donors (user_id, blood_group, available, phone, last_donated)
VALUES (@user_id, @blood_group, @available, @phone, @last_donated)
ON CONFLICT (user_id) DO UPDATE
SET blood_group = EXCLUDED.blood_group, available = EXCLUDED.available,
    phone = EXCLUDED.phone, last_donated = EXCLUDED.last_donated, updated_at = now()
RETURNING *;

-- name: DeleteDonor :exec
DELETE FROM blood_donors WHERE user_id = @user_id;

-- name: MarkDonated :one
UPDATE blood_donors
SET last_donated = CASE WHEN last_donated IS NULL OR last_donated < sqlc.arg(date)::date
                        THEN sqlc.arg(date)::date ELSE last_donated END,
    donations = donations + 1, updated_at = now()
WHERE user_id = @user_id
RETURNING *;

-- name: SetDonorPhoneIfEmpty :exec
UPDATE blood_donors SET phone = @phone, updated_at = now()
WHERE user_id = @user_id AND phone = '';

-- Donors to push: same university and group, available, last donation at
-- least 120 days ago, not the requester, told of fewer than @max_daily
-- requests since @since. Longest-rested donors first.
-- name: PickDonorsToNotify :many
SELECT d.user_id
FROM blood_donors d
JOIN users u ON u.id = d.user_id
WHERE u.university_id = @university_id
  AND d.blood_group = @blood_group
  AND d.available
  AND (d.last_donated IS NULL OR d.last_donated <= sqlc.arg(eligible_on)::date)
  AND d.user_id <> @requester_id
  AND NOT EXISTS (SELECT 1 FROM blood_notices n WHERE n.request_id = @request_id AND n.user_id = d.user_id)
  AND (SELECT count(*) FROM blood_notices n WHERE n.user_id = d.user_id AND n.sent_at > @since) < @max_daily::bigint
ORDER BY d.last_donated ASC NULLS FIRST, d.user_id
LIMIT @lim;

-- name: InsertNotices :exec
INSERT INTO blood_notices (request_id, user_id, sent_at)
SELECT @request_id, x, @sent_at FROM unnest(@user_ids::uuid[]) AS x
ON CONFLICT DO NOTHING;

-- ---- requests -------------------------------------------------------------

-- Serialises one user's posting (open and daily counts).
-- name: LockUser :one
SELECT id FROM users WHERE id = @id FOR UPDATE;

-- name: CountOpenRequests :one
SELECT count(*) FROM blood_requests
WHERE requester_id = @requester_id AND status = 'open' AND needed_by >= @not_before;

-- name: CountRecentRequests :one
SELECT count(*) FROM blood_requests WHERE requester_id = @requester_id AND created_at > @since;

-- name: CreateRequest :one
INSERT INTO blood_requests (university_id, requester_id, blood_group, units, hospital, area, needed_by,
                            urgent, contact_name, contact_phone, note, created_at)
VALUES (@university_id, @requester_id, @blood_group, @units, @hospital, @area, @needed_by,
        @urgent, @contact_name, @contact_phone, @note, @created_at)
RETURNING *;

-- name: SetNotified :exec
UPDATE blood_requests SET notified = @notified WHERE id = @id;

-- name: GetRequest :one
SELECT sqlc.embed(r),
       (SELECT count(*) FROM blood_responses x WHERE x.request_id = r.id) AS response_count,
       (SELECT count(*) FROM blood_donors d JOIN users u ON u.id = d.user_id
         WHERE u.university_id = r.university_id AND d.blood_group = r.blood_group) AS matching_donors,
       EXISTS (SELECT 1 FROM blood_responses x WHERE x.request_id = r.id AND x.donor_id = @viewer_id) AS responded
FROM blood_requests r
WHERE r.id = @id;

-- name: GetRequestForUpdate :one
SELECT * FROM blood_requests WHERE id = @id FOR UPDATE;

-- Open view: urgent first, then soonest. Keyset on (urgent, needed_by, id).
-- name: ListOpenRequests :many
SELECT sqlc.embed(r),
       (SELECT count(*) FROM blood_responses x WHERE x.request_id = r.id) AS response_count,
       (SELECT count(*) FROM blood_donors d JOIN users u ON u.id = d.user_id
         WHERE u.university_id = r.university_id AND d.blood_group = r.blood_group) AS matching_donors,
       EXISTS (SELECT 1 FROM blood_responses x WHERE x.request_id = r.id AND x.donor_id = @viewer_id) AS responded
FROM blood_requests r
WHERE r.university_id = @university_id
  AND r.status = 'open'
  AND r.needed_by >= @not_before
  AND (@blood_group::text = '' OR r.blood_group = @blood_group::text)
  AND (NOT @has_cursor::bool
       OR r.urgent < @c_urgent::bool
       OR (r.urgent = @c_urgent::bool AND (r.needed_by > @c_needed::timestamptz
            OR (r.needed_by = @c_needed::timestamptz AND r.id > @c_id::uuid))))
ORDER BY r.urgent DESC, r.needed_by ASC, r.id ASC
LIMIT @lim;

-- Mine: every status, newest first. Keyset on (created_at, id).
-- name: ListMyRequests :many
SELECT sqlc.embed(r),
       (SELECT count(*) FROM blood_responses x WHERE x.request_id = r.id) AS response_count,
       (SELECT count(*) FROM blood_donors d JOIN users u ON u.id = d.user_id
         WHERE u.university_id = r.university_id AND d.blood_group = r.blood_group) AS matching_donors,
       EXISTS (SELECT 1 FROM blood_responses x WHERE x.request_id = r.id AND x.donor_id = @viewer_id) AS responded
FROM blood_requests r
WHERE r.requester_id = @viewer_id
  AND (NOT @has_cursor::bool
       OR r.created_at < @c_created::timestamptz
       OR (r.created_at = @c_created::timestamptz AND r.id < @c_id::uuid))
ORDER BY r.created_at DESC, r.id DESC
LIMIT @lim;

-- name: CloseRequest :exec
UPDATE blood_requests SET status = @status, closed_at = @closed_at WHERE id = @id;

-- ---- responses ------------------------------------------------------------

-- name: InsertResponse :execrows
INSERT INTO blood_responses (request_id, donor_id, phone, created_at)
VALUES (@request_id, @donor_id, @phone, @created_at)
ON CONFLICT DO NOTHING;

-- name: DeleteResponse :exec
DELETE FROM blood_responses WHERE request_id = @request_id AND donor_id = @donor_id;

-- name: CountResponsesSince :one
SELECT count(*) FROM blood_responses WHERE donor_id = @donor_id AND created_at > @since;

-- Responses with the donor's name and current group (requester's view only).
-- name: ListResponses :many
SELECT x.request_id, COALESCE(NULLIF(u.display_name, ''), 'Student')::text AS name,
       COALESCE(d.blood_group, '')::text AS blood_group, x.phone, x.created_at
FROM blood_responses x
JOIN users u ON u.id = x.donor_id
LEFT JOIN blood_donors d ON d.user_id = x.donor_id
WHERE x.request_id = ANY(@request_ids::uuid[])
ORDER BY x.created_at, x.donor_id;

-- name: DisplayName :one
SELECT COALESCE(NULLIF(display_name, ''), 'Student')::text FROM users WHERE id = @id;

-- ---- admin panel ----------------------------------------------------------

-- name: AdminListRequests :many
SELECT sqlc.embed(r), un.name AS university_name, u.display_name AS requester_name, u.email AS requester_email,
       (SELECT count(*) FROM blood_responses x WHERE x.request_id = r.id)::int AS response_count
FROM blood_requests r
JOIN universities un ON un.id = r.university_id
LEFT JOIN users u ON u.id = r.requester_id
WHERE (@status::text = 'all' OR r.status = @status::text)
  AND (sqlc.narg(university_id)::uuid IS NULL OR r.university_id = sqlc.narg(university_id))
  AND (@q::text = '' OR r.hospital ILIKE @q_like OR r.area ILIKE @q_like OR r.contact_name ILIKE @q_like
       OR r.contact_phone ILIKE @q_like OR u.email ILIKE @q_like)
ORDER BY r.created_at DESC, r.id DESC
LIMIT @lim OFFSET @off;

-- name: AdminCountRequests :one
SELECT count(*)::int
FROM blood_requests r
LEFT JOIN users u ON u.id = r.requester_id
WHERE (@status::text = 'all' OR r.status = @status::text)
  AND (sqlc.narg(university_id)::uuid IS NULL OR r.university_id = sqlc.narg(university_id))
  AND (@q::text = '' OR r.hospital ILIKE @q_like OR r.area ILIKE @q_like OR r.contact_name ILIKE @q_like
       OR r.contact_phone ILIKE @q_like OR u.email ILIKE @q_like);

-- name: AdminGetRequest :one
SELECT sqlc.embed(r), un.name AS university_name, u.display_name AS requester_name, u.email AS requester_email,
       (SELECT count(*) FROM blood_responses x WHERE x.request_id = r.id)::int AS response_count
FROM blood_requests r
JOIN universities un ON un.id = r.university_id
LEFT JOIN users u ON u.id = r.requester_id
WHERE r.id = @id;

-- name: InsertAudit :exec
INSERT INTO audit_log (actor_id, action, target_type, target_id, meta)
VALUES (@actor_id, @action, @target_type, @target_id, @meta);
