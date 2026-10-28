-- +goose Up
-- The route's driver, so students can call them (a "Call driver" button).
-- Phone: digits with an optional leading +, stored without spaces.
ALTER TABLE bus_routes
    ADD COLUMN driver_name  text NOT NULL DEFAULT '' CHECK (char_length(driver_name) <= 60),
    ADD COLUMN driver_phone text NOT NULL DEFAULT '' CHECK (driver_phone ~ '^(\+?[0-9]{6,15})?$');

-- +goose Down
ALTER TABLE bus_routes
    DROP COLUMN driver_phone,
    DROP COLUMN driver_name;
