# Live buses

Students on a university bus share where it is; everyone else on that route
sees the bus move, when it will reach their stop, and gets a push when it is
close. After a trip, riders say in one tap how it went. What riders share
also teaches the app how each trip really runs (the start of "learning"):
the server records when a live bus passes each stop.

Built by the people on the bus, for the people waiting for it. No driver
app, no hardware.

Feature flag: `features.busLive` (app_config). Migration 00690 sets it on.

## 1. Words

- **Run**: one bus trip on one day: `(route, direction, serviceDate, departs)`.
  `serviceDate` is the Bangladesh date (Asia/Dhaka) the trip departs on.
  `departs` is the timetable departure in minutes after midnight, or `-1`
  for a bus not on the timetable. Trip ids are not used: reps replace the
  whole trip list when they edit it, so ids change; a departure time does
  not.
- **Sharer**: a student sharing their location from a run (a *session*).
- **Progress**: metres along the route line in the direction of travel.
  The route line is `Route.path` (encoded polyline, stops in to-campus
  order), or straight lines between the placed stops when there is no path.
  For `from_campus`, progress is `length - toCampusProgress`.

## 2. Privacy

- Location is sent only while a student shares, which they start by hand
  from a screen that says what is sent and who sees it. A notification
  stays up while it runs, with a Stop button.
- Other students never see who shares. The live view has counts and the
  run's combined position only: no user ids, names or single tracks.
- Raw points (`bus_live_pings`) and sessions are deleted 24 hours after
  they end. What stays: stop passage times per run (no user), each
  student's own share count, and trip feedback (one vote per student per
  run, never shown with a name; deleted after 180 days).
- Visitors from other universities never see another campus's buses.

## 3. Server

### 3.1 Tables (migration `00690_bus_live.sql`)

```
bus_live_sessions
  id uuid pk, route_id uuid → bus_routes on delete cascade,
  user_id uuid → users on delete cascade,
  direction text (to_campus|from_campus), service_date date,
  departs smallint (-1 = not on the timetable),
  started_at, last_at timestamptz, ended_at timestamptz null,
  end_reason text null (stopped|arrived|expired|replaced|off_route),
  last_lat, last_lng double null, last_accuracy real null,
  last_progress real null   -- metres, direction of travel
  last_off real null        -- metres from the route line
  speed real null           -- m/s, smoothed
  pings int default 0
  index (route_id, ended_at, last_at); unique active per user
  (partial unique index on user_id where ended_at is null)

bus_live_pings            -- raw, deleted after 24 h
  session_id → sessions on delete cascade, at, lat, lng, accuracy,
  speed, heading, progress, off

bus_run_stops             -- learning: when a live bus passed a stop
  route_id, direction, service_date, departs, stop_id uuid (no FK: stops
  are replaced on edit), passed_at, scheduled_at null, riders smallint
  pk (route_id, direction, service_date, departs, stop_id)
  kept 180 days

bus_live_views            -- who looked at a run (for "you helped N")
  route_id, direction, service_date, departs, user_id, first_at
  pk (route_id, direction, service_date, departs, user_id); 24 h

bus_share_stats           -- per student: trips shared, people helped
  user_id pk → users cascade, trips int, helped int, updated_at

bus_alerts                -- "tell me when the bus is N min from my stop"
  user_id → users cascade, route_id → bus_routes cascade,
  direction, stop_id uuid, lead_min smallint (5|10|15), created_at
  pk (user_id, route_id, direction)

bus_alerts_sent           -- one push per alert per run; 48 h
  user_id, route_id, direction, service_date, departs, sent_at
  pk (user_id, route_id, direction, service_date, departs)

bus_trip_feedback
  route_id → bus_routes cascade, user_id → users cascade,
  direction, service_date, departs smallint,
  status text (on_time|late|no_show), crowded bool, created_at
  pk (route_id, user_id, direction, service_date, departs); 180 days
```

### 3.2 Geometry

- Project each point onto the route line (equirectangular metres around
  the point; fine at city scale). Result: `progress` (direction of travel)
  and `off` (metres to the line). Cache the decoded line per route
  `(id, updated_at)`.
- **On route**: `off <= max(150, 1.5 × accuracy)`. A sharer off the route
  still counts (a detour is information); see 3.4.
- Stop progress: each placed stop projected the same way.
- Routes with fewer than 2 placed stops and no path have no line: sharing
  still works (the bus shows on the map), but no progress, ETAs, passages
  or alerts.

### 3.3 Sharing

