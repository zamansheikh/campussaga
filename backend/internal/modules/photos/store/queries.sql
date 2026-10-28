-- Profile photos (users.photo_key).

-- name: PhotoKey :one
SELECT photo_key FROM users WHERE id = @id;

-- name: SetPhotoKey :exec
UPDATE users SET photo_key = sqlc.narg(photo_key) WHERE id = @id;

-- Whether two students share a class group (then they see each other's photo).
-- name: ShareGroup :one
SELECT EXISTS (
    SELECT 1 FROM class_group_members a
    JOIN class_group_members b ON b.group_id = a.group_id
    WHERE a.user_id = @viewer AND b.user_id = @owner
);
