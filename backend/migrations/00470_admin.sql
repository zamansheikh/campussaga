-- +goose Up
-- Superadmin panel (campus.silifton.com/admin).

-- A blocked account can't sign in, and its sessions end at once.
ALTER TABLE users ADD COLUMN blocked_at timestamptz;

-- Admins sign in to the panel with an email code whatever their email
-- domain (Gmail included): such codes belong to no university.
ALTER TABLE sign_in_codes ALTER COLUMN university_id DROP NOT NULL;

-- An admin can verify a student by hand (enrolment proven another way):
-- verified then needs a university, but not a university email.
ALTER TABLE users DROP CONSTRAINT users_verified_has_university;
ALTER TABLE users ADD CONSTRAINT users_verified_has_university
    CHECK (verified_at IS NULL OR university_id IS NOT NULL);

CREATE INDEX users_created_at_idx ON users (created_at);
CREATE INDEX audit_log_actor_id_idx ON audit_log (actor_id);

-- +goose Down
DROP INDEX audit_log_actor_id_idx;
DROP INDEX users_created_at_idx;
UPDATE users SET verified_at = NULL WHERE verified_at IS NOT NULL AND university_email IS NULL;
ALTER TABLE users DROP CONSTRAINT users_verified_has_university;
ALTER TABLE users ADD CONSTRAINT users_verified_has_university
    CHECK (verified_at IS NULL OR (university_id IS NOT NULL AND university_email IS NOT NULL));
DELETE FROM sign_in_codes WHERE university_id IS NULL;
ALTER TABLE sign_in_codes ALTER COLUMN university_id SET NOT NULL;
ALTER TABLE users DROP COLUMN blocked_at;
