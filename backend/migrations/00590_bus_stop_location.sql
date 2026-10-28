-- +goose Up
-- Where each bus stop is (WGS 84), for the route map. Optional: a stop
-- without a location is left off the map. Both set or both NULL.
ALTER TABLE bus_stops
    ADD COLUMN lat double precision CHECK (lat BETWEEN -90 AND 90),
    ADD COLUMN lng double precision CHECK (lng BETWEEN -180 AND 180),
    ADD CONSTRAINT bus_stops_location_pair CHECK ((lat IS NULL) = (lng IS NULL));

-- +goose Down
ALTER TABLE bus_stops
    DROP CONSTRAINT bus_stops_location_pair,
    DROP COLUMN lng,
    DROP COLUMN lat;
