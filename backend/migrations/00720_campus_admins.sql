-- +goose Up
-- Campus admins and verification by people (docs/CAMPUS_ADMINS.md).

CREATE TABLE campus_admins (
    user_id       uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    university_id uuid        NOT NULL REFERENCES universities (id),
    appointed_by  uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX campus_admins_university_idx ON campus_admins (university_id);

-- How the student was verified, and the code that opens their vouch link.
ALTER TABLE users ADD COLUMN verified_via text
    CHECK (verified_via IN ('email', 'cr', 'vouch', 'campus_admin', 'admin'));
ALTER TABLE users ADD COLUMN vouch_code text UNIQUE
    CHECK (vouch_code ~ '^[a-z0-9]{8}$');
UPDATE users SET verified_via = CASE WHEN university_email IS NOT NULL THEN 'email' ELSE 'admin' END
    WHERE verified_at IS NOT NULL;

-- Every verification, newest first; revoked ones stay.
CREATE TABLE verification_events (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    university_id uuid        REFERENCES universities (id),
    method        text        NOT NULL CHECK (method IN ('email', 'cr', 'vouch', 'campus_admin', 'admin')),
    actor_id      uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    revoked_at    timestamptz,
    revoked_by    uuid        REFERENCES users (id) ON DELETE SET NULL,
    reason        text        NOT NULL DEFAULT '' CHECK (char_length(reason) <= 300)
);
CREATE INDEX verification_events_user_idx ON verification_events (user_id, created_at DESC);
CREATE INDEX verification_events_actor_idx ON verification_events (actor_id, created_at) WHERE actor_id IS NOT NULL;
CREATE INDEX verification_events_university_idx ON verification_events (university_id, created_at DESC);

INSERT INTO verification_events (user_id, university_id, method, created_at)
    SELECT id, university_id, verified_via, verified_at FROM users WHERE verified_at IS NOT NULL;

-- void_at: set when the verification these vouches gave was taken away
-- (they stop counting, but still count for the voucher's quota and block rule).
CREATE TABLE vouches (
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    voucher_id uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    void_at    timestamptz,
    PRIMARY KEY (user_id, voucher_id),
    CHECK (user_id <> voucher_id)
);
CREATE INDEX vouches_voucher_idx ON vouches (voucher_id, created_at);

CREATE TABLE vouch_blocks (
    user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    blocked_by uuid        REFERENCES users (id) ON DELETE SET NULL,
    reason     text        NOT NULL DEFAULT '' CHECK (char_length(reason) <= 300),
    auto       boolean     NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE escalations (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id uuid        NOT NULL REFERENCES universities (id),
    kind          text        NOT NULL CHECK (kind IN ('student', 'section', 'report', 'other')),
    target_id     text,
    note          text        NOT NULL CHECK (char_length(note) <= 500),
    created_by    uuid        REFERENCES users (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    resolved_at   timestamptz,
    resolved_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
    resolution    text        NOT NULL DEFAULT '' CHECK (char_length(resolution) <= 300)
);
CREATE INDEX escalations_open_idx ON escalations (created_at) WHERE resolved_at IS NULL;

CREATE TABLE domain_requests (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    domain          text        NOT NULL,
    email           text        NOT NULL,
    university_id   uuid        REFERENCES universities (id) ON DELETE SET NULL,
    university_name text        NOT NULL DEFAULT '' CHECK (char_length(university_name) <= 120),
    requester_id    uuid        REFERENCES users (id) ON DELETE SET NULL,
    mx_ok           boolean     NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now(),
    status          text        NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'approved', 'rejected')),
    decided_by      uuid        REFERENCES users (id) ON DELETE SET NULL,
    decided_at      timestamptz
);
CREATE INDEX domain_requests_status_idx ON domain_requests (status, created_at DESC);

-- verified_via follows verified_at for every writer (email codes, Google
-- sign-in, the admin's hand switch): an unverified user has none; a newly
-- verified one gets 'email' (has a university email) or 'admin' unless the
-- writer set it; a new university email makes it 'email'.
-- +goose StatementBegin
CREATE FUNCTION users_verified_via_sync() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.verified_at IS NULL THEN
        NEW.verified_via := NULL;
    ELSIF TG_OP = 'INSERT' OR OLD.verified_at IS NULL THEN
        IF NEW.verified_via IS NULL THEN
            NEW.verified_via := CASE WHEN NEW.university_email IS NOT NULL THEN 'email' ELSE 'admin' END;
        END IF;
    ELSIF NEW.university_email IS NOT NULL AND NEW.university_email IS DISTINCT FROM OLD.university_email THEN
        NEW.verified_via := 'email';
    END IF;
    RETURN NEW;
END $$;
-- +goose StatementEnd

-- The history rows of the automatic methods (email, admin); the people-based
-- ones are written by the API with their actor.
-- +goose StatementBegin
CREATE FUNCTION users_verification_history() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.verified_at IS NOT NULL AND NEW.verified_via IN ('email', 'admin') AND (
           TG_OP = 'INSERT' OR OLD.verified_at IS NULL OR OLD.verified_via IS DISTINCT FROM NEW.verified_via
           OR OLD.university_email IS DISTINCT FROM NEW.university_email) THEN
        INSERT INTO verification_events (user_id, university_id, method, created_at)
        VALUES (NEW.id, NEW.university_id, NEW.verified_via, NEW.verified_at);
    END IF;
    IF TG_OP = 'UPDATE' AND OLD.verified_at IS NOT NULL AND NEW.verified_at IS NULL THEN
        UPDATE verification_events SET revoked_at = now() WHERE user_id = NEW.id AND revoked_at IS NULL;
    END IF;
    RETURN NULL;
END $$;
-- +goose StatementEnd

CREATE TRIGGER users_verified_via_sync BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION users_verified_via_sync();
CREATE TRIGGER users_verification_history AFTER INSERT OR UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION users_verification_history();

-- +goose Down
DROP TRIGGER users_verification_history ON users;
DROP TRIGGER users_verified_via_sync ON users;
DROP FUNCTION users_verification_history();
DROP FUNCTION users_verified_via_sync();
DROP TABLE domain_requests;
DROP TABLE escalations;
DROP TABLE vouch_blocks;
DROP TABLE vouches;
DROP TABLE verification_events;
ALTER TABLE users DROP COLUMN vouch_code;
ALTER TABLE users DROP COLUMN verified_via;
DROP TABLE campus_admins;
