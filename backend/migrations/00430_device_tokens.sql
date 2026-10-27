-- +goose Up
-- Push notification tokens (Firebase Cloud Messaging), one row per app
-- install, tied to the sign-in session that registered it: signing out (or
-- any revoked or expired session) stops pushes to that phone. A token moves
-- to whoever signs in on that phone last. The language picks the text.
CREATE TABLE device_tokens (
    token      text PRIMARY KEY CHECK (char_length(token) BETWEEN 1 AND 4096),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_id uuid        NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
    platform   text        NOT NULL CHECK (platform IN ('android', 'ios')),
    language   text        NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'bn')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX device_tokens_user_id_idx ON device_tokens (user_id);
CREATE TRIGGER device_tokens_set_updated_at BEFORE UPDATE ON device_tokens
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE device_tokens;
