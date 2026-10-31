-- +goose Up
-- Campus social (docs/CAMPUS_SOCIAL.md): post, question and poll kinds next
-- to issues, emoji reactions, replies and likes on comments. Reactions, poll
-- votes and comment likes are anonymous like issue votes: no endpoint
-- returns who.
ALTER TABLE issues ADD COLUMN kind text NOT NULL DEFAULT 'issue'
    CHECK (kind IN ('issue', 'post', 'question', 'poll'));
ALTER TABLE issues ADD COLUMN poll_closes_at timestamptz; -- polls only

ALTER TABLE issues DROP CONSTRAINT issues_title_check;
ALTER TABLE issues DROP CONSTRAINT issues_body_check;
ALTER TABLE issues DROP CONSTRAINT issues_category_check;
ALTER TABLE issues ADD CONSTRAINT issues_text_check CHECK (
    CASE WHEN kind = 'issue'
         THEN char_length(title) BETWEEN 8 AND 120 AND char_length(body) BETWEEN 20 AND 3000
         ELSE title = '' AND char_length(body) <= 3000 END);
ALTER TABLE issues ADD CONSTRAINT issues_category_check CHECK (category IN (
    'academic', 'hostel', 'transport', 'facilities', 'safety', 'administration', 'food', 'it', 'other',
    'general', 'event', 'lost_found', 'buy_sell', 'fun'));
ALTER TABLE issues ADD CONSTRAINT issues_kind_category_check CHECK (
    CASE WHEN kind = 'issue'
         THEN category IN ('academic', 'hostel', 'transport', 'facilities', 'safety', 'administration', 'food', 'it', 'other')
         ELSE category <> 'safety' END);
ALTER TABLE issues ADD CONSTRAINT issues_poll_check CHECK ((kind = 'poll') = (poll_closes_at IS NOT NULL));
CREATE INDEX issues_kind_feed_idx ON issues (university_id, kind, visibility, private, created_at DESC, id DESC);

-- A reaction per person per post; issues use 'me_too' only.
ALTER TABLE issue_votes ADD COLUMN reaction text NOT NULL DEFAULT 'me_too'
    CHECK (reaction IN ('me_too', 'like', 'haha', 'wow', 'sad', 'clap'));

CREATE TABLE poll_options (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id   uuid     NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    position   smallint NOT NULL CHECK (position BETWEEN 0 AND 3),
    label      text     NOT NULL CHECK (char_length(label) BETWEEN 1 AND 80),
    vote_count int      NOT NULL DEFAULT 0,
    UNIQUE (issue_id, position)
);
CREATE TABLE poll_votes ( -- counts only ever leave the server
    issue_id   uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    option_id  uuid        NOT NULL REFERENCES poll_options (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (issue_id, user_id)
);

-- One level of replies; likes on comments.
ALTER TABLE comments ADD COLUMN parent_id uuid REFERENCES comments (id) ON DELETE CASCADE;
ALTER TABLE comments ADD COLUMN like_count int NOT NULL DEFAULT 0;
CREATE INDEX comments_parent_idx ON comments (parent_id) WHERE parent_id IS NOT NULL;
CREATE TABLE comment_likes (
    comment_id uuid        NOT NULL REFERENCES comments (id) ON DELETE CASCADE,
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (comment_id, user_id)
);

-- +goose Down
-- Down drops every post, question and poll (with their comments, photos and
-- reactions), then restores the issue-only constraints.
DROP TABLE comment_likes;
DROP INDEX comments_parent_idx;
ALTER TABLE comments DROP COLUMN like_count;
ALTER TABLE comments DROP COLUMN parent_id;
DROP TABLE poll_votes;
DROP TABLE poll_options;
ALTER TABLE issue_votes DROP COLUMN reaction;

DELETE FROM issues WHERE kind <> 'issue';
DROP INDEX issues_kind_feed_idx;
ALTER TABLE issues DROP CONSTRAINT issues_poll_check;
ALTER TABLE issues DROP CONSTRAINT issues_kind_category_check;
ALTER TABLE issues DROP CONSTRAINT issues_category_check;
ALTER TABLE issues DROP CONSTRAINT issues_text_check;
ALTER TABLE issues ADD CONSTRAINT issues_title_check CHECK (char_length(title) BETWEEN 8 AND 120);
ALTER TABLE issues ADD CONSTRAINT issues_body_check CHECK (char_length(body) BETWEEN 20 AND 3000);
ALTER TABLE issues ADD CONSTRAINT issues_category_check CHECK (category IN ('academic', 'hostel', 'transport',
    'facilities', 'safety', 'administration', 'food', 'it', 'other'));
ALTER TABLE issues DROP COLUMN poll_closes_at;
ALTER TABLE issues DROP COLUMN kind;
