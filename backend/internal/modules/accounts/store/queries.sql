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

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = @email;

-- name: GetUser :one
SELECT * FROM users WHERE id = @id;

-- name: InsertUser :one
INSERT INTO users (email, university_id, verified_at)
VALUES (@email, @university_id, @verified_at)
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

-- name: FindSessionByPrevious :one
SELECT * FROM sessions WHERE previous_hash = @previous_hash ORDER BY last_used_at DESC LIMIT 1;

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

-- name: SessionActive :one
SELECT EXISTS (
    SELECT 1 FROM sessions
    WHERE id = @id AND user_id = @user_id AND revoked_at IS NULL AND expires_at > @now
);

-- name: PurgeSessions :execrows
DELETE FROM sessions WHERE expires_at < @before OR revoked_at < @before;
