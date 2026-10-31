-- +goose Up
-- Sponsors and ads run from the admin panel (docs/SPONSORS.md). No ad
-- networks: the team creates every ad, the app draws it, and sponsors only
-- ever get daily totals.

CREATE TABLE sponsors (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name          text        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 80),
    -- health: hospitals and NGOs, the only sponsors allowed on the Blood page.
    category      text        NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'health')),
    logo_key      text,
    logo_version  text,
    website       text        NOT NULL DEFAULT '' CHECK (char_length(website) <= 300),
    contact_name  text        NOT NULL DEFAULT '' CHECK (char_length(contact_name) <= 80),
    contact_phone text        NOT NULL DEFAULT '' CHECK (char_length(contact_phone) <= 20),
    contact_email text        NOT NULL DEFAULT '' CHECK (char_length(contact_email) <= 120),
    notes         text        NOT NULL DEFAULT '' CHECK (char_length(notes) <= 1000),
    archived_at   timestamptz,
    created_by    uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE promos (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sponsor_id     uuid        NOT NULL REFERENCES sponsors (id) ON DELETE CASCADE,
    kind           text        NOT NULL CHECK (kind IN ('deal', 'card', 'feed', 'line', 'campaign')),
    placement      text        NOT NULL CHECK (placement IN ('deals', 'today', 'campus', 'line:bus',
                                   'line:groups', 'line:cgpa', 'line:blood', 'campaign')),
    campaign_id    uuid        REFERENCES campaigns (id) ON DELETE CASCADE,
    title_en       text        NOT NULL DEFAULT '' CHECK (char_length(title_en) <= 60),
    title_bn       text        NOT NULL DEFAULT '' CHECK (char_length(title_bn) <= 60),
    body_en        text        NOT NULL DEFAULT '' CHECK (char_length(body_en) <= 140),
    body_bn        text        NOT NULL DEFAULT '' CHECK (char_length(body_bn) <= 140),
    cta_en         text        NOT NULL DEFAULT '' CHECK (char_length(cta_en) <= 20),
    cta_bn         text        NOT NULL DEFAULT '' CHECK (char_length(cta_bn) <= 20),
    image_key      text,
    image_version  text,
    link_kind      text        NOT NULL DEFAULT 'none' CHECK (link_kind IN ('none', 'web', 'app')),
    link           text        NOT NULL DEFAULT '' CHECK (char_length(link) <= 500),
    code           text        CHECK (char_length(code) <= 30),
    expires_at     timestamptz,
    terms_en       text        NOT NULL DEFAULT '' CHECK (char_length(terms_en) <= 500),
    terms_bn       text        NOT NULL DEFAULT '' CHECK (char_length(terms_bn) <= 500),
    university_ids uuid[],     -- null: every university
    cities         text[],     -- null: every city
    starts_at      timestamptz,
    ends_at        timestamptz,
    status         text        NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'live', 'paused', 'ended')),
    daily_cap      smallint    NOT NULL DEFAULT 2 CHECK (daily_cap BETWEEN 1 AND 20),
    total_views    int         CHECK (total_views > 0),
    priority       smallint    NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    created_by     uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    CHECK ((kind = 'campaign') = (campaign_id IS NOT NULL)),
    CHECK (starts_at IS NULL OR ends_at IS NULL OR starts_at < ends_at)
);
CREATE INDEX promos_live_idx ON promos (placement) WHERE status = 'live';
CREATE INDEX promos_sponsor_idx ON promos (sponsor_id);
-- One live sponsor per campaign.
CREATE UNIQUE INDEX promos_campaign_live_idx ON promos (campaign_id) WHERE status = 'live';

-- Daily totals for reports (kept for good).
CREATE TABLE promo_days (
    promo_id uuid NOT NULL REFERENCES promos (id) ON DELETE CASCADE,
    day      date NOT NULL,
    views    int  NOT NULL DEFAULT 0,
    viewers  int  NOT NULL DEFAULT 0,
    taps     int  NOT NULL DEFAULT 0,
    copies   int  NOT NULL DEFAULT 0,
    hides    int  NOT NULL DEFAULT 0,
    PRIMARY KEY (promo_id, day)
);

-- Per student and day, only for caps and unique viewers; deleted after 90 days.
CREATE TABLE promo_user_days (
    promo_id uuid     NOT NULL REFERENCES promos (id) ON DELETE CASCADE,
    user_id  uuid     NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day      date     NOT NULL,
    views    smallint NOT NULL DEFAULT 0,
    taps     smallint NOT NULL DEFAULT 0,
    copies   smallint NOT NULL DEFAULT 0,
    PRIMARY KEY (promo_id, user_id, day)
);
CREATE INDEX promo_user_days_day_idx ON promo_user_days (day);

-- "Hide this ad" for 7 days.
CREATE TABLE promo_hides (
    user_id  uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    promo_id uuid        NOT NULL REFERENCES promos (id) ON DELETE CASCADE,
    until    timestamptz NOT NULL,
    PRIMARY KEY (user_id, promo_id)
);

-- +goose Down
DROP TABLE promo_hides;
DROP TABLE promo_user_days;
DROP TABLE promo_days;
DROP TABLE promos;
DROP TABLE sponsors;
