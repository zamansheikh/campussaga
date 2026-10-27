-- +goose Up
-- Shared building blocks used by every later migration.

-- +goose StatementBegin
CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
-- +goose StatementEnd

-- Every moderator/admin action (R2 onwards). Never exposed by any endpoint.
CREATE TABLE audit_log (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_id    uuid,
    action      text        NOT NULL,
    target_type text,
    target_id   text,
    meta        jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_log_created_at_idx ON audit_log (created_at);

-- +goose Down
DROP TABLE audit_log;
DROP FUNCTION set_updated_at();
