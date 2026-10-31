-- +goose Up
-- Live buses (docs/BUS_LIVE.md): students share where their bus is, others
-- see it move, get ETAs and "bus near" pushes, and rate the trip afterwards.
-- A run is one trip on one day: (route, direction, service_date, departs);
-- departs is minutes after midnight, -1 for a bus not on the timetable.
CREATE TABLE bus_live_sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id      uuid NOT NULL REFERENCES bus_routes (id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  direction     text NOT NULL CHECK (direction IN ('to_campus', 'from_campus')),
  service_date  date NOT NULL,
  departs       smallint NOT NULL CHECK (departs BETWEEN -1 AND 1439),
  started_at    timestamptz NOT NULL,
  last_at       timestamptz NOT NULL,
  ended_at      timestamptz,
  end_reason    text CHECK (end_reason IN ('stopped', 'arrived', 'expired', 'replaced', 'off_route')),
  last_lat      double precision,
  last_lng      double precision,
  last_accuracy real,
  last_progress real,
  last_off      real,
  speed         real,
  pings         int NOT NULL DEFAULT 0
);
CREATE INDEX bus_live_sessions_route_idx ON bus_live_sessions (route_id, ended_at, last_at);
CREATE INDEX bus_live_sessions_user_idx ON bus_live_sessions (user_id, started_at);
CREATE UNIQUE INDEX bus_live_sessions_one_open ON bus_live_sessions (user_id) WHERE ended_at IS NULL;

-- Raw points; deleted with their session, 24 hours after it ends.
CREATE TABLE bus_live_pings (
  session_id uuid NOT NULL REFERENCES bus_live_sessions (id) ON DELETE CASCADE,
  at         timestamptz NOT NULL,
  lat        double precision NOT NULL,
  lng        double precision NOT NULL,
  accuracy   real,
  speed      real,
  heading    real,
  progress   real,
  off        real
);
CREATE INDEX bus_live_pings_session_idx ON bus_live_pings (session_id, at);

-- Learning: when a live bus passed a stop. No user, no stop foreign key
-- (stops are replaced when a rep edits them). Kept 180 days.
CREATE TABLE bus_run_stops (
  route_id     uuid NOT NULL,
  direction    text NOT NULL,
  service_date date NOT NULL,
  departs      smallint NOT NULL,
  stop_id      uuid NOT NULL,
  passed_at    timestamptz NOT NULL,
  scheduled_at timestamptz,
  riders       smallint NOT NULL,
  PRIMARY KEY (route_id, direction, service_date, departs, stop_id)
);
CREATE INDEX bus_run_stops_passed_idx ON bus_run_stops (passed_at);

-- Who looked at a run, for "you helped N students". 24 hours.
CREATE TABLE bus_live_views (
  route_id     uuid NOT NULL,
  direction    text NOT NULL,
  service_date date NOT NULL,
  departs      smallint NOT NULL,
  user_id      uuid NOT NULL,
  first_at     timestamptz NOT NULL,
  PRIMARY KEY (route_id, direction, service_date, departs, user_id)
);
CREATE INDEX bus_live_views_first_idx ON bus_live_views (first_at);

CREATE TABLE bus_share_stats (
  user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  trips      int NOT NULL DEFAULT 0,
  helped     int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- "Tell me when the bus is N minutes from my stop."
CREATE TABLE bus_alerts (
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  route_id   uuid NOT NULL REFERENCES bus_routes (id) ON DELETE CASCADE,
  direction  text NOT NULL CHECK (direction IN ('to_campus', 'from_campus')),
  stop_id    uuid NOT NULL,
  lead_min   smallint NOT NULL CHECK (lead_min IN (5, 10, 15)),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, route_id, direction)
);
CREATE INDEX bus_alerts_route_idx ON bus_alerts (route_id, direction);

-- One push per alert per run. 48 hours.
CREATE TABLE bus_alerts_sent (
  user_id      uuid NOT NULL,
  route_id     uuid NOT NULL,
  direction    text NOT NULL,
  service_date date NOT NULL,
  departs      smallint NOT NULL,
  sent_at      timestamptz NOT NULL,
  PRIMARY KEY (user_id, route_id, direction, service_date, departs)
);
CREATE INDEX bus_alerts_sent_at_idx ON bus_alerts_sent (sent_at);

-- One vote per student per run (a second replaces the first). 180 days.
CREATE TABLE bus_trip_feedback (
  route_id     uuid NOT NULL REFERENCES bus_routes (id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  direction    text NOT NULL CHECK (direction IN ('to_campus', 'from_campus')),
  service_date date NOT NULL,
  departs      smallint NOT NULL CHECK (departs BETWEEN 0 AND 1439),
  status       text NOT NULL CHECK (status IN ('on_time', 'late', 'no_show')),
  crowded      boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (route_id, user_id, direction, service_date, departs)
);
CREATE INDEX bus_trip_feedback_created_idx ON bus_trip_feedback (created_at);

UPDATE app_config SET value = jsonb_set(value, '{busLive}', 'true') WHERE key = 'features';

-- +goose Down
UPDATE app_config SET value = value - 'busLive' WHERE key = 'features';
DROP TABLE bus_trip_feedback;
DROP TABLE bus_alerts_sent;
DROP TABLE bus_alerts;
DROP TABLE bus_share_stats;
DROP TABLE bus_live_views;
DROP TABLE bus_run_stops;
DROP TABLE bus_live_pings;
DROP TABLE bus_live_sessions;
