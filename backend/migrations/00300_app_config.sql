-- +goose Up
-- Public settings the app reads at start: minimum supported build, feature flags.
CREATE TABLE app_config (
    key        text PRIMARY KEY CHECK (key ~ '^[a-z0-9_.]+$'),
    value      jsonb       NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER app_config_set_updated_at BEFORE UPDATE ON app_config
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO app_config (key, value) VALUES
    ('min_supported_build', '1'::jsonb),
    ('features', '{"myClass": false, "campusVoice": false}'::jsonb);

-- +goose Down
DROP TABLE app_config;
