-- +goose Up
-- Low-cost rewards (docs/GROWTH.md §9): an optional prize for a section,
-- a small reward for the first students who enter the prize race, and the
-- positions in which students entered it.
ALTER TABLE campaigns
    ADD COLUMN section_prize_en      text NOT NULL DEFAULT '' CHECK (char_length(section_prize_en) <= 120),
    ADD COLUMN section_prize_bn      text NOT NULL DEFAULT '' CHECK (char_length(section_prize_bn) <= 120),
    ADD COLUMN finisher_reward_en    text NOT NULL DEFAULT '' CHECK (char_length(finisher_reward_en) <= 120),
    ADD COLUMN finisher_reward_bn    text NOT NULL DEFAULT '' CHECK (char_length(finisher_reward_bn) <= 120),
    ADD COLUMN finisher_reward_count int  NOT NULL DEFAULT 0 CHECK (finisher_reward_count BETWEEN 0 AND 10000);

-- A student's place in the prize race: given once, the first time they are
-- in it while the campaign is live. Positions never change; the row goes when
-- the participant is disqualified. phone: where to send the reward (01…),
-- deleted 90 days after sending.
CREATE TABLE campaign_finishers (
    campaign_id uuid        NOT NULL REFERENCES campaigns (id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    position    int         NOT NULL CHECK (position >= 1),
    finished_at timestamptz NOT NULL,
    phone       text        CHECK (char_length(phone) <= 20),
    claimed_at  timestamptz,
    sent_at     timestamptz,
    sent_by     uuid        REFERENCES users (id) ON DELETE SET NULL,
    PRIMARY KEY (campaign_id, user_id),
    UNIQUE (campaign_id, position)
);
CREATE INDEX campaign_finishers_user_idx ON campaign_finishers (user_id);

-- +goose Down
DROP TABLE campaign_finishers;
ALTER TABLE campaigns
    DROP COLUMN finisher_reward_count,
    DROP COLUMN finisher_reward_bn,
    DROP COLUMN finisher_reward_en,
    DROP COLUMN section_prize_bn,
    DROP COLUMN section_prize_en;
