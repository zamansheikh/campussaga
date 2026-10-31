-- Bus routes, stops, trips and transport reps.

-- name: ListRoutes :many
SELECT * FROM bus_routes
WHERE university_id = @university_id AND (active OR @include_inactive::bool)
ORDER BY name, id;

-- Every university's routes (the admin panel's default view).
-- name: ListAllRoutes :many
SELECT * FROM bus_routes ORDER BY university_id, name, id LIMIT 500;

-- name: CountRoutes :one
SELECT count(*) FROM bus_routes WHERE university_id = @university_id;

-- name: GetRoute :one
SELECT * FROM bus_routes WHERE id = @id;

-- name: CreateRoute :one
INSERT INTO bus_routes (university_id, name, color, notes, active, driver_name, driver_phone)
VALUES (@university_id, @name, @color, @notes, @active, @driver_name, @driver_phone)
RETURNING *;

-- name: UpdateRoute :one
UPDATE bus_routes SET name = @name, color = @color, notes = @notes, active = @active,
    driver_name = @driver_name, driver_phone = @driver_phone
WHERE id = @id
RETURNING *;

-- name: TouchRoute :exec
UPDATE bus_routes SET updated_at = now() WHERE id = @id;

-- name: DeleteRoute :execrows
DELETE FROM bus_routes WHERE id = @id;

-- name: StopsForRoutes :many
SELECT * FROM bus_stops WHERE route_id = ANY(@route_ids::uuid[]) ORDER BY route_id, position;

-- name: TripsForRoutes :many
SELECT * FROM bus_trips WHERE route_id = ANY(@route_ids::uuid[]) ORDER BY route_id, direction, departs_min, id;

-- name: StopsOfRoute :many
SELECT * FROM bus_stops WHERE route_id = @route_id ORDER BY position;

-- name: DeleteStops :exec
DELETE FROM bus_stops WHERE route_id = @route_id;

-- name: InsertStop :exec
INSERT INTO bus_stops (route_id, position, name, landmark, to_campus_min, from_campus_min, lat, lng)
VALUES (@route_id, @position, @name, @landmark, @to_campus_min, @from_campus_min, sqlc.narg(lat), sqlc.narg(lng));

-- name: DeleteTrips :exec
DELETE FROM bus_trips WHERE route_id = @route_id;

-- name: InsertTrip :exec
INSERT INTO bus_trips (route_id, direction, departs_min, weekdays, note)
VALUES (@route_id, @direction, @departs_min, @weekdays::smallint[], @note);

-- name: RepUniversity :one
SELECT university_id FROM transport_reps WHERE user_id = @user_id;

-- name: ListReps :many
SELECT r.user_id, r.university_id, r.created_at, u.email, u.display_name,
       un.name AS university_name, un.slug AS university_slug
FROM transport_reps r
JOIN users u ON u.id = r.user_id
JOIN universities un ON un.id = r.university_id
WHERE sqlc.narg(university_id)::uuid IS NULL OR r.university_id = sqlc.narg(university_id)
ORDER BY un.name, u.email;

-- name: UpsertRep :exec
INSERT INTO transport_reps (user_id, university_id) VALUES (@user_id, @university_id)
ON CONFLICT (user_id) DO UPDATE SET university_id = EXCLUDED.university_id;

-- name: DeleteRep :execrows
DELETE FROM transport_reps WHERE user_id = @user_id;

-- name: UserExists :one
SELECT EXISTS (SELECT 1 FROM users WHERE id = @id);

-- name: UniversityExists :one
SELECT EXISTS (SELECT 1 FROM universities WHERE id = @id);

-- name: InsertAudit :exec
INSERT INTO audit_log (actor_id, action, target_type, target_id, meta)
VALUES (@actor_id, @action, @target_type, @target_id, @meta);

-- name: SetRoutePath :exec
UPDATE bus_routes SET path = sqlc.narg(path), path_key = @path_key WHERE id = @id;

-- ---- live buses (docs/BUS_LIVE.md) -------------------------------------------

-- name: InsertLiveSession :one
INSERT INTO bus_live_sessions (route_id, user_id, direction, service_date, departs, started_at, last_at,
    last_lat, last_lng, last_accuracy, last_progress, last_off, pings)
