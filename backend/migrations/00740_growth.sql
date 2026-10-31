-- +goose Up
-- Growth: invites, badges, student profiles, prize campaigns (docs/GROWTH.md).

ALTER TABLE users
    ADD COLUMN referral_code text UNIQUE CHECK (referral_code ~ '^[a-z0-9]{8}$'),
    ADD COLUMN featured_badge text CHECK (char_length(featured_badge) <= 40),
    ADD COLUMN leaderboard_hidden boolean NOT NULL DEFAULT false;

-- One row per student and day (Asia/Dhaka) they used the app; 30 days kept.
CREATE TABLE user_active_days (
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day     date NOT NULL,
    PRIMARY KEY (user_id, day)
);
CREATE INDEX user_active_days_day_idx ON user_active_days (day);

-- Which accounts a phone's push token has been registered under (a sha256 of
-- the token, so a token that moves from one student to another is still
-- remembered). Used only to flag invites between accounts on one phone.
CREATE TABLE device_token_users (
    token_hash text        NOT NULL CHECK (char_length(token_hash) = 64),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    first_seen timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (token_hash, user_id)
);
CREATE INDEX device_token_users_user_idx ON device_token_users (user_id);

CREATE TABLE referrals (
    referred_id     uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    referrer_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    source          text        NOT NULL CHECK (source IN ('link', 'join')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    qualified_at    timestamptz,
    disqualified_at timestamptz,
    disqualified_by uuid        REFERENCES users (id) ON DELETE SET NULL,
    reason          text        NOT NULL DEFAULT '' CHECK (char_length(reason) <= 300),
    same_device     boolean     NOT NULL DEFAULT false,
    CHECK (referred_id <> referrer_id)
);
CREATE INDEX referrals_referrer_idx ON referrals (referrer_id, created_at DESC);
CREATE INDEX referrals_pending_idx ON referrals (created_at) WHERE qualified_at IS NULL;

CREATE TABLE user_badges (
    user_id   uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    badge     text        NOT NULL,
    tier      smallint    NOT NULL DEFAULT 0 CHECK (tier BETWEEN 0 AND 3),
    private   boolean     NOT NULL DEFAULT false,
    earned_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, badge)
);

CREATE TABLE campaigns (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title_en      text        NOT NULL CHECK (char_length(title_en) BETWEEN 1 AND 120),
    title_bn      text        NOT NULL DEFAULT '' CHECK (char_length(title_bn) <= 120),
    body_en       text        NOT NULL DEFAULT '' CHECK (char_length(body_en) <= 2000),
    body_bn       text        NOT NULL DEFAULT '' CHECK (char_length(body_bn) <= 2000),
    rules_en      text        NOT NULL DEFAULT '' CHECK (char_length(rules_en) <= 8000),
    rules_bn      text        NOT NULL DEFAULT '' CHECK (char_length(rules_bn) <= 8000),
    starts_at     timestamptz NOT NULL,
    ends_at       timestamptz NOT NULL,
    settles_at    timestamptz NOT NULL,
    university_ids uuid[],
    prizes        jsonb       NOT NULL DEFAULT '[]',
    status        text        NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'live', 'ended', 'announced')),
    created_by    uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at AND settles_at >= ends_at)
);
CREATE INDEX campaigns_status_idx ON campaigns (status, ends_at DESC);
CREATE TRIGGER campaigns_set_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE campaign_disqualified (
    campaign_id     uuid        NOT NULL REFERENCES campaigns (id) ON DELETE CASCADE,
    user_id         uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    reason          text        NOT NULL DEFAULT '' CHECK (char_length(reason) <= 300),
    disqualified_by uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (campaign_id, user_id)
);

CREATE TABLE campaign_winners (
    campaign_id  uuid        NOT NULL REFERENCES campaigns (id) ON DELETE CASCADE,
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    rank         int         NOT NULL CHECK (rank >= 1),
    prize_en     text        NOT NULL DEFAULT '',
    prize_bn     text        NOT NULL DEFAULT '',
    announced_at timestamptz NOT NULL DEFAULT now(),
    claimed_at   timestamptz,
    delivered_at timestamptz,
    PRIMARY KEY (campaign_id, user_id)
);

-- Only winners; deleted 90 days after delivery.
CREATE TABLE campaign_claims (
    campaign_id uuid        NOT NULL,
    user_id     uuid        NOT NULL,
    full_name   text        NOT NULL CHECK (char_length(full_name) BETWEEN 1 AND 80),
    phone       text        NOT NULL CHECK (char_length(phone) BETWEEN 1 AND 20),
    address     text        NOT NULL CHECK (char_length(address) BETWEEN 1 AND 300),
    note        text        NOT NULL DEFAULT '' CHECK (char_length(note) <= 300),
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (campaign_id, user_id),
    FOREIGN KEY (campaign_id, user_id) REFERENCES campaign_winners (campaign_id, user_id) ON DELETE CASCADE
);

-- Feedback messages sent in the same instant keep the order they were sent
-- in (ids are random). Fills existing rows.
ALTER TABLE feedback_messages ADD COLUMN seq bigint GENERATED ALWAYS AS IDENTITY;

-- +goose Down
ALTER TABLE feedback_messages DROP COLUMN seq;
DROP TABLE campaign_claims;
DROP TABLE campaign_winners;
DROP TABLE campaign_disqualified;
DROP TABLE campaigns;
DROP TABLE user_badges;
DROP TABLE referrals;
DROP TABLE device_token_users;
DROP TABLE user_active_days;
ALTER TABLE users DROP COLUMN leaderboard_hidden, DROP COLUMN featured_badge, DROP COLUMN referral_code;
