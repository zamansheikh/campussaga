-- +goose Up
-- The road path through a route's placed stops, for the map: an encoded
-- polyline (precision 5) from a road router (OSRM), worked out when the
-- stops change. path_key is the stop coordinates it was made from, so an
-- unchanged route isn't routed again. NULL: draw straight lines.
ALTER TABLE bus_routes
    ADD COLUMN path     text,
    ADD COLUMN path_key text NOT NULL DEFAULT '';

-- +goose Down
ALTER TABLE bus_routes
    DROP COLUMN path_key,
    DROP COLUMN path;