VALUES (@route_id, @user_id, @direction, @service_date, @departs, @now, @now,
    @lat, @lng, @accuracy, sqlc.narg(progress), sqlc.narg(off), 1)
RETURNING *;

-- name: GetLiveSessionForUpdate :one
SELECT * FROM bus_live_sessions WHERE id = @id FOR UPDATE;

-- name: OpenSessionOfUser :one
SELECT * FROM bus_live_sessions WHERE user_id = @user_id AND ended_at IS NULL FOR UPDATE;

-- name: CountSessionsSince :one
SELECT count(*) FROM bus_live_sessions WHERE user_id = @user_id AND started_at >= @since;

-- name: EndLiveSession :one
UPDATE bus_live_sessions SET ended_at = @now, end_reason = @reason
WHERE id = @id AND ended_at IS NULL
RETURNING *;

-- name: UpdateLiveSession :exec
UPDATE bus_live_sessions SET last_at = @last_at, last_lat = @lat, last_lng = @lng, last_accuracy = @accuracy,
    last_progress = sqlc.narg(progress), last_off = sqlc.narg(off), speed = sqlc.narg(speed),
    pings = pings + @added::int
WHERE id = @id;

-- name: InsertLivePing :exec
INSERT INTO bus_live_pings (session_id, at, lat, lng, accuracy, speed, heading, progress, off)
VALUES (@session_id, @at, @lat, @lng, @accuracy, sqlc.narg(speed), sqlc.narg(heading), sqlc.narg(progress), sqlc.narg(off));

-- Pings of a session within max_off metres of the line since a time.
-- name: CountPingsOnLine :one
SELECT count(*) FROM bus_live_pings
WHERE session_id = @session_id AND at > @since AND off IS NOT NULL AND off <= @max_off::real;

-- Open sessions heard from since a time, of one route (or of every route: null).
-- name: FreshSessions :many
SELECT * FROM bus_live_sessions
WHERE ended_at IS NULL AND last_at >= @since AND (sqlc.narg(route_id)::uuid IS NULL OR route_id = sqlc.narg(route_id))
ORDER BY started_at, id;

-- name: FreshSessionsOfUniversity :many
SELECT s.* FROM bus_live_sessions s
JOIN bus_routes r ON r.id = s.route_id
WHERE s.ended_at IS NULL AND s.last_at >= @since AND r.active AND r.university_id = @university_id
ORDER BY s.started_at, s.id;

-- name: MyOpenSession :one
SELECT * FROM bus_live_sessions WHERE user_id = @user_id AND route_id = @route_id AND ended_at IS NULL;

-- name: UpsertLiveView :exec
INSERT INTO bus_live_views (route_id, direction, service_date, departs, user_id, first_at)
VALUES (@route_id, @direction, @service_date, @departs, @user_id, @now)
ON CONFLICT DO NOTHING;

-- Distinct students other than the sharer who looked at the run while the session was open.
-- name: CountViewers :one
SELECT count(*) FROM bus_live_views
WHERE route_id = @route_id AND direction = @direction AND service_date = @service_date AND departs = @departs
  AND user_id <> @sharer AND first_at >= @from_at AND first_at <= @to_at;

-- name: AddShareStats :one
INSERT INTO bus_share_stats (user_id, trips, helped) VALUES (@user_id, 1, @helped::int)
ON CONFLICT (user_id) DO UPDATE SET trips = bus_share_stats.trips + 1,
    helped = bus_share_stats.helped + EXCLUDED.helped, updated_at = now()
RETURNING trips, helped;

-- name: GetShareStats :one
SELECT trips, helped FROM bus_share_stats WHERE user_id = @user_id;

-- Stops a run has already been recorded passing.
-- name: RunStopIDs :many
SELECT stop_id FROM bus_run_stops
WHERE route_id = @route_id AND direction = @direction AND service_date = @service_date AND departs = @departs;

-- name: InsertRunStop :exec
INSERT INTO bus_run_stops (route_id, direction, service_date, departs, stop_id, passed_at, scheduled_at, riders)
VALUES (@route_id, @direction, @service_date, @departs, @stop_id, @passed_at, sqlc.narg(scheduled_at), @riders)
ON CONFLICT DO NOTHING;