`POST /transport/routes/{id}/live/share` (student of the route's university)
```
{ "direction": "to_campus", "departs": "07:30" | null,
  "lat": 23.8, "lng": 90.4, "accuracy": 12 }
→ 201 { "sessionId": "…", "live": <Live> }
```
- `departs` must be a trip of the route in that direction running on
  today's weekday, with now in `[departs − 30 min, departs + span + 90 min]`
  (`span` = the largest stop offset that way, 0 if none) → else
  `TRIP_NOT_RUNNING` (409). `null` = a bus not on the timetable.
- Within 600 m of the line when there is one → else `NOT_ON_ROUTE` (409).
- Ends the student's other open session (`replaced`). At most 8 sessions
  per student per day → `SHARE_LIMIT` (429).
- Inactive route → `ROUTE_NOT_FOUND`.

`POST /transport/live/{session}/pings` (owner only, else 404
`SESSION_NOT_FOUND`)
```
{ "points": [ { "at": RFC3339, "lat", "lng", "accuracy", "speed"?, "heading"? } ] }
→ 200 { "ended": false, "reason": null, "riders": 3 }
```
- 1–30 points, oldest first. Drop points older than 10 min or more than
  30 s in the future, closer than 5 s to the previous kept point, with
  accuracy > 200 m, or implying more than 120 km/h from the previous kept
  point. Keep the rest (pings table) and update the session's `last_*`.
- Session already ended → `{ended: true, reason}` (200, so the phone
  stops cleanly).
- The server ends the session (and says so) when:
  - `arrived`: progress within 150 m of the end of the line in this
    direction (the last stop to campus, the far end from campus);
  - `off_route`: off the line by more than 1 km for 10 minutes;
  - `expired`: older than 3 hours.
- After the update, recompute the run (3.4), record stop passages (3.6) and
  check alerts (3.7).
- Rate limit: 400 requests per user per hour.

`POST /transport/live/{session}/stop` → `{ "helped": 12, "trips": 5 }`
- `helped`: distinct students (not the sharer) who viewed this run while
  the session was open. `trips`: the student's total trips shared.
- Ending a session (any reason) with ≥ 3 pings and ≥ 2 minutes adds 1 to
  `bus_share_stats.trips` and `helped` to its `helped`.

### 3.4 The run (computed on read, from sessions)

Fresh sharers: open sessions of the run with `last_at` in the last 2
minutes. When on-route sharers disagree, sort by progress, split at gaps
over 1500 m and keep the largest group (tie: the group with the most
pings). The run:

- `riders`: size of that group (off-route sharers join it when their
  nearest-line point is within 1500 m of the group's median).
- `position`: the point on the line at the group's median progress;
  `onRoute: false` and the median raw point when most fresh sharers are
  off the route.
- `progress`, `speed` (median of sharers' smoothed speeds, m/s).
- `updatedAt`: newest `last_at`.
- `delayMin`: when `departs` is known and the timetable has offsets: now −
  (departure + scheduled minute at the current progress), rounded; the
  scheduled minute is interpolated between the neighbouring timed stops.
  Positive = late. Null when unknown.
- `etas`: for each placed stop ahead (progress > run progress + 50 m):
  `now + (offset(stop) − scheduledMinute(position))` when both are known,
  else `remaining metres / speed` with speed clamped to 3–15 m/s (default
  5 m/s when not moving or unknown). Never before now.
- `passed`: stop ids behind the bus.
- `nextStopId`: the first stop ahead.

`GET /transport/routes/{id}/live`
```
→ { "runs": [ {
      "direction": "to_campus", "departs": "07:30" | null,
      "riders": 3, "position": {"lat","lng"}, "onRoute": true,
      "progress": 5230.5, "length": 14200, "speed": 6.1,
      "delayMin": 4 | null, "nextStopId": "…" | null,
      "passed": ["…"], "etas": [ {"stopId": "…", "at": RFC3339} ],
      "updatedAt": RFC3339, "mine": false } ],
    "mySession": { "id", "direction", "departs" } | null }
```
Runs with no fresh sharer are left out. `mine`: the caller shares on this
run. Records the caller as a viewer of each run returned (`bus_live_views`).

`GET /transport/live` → `{ "routes": [ {"routeId", "runs": 1, "riders": 3} ] }`
for the caller's university, routes with a live run only (route list
badges).

### 3.5 Trip feedback

`POST /transport/routes/{id}/feedback`
```
{ "direction", "departs": "07:30", "date": "2026-11-01",
  "status": "on_time"|"late"|"no_show", "crowded": false }
→ 200 <TripInsight>
```
- `date` is today or yesterday (Dhaka); `departs` is a trip that way; on
  today, the departure has passed. One vote per student per run (a second
  vote replaces the first). Errors `TRIP_NOT_FOUND` (404),
  `FEEDBACK_TOO_EARLY` (409), `INVALID_FEEDBACK` (400).

`GET /transport/routes/{id}/insights` → `{ "trips": [TripInsight] }`, the
route's trips with any data from the last 30 days:
```
TripInsight { "direction", "departs": "07:30",
  "votes": 9, "onTime": 6, "late": 2, "noShow": 1, "crowded": 4,
  "delayMin": 6 | null,   -- median delay at stops over measured runs
  "runs": 4 }             -- runs measured live (bus_run_stops)
```
`delayMin` needs ≥ 3 measured runs; per run, its delay is the median of
`passed_at − scheduled_at` over its stops with a schedule.

### 3.6 Stop passages (learning)

When a run's progress passes a stop's progress (by 30 m) for the first
time that day, insert `bus_run_stops` with `scheduled_at` (departure +
offset, when known) and the rider count. Only on-route runs.

### 3.7 "Bus near" pushes

`GET /transport/alerts` → `{ "alerts": [ {"routeId","stopId","direction","leadMin"} ] }`
`PUT /transport/routes/{id}/alert` `{ "stopId", "direction", "leadMin": 5|10|15 }`
→ the alert (one per student per route and direction; replaces).
`DELETE /transport/routes/{id}/alert?direction=to_campus` → 204.

After each ping batch: for alerts on the run's route and direction whose
stop is ahead with ETA ≤ `leadMin` (and ≥ 1 min), push once per alert per
run (`bus_alerts_sent`), not to the sharers of that run:

- EN: "Bus coming: {route}" / "About {n} min from {stop} · {riders} sharing live"
- BN: "বাস আসছে: {route}" / "{stop} থেকে প্রায় {n} মিনিট দূরে · {riders} জন লাইভ শেয়ার করছে"

Data: `{type: "bus_near", routeId, stopId}`.

### 3.8 Housekeeping

Every 5 minutes: end open sessions with no ping for 10 minutes
(`expired`, with the stats of 3.3); delete pings and sessions ended over
24 h ago, views older than 24 h, alerts sent older than 48 h, run stops and
feedback older than 180 days.

## 4. App

- **Route page**: a live card at the top.
  - A run is live: the bus's place ("Near Mirpur 10"), "3 sharing live",
    "4 min late", ETA at my stop ("At Mirpur 10 in ~6 min"), and Open map.
  - Nothing live during a trip window (10 min before departure until 30 min
    after its last stop): "On the 7:30 bus? Share where it is so others
    can see it" with "I'm on this bus".
  - Sharing: "You're sharing the 7:30 bus · 2 others too" with Stop.
  - Alert toggle on the my-stop card: "Tell me when it's 10 min away".
- **Share sheet**: the trip (preselected: the one running now), what is
  shared and who sees it (Play's prominent disclosure), Start.
- **While sharing**: an Android foreground service (geolocator's
  foreground notification: "Sharing the bus's location", ongoing), points
  every ~10 s or 20 m, sent in batches every 15 s, held and retried while
  offline (at most 30 per request). Stops on Stop, `ended` from the
  server, the app being closed, or 3 hours.
- **After sharing**: "Thanks! 12 students saw your bus" and the one-tap
  feedback sheet.
- **Live map**: the bus marker (route colour, riders count) gliding
  between updates, "Live · 3 sharing · 10 s ago", ETAs on the stop strip;
  polled every 10 s while open.
- **Departures**: each trip's insight ("Usually on time", "Often ~8 min
  late", "Often crowded", "Sometimes doesn't come") once there are ≥ 3
  votes or ≥ 3 measured runs.
- **Feedback card**: on the route page for the latest trip past my stop in
  the last 3 hours (once per trip; dismissable): On time · Late · Didn't
  come, plus "It was crowded".
- **Routes list**: a "Live" pill on routes with a live run.
- **Push** `bus_near` opens the route page.

Android needs `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION`;
no background location permission (the service starts while the app is
open). Play Console: foreground service declaration (location, "live bus
sharing started by the user"), data safety: precise location, collected,
optional, app functionality.

## 5. Later (Step 2 and 3)

- Suggest timetable changes to reps from `bus_run_stops` ("the 7:30 bus
  reaches Mirpur 10 at 7:52 on most days, the timetable says 7:45").
- Suggest the route line from riders' tracks when many go off the line in
  the same place.
- "Suggest an edit" for stops; "the bus didn't come" alerts for the others
  waiting.
