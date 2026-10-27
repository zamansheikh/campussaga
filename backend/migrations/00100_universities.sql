-- +goose Up
CREATE TABLE universities (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug       text        NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    name       text        NOT NULL CHECK (char_length(name) BETWEEN 2 AND 120),
    name_bn    text        CHECK (char_length(name_bn) <= 120),
    city       text        CHECK (char_length(city) <= 60),
    timezone   text        NOT NULL DEFAULT 'Asia/Dhaka',
    -- First day of the week, ISO numbering (1 = Monday ... 6 = Saturday, 7 = Sunday).
    week_start smallint    NOT NULL DEFAULT 6 CHECK (week_start BETWEEN 1 AND 7),
    is_active  boolean     NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER universities_set_updated_at BEFORE UPDATE ON universities
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Student email domains. A domain belongs to exactly one university;
-- subdomains match too (cse.du.ac.bd -> du.ac.bd), longest match wins.
CREATE TABLE university_domains (
    domain        text PRIMARY KEY
                  CHECK (domain = lower(domain) AND domain ~ '^[a-z0-9-]+(\.[a-z0-9-]+)+$'),
    university_id uuid NOT NULL REFERENCES universities (id) ON DELETE CASCADE
);
CREATE INDEX university_domains_university_id_idx ON university_domains (university_id);

-- +goose Down
DROP TABLE university_domains;
DROP TABLE universities;
