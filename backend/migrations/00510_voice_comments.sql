-- +goose Up
-- Comments on issues: students (anonymous handle per issue, or named) and
-- official replies from authorities (always named, with their title).
CREATE TABLE comments (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id          uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    kind              text        NOT NULL DEFAULT 'student' CHECK (kind IN ('student', 'official')),
    handle            text        NOT NULL DEFAULT '', -- '' for official and named
    official_title    text        NOT NULL DEFAULT '',
    named             boolean     NOT NULL DEFAULT false,
    named_author_id   uuid        REFERENCES users (id) ON DELETE SET NULL,
    body              text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
    visibility        text        NOT NULL DEFAULT 'visible' CHECK (visibility IN ('visible', 'held', 'hidden', 'removed')),
    hold_reason       text        NOT NULL DEFAULT '',
    removed_reason    text        NOT NULL DEFAULT '' CHECK (char_length(removed_reason) <= 300),
    deleted_by_author boolean     NOT NULL DEFAULT false,
    report_count      int         NOT NULL DEFAULT 0,
    created_at        timestamptz NOT NULL DEFAULT now(),
    -- Students write up to 1000 characters, official replies up to 2000.
    CHECK (kind = 'official' OR char_length(body) <= 1000),
    CHECK (named OR named_author_id IS NULL)
);
CREATE INDEX comments_issue_idx ON comments (issue_id, created_at, id);

CREATE TABLE comment_authors (
    comment_id uuid PRIMARY KEY REFERENCES comments (id) ON DELETE CASCADE,
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE
);
CREATE INDEX comment_authors_user_idx ON comment_authors (user_id);

-- +goose Down
DROP TABLE comment_authors;
DROP TABLE comments;
