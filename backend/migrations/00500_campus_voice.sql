-- +goose Up
-- Campus Voice (docs/CAMPUS_VOICE.md): campus issues, anonymous by default.
-- Content tables carry no user id for anonymous content: who wrote what is
-- kept in *_authors tables that no endpoint returns, joins into a response,
-- filters by or logs (§2.1).
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE issues (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id     uuid        NOT NULL REFERENCES universities (id),
    category          text        NOT NULL CHECK (category IN ('academic', 'hostel', 'transport',
                          'facilities', 'safety', 'administration', 'food', 'it', 'other')),
    -- Safety issues: private to the author, moderators and the university's authorities.
    private           boolean     NOT NULL,
    title             text        NOT NULL CHECK (char_length(title) BETWEEN 8 AND 120),
    body              text        NOT NULL CHECK (char_length(body) BETWEEN 20 AND 3000),
    location_label    text        NOT NULL DEFAULT '' CHECK (char_length(location_label) <= 80),
    status            text        NOT NULL DEFAULT 'open' CHECK (status IN
                          ('open', 'acknowledged', 'in_progress', 'solved', 'rejected')),
    visibility        text        NOT NULL DEFAULT 'visible' CHECK (visibility IN
                          ('visible', 'held', 'hidden', 'removed')),
    -- Why it is held/hidden: an auto-check rule, 'unverified', 'reports' (auto-hidden) or 'moderator'.
    hold_reason       text        NOT NULL DEFAULT '',
    removed_reason    text        NOT NULL DEFAULT '' CHECK (char_length(removed_reason) <= 300),
    deleted_by_author boolean     NOT NULL DEFAULT false,
    -- Posted with the author's name. named_author_id becomes NULL if that
    -- account is deleted ("Deleted account"); named stays true.
    named             boolean     NOT NULL DEFAULT false,
    named_author_id   uuid        REFERENCES users (id) ON DELETE SET NULL,
    me_too_count      int         NOT NULL DEFAULT 0,
    comment_count     int         NOT NULL DEFAULT 0, -- visible comments
    report_count      int         NOT NULL DEFAULT 0, -- open reports
    status_changed_at timestamptz NOT NULL DEFAULT now(),
    solved_at         timestamptz,
    edited_at         timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    CHECK (private = (category = 'safety')),
    CHECK (named OR named_author_id IS NULL)
);
CREATE INDEX issues_feed_idx ON issues (university_id, visibility, private, created_at DESC, id DESC);
CREATE INDEX issues_status_idx ON issues (university_id, status, status_changed_at DESC);
CREATE INDEX issues_title_trgm ON issues USING gin (title gin_trgm_ops);
CREATE TRIGGER issues_set_updated_at BEFORE UPDATE ON issues
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE issue_authors (
    issue_id uuid PRIMARY KEY REFERENCES issues (id) ON DELETE CASCADE,
    user_id  uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE
);
CREATE INDEX issue_authors_user_idx ON issue_authors (user_id);

CREATE TABLE issue_votes (
    issue_id   uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (issue_id, user_id)
);

-- Who gets pushes about an issue: the author, voters, commenters, followers.
CREATE TABLE issue_follows (
    issue_id   uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (issue_id, user_id)
);

CREATE TABLE status_updates (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id    uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    actor_kind  text        NOT NULL CHECK (actor_kind IN ('authority', 'moderator', 'author', 'system')),
    actor_title text        NOT NULL DEFAULT '', -- an authority's public title, e.g. "Proctor Office"
    from_status text        NOT NULL,
    to_status   text        NOT NULL,
    note        text        NOT NULL DEFAULT '' CHECK (char_length(note) <= 500),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX status_updates_issue_idx ON status_updates (issue_id, created_at);

-- +goose Down
DROP TABLE status_updates;
DROP TABLE issue_follows;
DROP TABLE issue_votes;
DROP TABLE issue_authors;
DROP TABLE issues;
