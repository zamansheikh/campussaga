-- Bus routes, stops, trips and transport reps.

-- name: ListRoutes :many
SELECT * FROM bus_routes
WHERE university_id = @university_id AND (active OR @include_inactive::bool)
ORDER BY name, id;

-- name: CountRoutes :one
SELECT count(*) FROM bus_routes WHERE university_id = @university_id;

-- name: GetRoute :one
SELECT * FROM bus_routes WHERE id = @id;

-- name: CreateRoute :one
INSERT INTO bus_routes (university_id, name, color, notes, active)
VALUES (@university_id, @name, @color, @notes, @active)
RETURNING *;

-- name: UpdateRoute :one
UPDATE bus_routes SET name = @name, color = @color, notes = @notes, active = @active
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

-- name: DeleteStops :exec
DELETE FROM bus_stops WHERE route_id = @route_id;

-- name: InsertStop :exec
INSERT INTO bus_stops (route_id, position, name, landmark, to_campus_min, from_campus_min)
VALUES (@route_id, @position, @name, @landmark, @to_campus_min, @from_campus_min);

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
