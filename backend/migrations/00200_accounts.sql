-- +goose Up
CREATE TYPE user_role AS ENUM ('student', 'authority', 'moderator', 'admin');

-- A user exists only after entering a correct email code, so every row is a
-- verified student (or a staff role set by an admin).
CREATE TABLE users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         text        NOT NULL UNIQUE CHECK (email = lower(email) AND position('@' IN email) > 1),
    university_id uuid        NOT NULL REFERENCES universities (id),
    display_name  text        CHECK (char_length(display_name) BETWEEN 1 AND 60),
    department    text        CHECK (char_length(department) <= 80),
    batch         text        CHECK (char_length(batch) <= 20),
    role          user_role   NOT NULL DEFAULT 'student',
    verified_at   timestamptz NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX users_university_id_idx ON users (university_id);
CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- One pending sign-in code per email. Only an HMAC of the code is stored.
CREATE TABLE sign_in_codes (
    email         text PRIMARY KEY CHECK (email = lower(email)),
    university_id uuid        NOT NULL REFERENCES universities (id) ON DELETE CASCADE,
    code_hash     bytea       NOT NULL,
    attempts      int         NOT NULL DEFAULT 0,
    -- Sends in the current hour window (resend limit).
    sends         int         NOT NULL DEFAULT 1,
    window_start  timestamptz NOT NULL,
    last_sent_at  timestamptz NOT NULL,
    expires_at    timestamptz NOT NULL
);
CREATE INDEX sign_in_codes_expires_at_idx ON sign_in_codes (expires_at);

-- One row per signed-in device. The refresh token is stored as a SHA-256
-- hash and rotated on every use; previous_hash detects a stolen, reused token.
CREATE TABLE sessions (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    refresh_hash  bytea       NOT NULL UNIQUE,
    previous_hash bytea,
    user_agent    text        CHECK (char_length(user_agent) <= 300),
    created_at    timestamptz NOT NULL DEFAULT now(),
    last_used_at  timestamptz NOT NULL DEFAULT now(),
    expires_at    timestamptz NOT NULL,
    revoked_at    timestamptz
);
CREATE INDEX sessions_user_id_idx ON sessions (user_id);
CREATE INDEX sessions_previous_hash_idx ON sessions (previous_hash) WHERE previous_hash IS NOT NULL;

-- +goose Down
DROP TABLE sessions;
DROP TABLE sign_in_codes;
DROP TABLE users;
DROP TYPE user_role;
