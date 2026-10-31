-- +goose Up
-- In-app feedback: bug reports, ideas, with replies from the team (docs/FEEDBACK.md).
CREATE TABLE feedback (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid        REFERENCES users (id) ON DELETE SET NULL,
    university_id   uuid        REFERENCES universities (id) ON DELETE SET NULL,
    kind            text        NOT NULL CHECK (kind IN ('bug', 'idea', 'other')),
    message         text        NOT NULL CHECK (char_length(message) BETWEEN 10 AND 2000),
    status          text        NOT NULL DEFAULT 'new'
                    CHECK (status IN ('new', 'seen', 'planned', 'in_progress', 'done', 'wont_do')),
    app_version     text        NOT NULL DEFAULT '' CHECK (char_length(app_version) <= 20),
    build           int         NOT NULL DEFAULT 0,
    platform        text        NOT NULL DEFAULT '' CHECK (char_length(platform) <= 20),
    device          text        NOT NULL DEFAULT '' CHECK (char_length(device) <= 80),
    os              text        NOT NULL DEFAULT '' CHECK (char_length(os) <= 40),
    locale          text        NOT NULL DEFAULT '' CHECK (char_length(locale) <= 10),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    last_message_at timestamptz NOT NULL DEFAULT now(),
    user_unread     int         NOT NULL DEFAULT 0,
    team_unread     int         NOT NULL DEFAULT 0
);
CREATE INDEX feedback_user_idx ON feedback (user_id, last_message_at DESC);
CREATE INDEX feedback_status_idx ON feedback (status, last_message_at DESC);

CREATE TABLE feedback_images (
    id          uuid PRIMARY KEY, -- the upload's id
    feedback_id uuid     NOT NULL REFERENCES feedback (id) ON DELETE CASCADE,
    position    smallint NOT NULL CHECK (position BETWEEN 0 AND 2),
    full_key    text     NOT NULL,
    thumb_key   text     NOT NULL,
    width       int      NOT NULL,
    height      int      NOT NULL,
    UNIQUE (feedback_id, position)
);

CREATE TABLE feedback_messages (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    feedback_id uuid        NOT NULL REFERENCES feedback (id) ON DELETE CASCADE,
    author_id   uuid        REFERENCES users (id) ON DELETE SET NULL,
    from_team   boolean     NOT NULL,
    body        text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX feedback_messages_idx ON feedback_messages (feedback_id, created_at, id);

-- +goose Down
DROP TABLE feedback_messages;
DROP TABLE feedback_images;
DROP TABLE feedback;
