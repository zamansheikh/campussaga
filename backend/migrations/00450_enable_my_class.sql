-- +goose Up
-- R1 "My Class" is live (beta): turn its feature flag on.
UPDATE app_config SET value = jsonb_set(value, '{myClass}', 'true') WHERE key = 'features';

-- +goose Down
UPDATE app_config SET value = jsonb_set(value, '{myClass}', 'false') WHERE key = 'features';
