-- +goose Up
-- Photos (uploaded first, attached to an issue when it is posted) and reports.
CREATE TABLE uploads ( -- not attached yet; deleted after 24 h
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    full_key   text        NOT NULL,
    thumb_key  text        NOT NULL,
    width      int         NOT NULL,
    height     int         NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX uploads_user_idx ON uploads (user_id, created_at);
CREATE INDEX uploads_created_idx ON uploads (created_at);

CREATE TABLE issue_images ( -- attached: no link to a user
    id        uuid PRIMARY KEY, -- the upload's id
    issue_id  uuid     NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    position  smallint NOT NULL CHECK (position BETWEEN 0 AND 3),
    full_key  text     NOT NULL,
    thumb_key text     NOT NULL,
    width     int      NOT NULL,
    height    int      NOT NULL,
    UNIQUE (issue_id, position)
);

CREATE TABLE reports (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    target_type text        NOT NULL CHECK (target_type IN ('issue', 'comment')),
    target_id   uuid        NOT NULL,
    issue_id    uuid        NOT NULL REFERENCES issues (id) ON DELETE CASCADE,
    reason      text        NOT NULL CHECK (reason IN ('spam', 'abuse', 'personal_info', 'false_info', 'inappropriate', 'other')),
    details     text        NOT NULL DEFAULT '' CHECK (char_length(details) <= 300),
    state       text        NOT NULL DEFAULT 'open' CHECK (state IN ('open', 'resolved', 'dismissed')),
    created_at  timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz
);
CREATE INDEX reports_open_idx ON reports (state, created_at) WHERE state = 'open';
CREATE INDEX reports_target_idx ON reports (target_id, state);

CREATE TABLE report_authors (
    report_id uuid PRIMARY KEY REFERENCES reports (id) ON DELETE CASCADE,
    user_id   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    target_id uuid NOT NULL,
    UNIQUE (user_id, target_id) -- one report per person per item
);

-- +goose Down
DROP TABLE report_authors;
DROP TABLE reports;
DROP TABLE issue_images;
DROP TABLE uploads;
