-- +goose Up
-- Where "Update" sends students when their build is below
-- min_supported_build. Served by GET /config as "storeUrls".
-- iOS stays null until the app is on the App Store.
INSERT INTO app_config (key, value) VALUES
    ('store_urls', '{"android": "https://play.google.com/store/apps/details?id=com.silifton.campussaga", "ios": null}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- +goose Down
DELETE FROM app_config WHERE key = 'store_urls';
