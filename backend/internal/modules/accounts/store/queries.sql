-- ---- sign-in codes ------------------------------------------------------

-- Serialises code requests/verifications for one email (also when no row
-- exists yet), for the rest of the transaction.
-- name: LockEmail :exec
SELECT pg_advisory_xact_lock(hashtextextended(@email::text, 0));

-- name: LockSignInCode :one
SELECT * FROM sign_in_codes WHERE email = @email FOR UPDATE;

-- name: UpsertSignInCode :exec
INSERT INTO sign_in_codes (email, university_id, code_hash, attempts, sends, window_start, last_sent_at, expires_at)
VALUES (@email, @university_id, @code_hash, 0, @sends, @window_start, @last_sent_at, @expires_at)
ON CONFLICT (email) DO UPDATE SET
    university_id = EXCLUDED.university_id,
    code_hash     = EXCLUDED.code_hash,
    attempts      = 0,
    sends         = EXCLUDED.sends,
    window_start  = EXCLUDED.window_start,
    last_sent_at  = EXCLUDED.last_sent_at,
    expires_at    = EXCLUDED.expires_at;

-- name: CountFailedAttempt :one
UPDATE sign_in_codes SET attempts = attempts + 1 WHERE email = @email RETURNING attempts;

-- name: DeleteSignInCode :exec
DELETE FROM sign_in_codes WHERE email = @email;

-- Rows are kept past expiry until their resend window ends (rate limit).
-- name: PurgeSignInCodes :execrows
DELETE FROM sign_in_codes WHERE expires_at < @before AND window_start < @before;

-- ---- users --------------------------------------------------------------

-- The account for an email: its sign-in email, or the university email a
-- Gmail student proved (whoever controls that address owns the account).
-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = @email OR university_email = @email
ORDER BY (email = @email) DESC LIMIT 1;

-- name: EmailInUse :one
SELECT EXISTS (
    SELECT 1 FROM users WHERE (email = @email OR university_email = @email) AND id <> @id
);

-- name: SetUniversity :one
UPDATE users SET university_id = @university_id WHERE id = @id AND verified_at IS NULL
RETURNING *;

-- Moving university without a university email there: not verified any more.
-- name: ChangeUniversityUnverified :one
UPDATE users SET university_id = @university_id, university_email = NULL, verified_at = NULL
WHERE id = @id
RETURNING *;

-- name: VerifyUser :one
UPDATE users SET university_email = @university_email, university_id = @university_id,
    verified_at = @verified_at
WHERE id = @id
RETURNING *;

-- name: GetUser :one
SELECT * FROM users WHERE id = @id;

-- name: InsertUser :one
INSERT INTO users (email, university_id, university_email, verified_at)
VALUES (@email, sqlc.narg(university_id), sqlc.narg(university_email), sqlc.narg(verified_at))
RETURNING *;

-- name: UpdateProfile :one
UPDATE users SET
    display_name = sqlc.narg(display_name),
    department   = sqlc.narg(department),
    batch        = sqlc.narg(batch)
WHERE id = @id
RETURNING *;

-- Departments other students at the same university entered, most used
-- first, each shown in its most common spelling. Matching ignores case.
-- name: DepartmentSuggestions :many
SELECT mode() WITHIN GROUP (ORDER BY department)::text AS department
FROM users
WHERE university_id = @university_id
  AND department IS NOT NULL
  AND strpos(lower(department), lower(@q::text)) > 0
GROUP BY lower(department)
ORDER BY count(*) DESC, lower(department)
LIMIT @max_results;

-- name: DeleteUser :execrows
DELETE FROM users WHERE id = @id;

-- ---- sessions -----------------------------------------------------------

-- name: InsertSession :one
INSERT INTO sessions (user_id, refresh_hash, user_agent, created_at, last_used_at, expires_at)
VALUES (@user_id, @refresh_hash, sqlc.narg(user_agent), @now, @now, @expires_at)
RETURNING *;

-- name: LockSessionByRefresh :one
SELECT * FROM sessions WHERE refresh_hash = @refresh_hash FOR UPDATE;

-- The session a refresh token was rotated out of (a retry or a replay).
-- name: LockSessionByPrevious :one
SELECT * FROM sessions WHERE previous_hash = @previous_hash
ORDER BY last_used_at DESC LIMIT 1 FOR UPDATE;

-- Sliding expiry: a session stays alive while the app is used.
-- name: RotateSession :exec
UPDATE sessions SET previous_hash = refresh_hash, refresh_hash = @new_hash,
    last_used_at = @now, expires_at = @expires_at
WHERE id = @id;

-- name: RevokeSession :execrows
UPDATE sessions SET revoked_at = @now::timestamptz
WHERE id = @id AND user_id = @user_id AND revoked_at IS NULL;

-- name: RevokeUserSessions :execrows
UPDATE sessions SET revoked_at = @now::timestamptz WHERE user_id = @user_id AND revoked_at IS NULL;

-- The live session's student: their current university and whether they
-- are verified (read on every request, so changes apply at once). No row =
-- session ended.
-- name: SessionUser :one
SELECT u.university_id, (u.verified_at IS NOT NULL)::bool AS verified, u.role
FROM sessions s JOIN users u ON u.id = s.user_id
WHERE s.id = @id AND s.user_id = @user_id AND s.revoked_at IS NULL AND s.expires_at > @now
  AND u.blocked_at IS NULL;

-- name: PurgeSessions :execrows
DELETE FROM sessions WHERE expires_at < @before OR revoked_at < @before;

-- name: SetGooglePhoto :exec
UPDATE users SET google_photo_url = sqlc.narg(url) WHERE id = @id;

-- name: IsCampusAdmin :one
SELECT EXISTS (
    SELECT 1 FROM campus_admins c JOIN users u ON u.id = c.user_id
    WHERE c.user_id = @user_id AND u.university_id = c.university_id AND u.verified_at IS NOT NULL);

-- name: SetLeaderboardHidden :one
UPDATE users SET leaderboard_hidden = @hidden WHERE id = @id
RETURNING *;
