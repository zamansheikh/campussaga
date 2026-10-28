-- +goose Up
-- The app was renamed to VarsityKotha before its Play Store launch; its
-- Android ID changed from com.silifton.campussaga to com.silifton.varsitykotha.
UPDATE app_config
SET value = jsonb_set(value, '{android}', '"https://play.google.com/store/apps/details?id=com.silifton.varsitykotha"')
WHERE key = 'store_urls';

-- +goose Down
UPDATE app_config
SET value = jsonb_set(value, '{android}', '"https://play.google.com/store/apps/details?id=com.silifton.campussaga"')
WHERE key = 'store_urls';
