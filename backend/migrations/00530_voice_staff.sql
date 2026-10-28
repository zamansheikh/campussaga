-- +goose Up
-- University officials (authorities) and moderators, set by an admin.
-- users.role stays the access gate; this table holds the scope and title.
CREATE TABLE staff (
    user_id       uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    kind          text        NOT NULL CHECK (kind IN ('authority', 'moderator')),
    university_id uuid        REFERENCES universities (id), -- NULL: moderator of all universities
    title         text        NOT NULL DEFAULT '' CHECK (char_length(title) <= 80),
    created_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (kind = 'moderator' OR (university_id IS NOT NULL AND char_length(title) >= 2))
);

-- Blocks posting, commenting, voting and reporting (reading still works).
CREATE TABLE voice_bans (
    user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    until      timestamptz, -- NULL = permanent
    reason     text        NOT NULL DEFAULT '' CHECK (char_length(reason) <= 300),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE voice_bans;
DROP TABLE staff;
