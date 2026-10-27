-- name: UpsertDevice :exec
INSERT INTO device_tokens (token, user_id, session_id, platform, language)
VALUES (@token, @user_id, @session_id, @platform, @language)
ON CONFLICT (token) DO UPDATE SET
    user_id = EXCLUDED.user_id, session_id = EXCLUDED.session_id,
    platform = EXCLUDED.platform, language = EXCLUDED.language;

-- A token Firebase says is no longer valid.
-- name: DeleteToken :exec
DELETE FROM device_tokens WHERE token = @token;

-- Only phones still signed in (session not revoked or expired).
-- name: DevicesForUsers :many
SELECT d.token, d.platform, d.language FROM device_tokens d
JOIN sessions s ON s.id = d.session_id
WHERE d.user_id = ANY(@user_ids::uuid[]) AND s.revoked_at IS NULL AND s.expires_at > now();
