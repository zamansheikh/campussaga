-- +goose Up
-- Students whose university gives no email can sign in with Google (Gmail)
-- as "not verified": they pick their university themselves, and can verify
-- later by proving a university email with a code.
--
--   email            the sign-in email (university or personal Google)
--   university_email the proven university email (null = not verified)
--   verified_at      when it was proven
ALTER TABLE users ALTER COLUMN university_id DROP NOT NULL;
ALTER TABLE users ALTER COLUMN verified_at DROP NOT NULL;
ALTER TABLE users ADD COLUMN university_email text UNIQUE
    CHECK (university_email = lower(university_email));
UPDATE users SET university_email = email WHERE verified_at IS NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_verified_has_university
    CHECK (verified_at IS NULL OR (university_id IS NOT NULL AND university_email IS NOT NULL));

-- +goose Down
DELETE FROM users WHERE verified_at IS NULL;
ALTER TABLE users DROP CONSTRAINT users_verified_has_university;
ALTER TABLE users DROP COLUMN university_email;
ALTER TABLE users ALTER COLUMN verified_at SET NOT NULL;
ALTER TABLE users ALTER COLUMN university_id SET NOT NULL;
