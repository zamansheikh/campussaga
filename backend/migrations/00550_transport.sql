-- +goose Up
-- University bus routes and timetables (no live tracking). Kept by admins
-- (admin panel) and by transport reps: students an admin names for one
-- university, who edit that university's routes in the app.
--
-- Timetable model: each stop has a fixed minute offset from the start of a
-- trip, one per direction; each trip is just a departure time, a direction
-- and the weekdays it runs. Time at a stop = departure + that stop's offset.
-- Why: university buses run fixed schedules, so offsets hold for every trip;
-- reps edit stops and departures independently (adding a stop never breaks
-- the trips), and one departure is one row.
CREATE TABLE bus_routes (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id uuid        NOT NULL REFERENCES universities (id) ON DELETE CASCADE,
    name          text        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 60),
    color         text        NOT NULL DEFAULT '#0F766E' CHECK (color ~ '^#[0-9A-F]{6}$'),
    notes         text        NOT NULL DEFAULT '' CHECK (char_length(notes) <= 500),
    active        boolean     NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX bus_routes_university_id_idx ON bus_routes (university_id);
CREATE TRIGGER bus_routes_set_updated_at BEFORE UPDATE ON bus_routes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Stops in order from the far end to campus (to-campus order). An offset is
-- NULL when the bus doesn't stop there in that direction.
CREATE TABLE bus_stops (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id        uuid     NOT NULL REFERENCES bus_routes (id) ON DELETE CASCADE,
    position        smallint NOT NULL CHECK (position >= 0),
    name            text     NOT NULL CHECK (char_length(name) BETWEEN 1 AND 60),
    landmark        text     NOT NULL DEFAULT '' CHECK (char_length(landmark) <= 100),
    to_campus_min   smallint CHECK (to_campus_min BETWEEN 0 AND 600),
    from_campus_min smallint CHECK (from_campus_min BETWEEN 0 AND 600),
    UNIQUE (route_id, position)
);

-- One departure: from the first stop (to campus) or from campus (from
-- campus). Weekdays are ISO (1 = Monday ... 7 = Sunday).
CREATE TABLE bus_trips (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id    uuid       NOT NULL REFERENCES bus_routes (id) ON DELETE CASCADE,
    direction   text       NOT NULL CHECK (direction IN ('to_campus', 'from_campus')),
    departs_min smallint   NOT NULL CHECK (departs_min BETWEEN 0 AND 1439),
    weekdays    smallint[] NOT NULL CHECK (
        cardinality(weekdays) BETWEEN 1 AND 7 AND weekdays <@ ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]),
    note        text       NOT NULL DEFAULT '' CHECK (char_length(note) <= 100)
);
CREATE INDEX bus_trips_route_id_idx ON bus_trips (route_id);

-- A student who keeps one university's routes up to date.
CREATE TABLE transport_reps (
    user_id       uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    university_id uuid        NOT NULL REFERENCES universities (id) ON DELETE CASCADE,
    created_at    timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE transport_reps;
DROP TABLE bus_trips;
DROP TABLE bus_stops;
DROP TABLE bus_routes;