-- name: ListAlerts :many
SELECT * FROM bus_alerts WHERE user_id = @user_id ORDER BY created_at, route_id;

-- name: UpsertAlert :one
INSERT INTO bus_alerts (user_id, route_id, direction, stop_id, lead_min)
VALUES (@user_id, @route_id, @direction, @stop_id, @lead_min)
ON CONFLICT (user_id, route_id, direction) DO UPDATE SET stop_id = EXCLUDED.stop_id, lead_min = EXCLUDED.lead_min
RETURNING *;

-- name: DeleteAlert :exec
DELETE FROM bus_alerts WHERE user_id = @user_id AND route_id = @route_id AND direction = @direction;

-- Alerts on a route and direction not yet sent for the run, whose owner is not sharing it.
-- name: PendingAlerts :many
SELECT a.* FROM bus_alerts a
WHERE a.route_id = @route_id AND a.direction = @direction
  AND NOT EXISTS (SELECT 1 FROM bus_alerts_sent t WHERE t.user_id = a.user_id AND t.route_id = a.route_id
        AND t.direction = a.direction AND t.service_date = @service_date AND t.departs = @departs)
  AND NOT EXISTS (SELECT 1 FROM bus_live_sessions s WHERE s.user_id = a.user_id AND s.ended_at IS NULL
        AND s.route_id = a.route_id AND s.direction = a.direction AND s.service_date = @service_date AND s.departs = @departs);

-- One row when this call recorded the push, none when it was already sent.
-- name: MarkAlertSent :execrows
INSERT INTO bus_alerts_sent (user_id, route_id, direction, service_date, departs, sent_at)
VALUES (@user_id, @route_id, @direction, @service_date, @departs, @now)
ON CONFLICT DO NOTHING;

-- name: UpsertFeedback :exec
INSERT INTO bus_trip_feedback (route_id, user_id, direction, service_date, departs, status, crowded)
VALUES (@route_id, @user_id, @direction, @service_date, @departs, @status, @crowded)
ON CONFLICT (route_id, user_id, direction, service_date, departs)
DO UPDATE SET status = EXCLUDED.status, crowded = EXCLUDED.crowded, created_at = now();

-- name: FeedbackTotals :many
SELECT direction, departs, count(*)::int AS votes,
    (count(*) FILTER (WHERE status = 'on_time'))::int AS on_time,
    (count(*) FILTER (WHERE status = 'late'))::int AS late,
    (count(*) FILTER (WHERE status = 'no_show'))::int AS no_show,
    (count(*) FILTER (WHERE crowded))::int AS crowded
FROM bus_trip_feedback
WHERE route_id = @route_id AND service_date >= @since
GROUP BY direction, departs;

-- One row per measured run: its median delay in minutes, and how many of its
-- stops had a scheduled time (0: the delay is not known).
-- name: RunDelays :many
SELECT direction, departs, service_date, (count(scheduled_at))::int AS timed,
    COALESCE(percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (passed_at - scheduled_at)) / 60.0)
        FILTER (WHERE scheduled_at IS NOT NULL), 0)::float8 AS delay_min
FROM bus_run_stops
WHERE route_id = @route_id AND service_date >= @since AND departs >= 0
GROUP BY direction, departs, service_date;

-- Housekeeping (sweep.go).
-- name: StaleSessions :many
SELECT * FROM bus_live_sessions WHERE ended_at IS NULL AND last_at < @before FOR UPDATE SKIP LOCKED;

-- name: PurgeLiveSessions :execrows
DELETE FROM bus_live_sessions WHERE ended_at IS NOT NULL AND ended_at < @before;

-- name: PurgeLiveViews :execrows
DELETE FROM bus_live_views WHERE first_at < @before;

-- name: PurgeAlertsSent :execrows
DELETE FROM bus_alerts_sent WHERE sent_at < @before;

-- name: PurgeRunStops :execrows
DELETE FROM bus_run_stops WHERE passed_at < @before;

-- name: PurgeFeedback :execrows
DELETE FROM bus_trip_feedback WHERE created_at < @before;
