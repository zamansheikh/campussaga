import 'dart:math' as math;

import '../classes/class_models.dart' show Clock;

/// Which way a bus trip runs.
enum BusDirection {
  toCampus('to_campus'),
  fromCampus('from_campus');

  const BusDirection(this.wire);
  final String wire;

  static BusDirection parse(String? v) =>
      v == 'from_campus' ? fromCampus : toCampus;
}

/// A stop on a route. Stops run from the far end to campus; the offsets are
/// minutes after a trip starts, per direction (null: no time that way).
/// [lat]/[lng] place it on the map (both null: not placed yet).
class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    this.landmark = '',
    this.toCampusMin,
    this.fromCampusMin,
    this.lat,
    this.lng,
  });

  factory BusStop.fromJson(Map<String, Object?> j) {
    final loc = (j['location'] as Map?)?.cast<String, Object?>();
    return BusStop(
      id: j['id'] as String? ?? '',
      name: j['name']! as String,
      landmark: j['landmark'] as String? ?? '',
      toCampusMin: (j['toCampusMin'] as num?)?.toInt(),
      fromCampusMin: (j['fromCampusMin'] as num?)?.toInt(),
      lat: (loc?['lat'] as num?)?.toDouble(),
      lng: (loc?['lng'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String name;
  final String landmark;
  final int? toCampusMin;
  final int? fromCampusMin;
  final double? lat;
  final double? lng;

  bool get hasLocation => lat != null && lng != null;

  int? offset(BusDirection d) =>
      d == BusDirection.toCampus ? toCampusMin : fromCampusMin;

  /// A copy; pass `() => null` to clear a time or the location.
  BusStop copyWith({
    String? name,
    String? landmark,
    int? Function()? toCampusMin,
    int? Function()? fromCampusMin,
    ({double lat, double lng})? Function()? location,
  }) {
    final loc = location == null
        ? (hasLocation ? (lat: lat!, lng: lng!) : null)
        : location();
    return BusStop(
      id: id,
      name: name ?? this.name,
      landmark: landmark ?? this.landmark,
      toCampusMin: toCampusMin == null ? this.toCampusMin : toCampusMin(),
      fromCampusMin: fromCampusMin == null
          ? this.fromCampusMin
          : fromCampusMin(),
      lat: loc?.lat,
      lng: loc?.lng,
    );
  }

  /// The location as the API sends it: {lat, lng} or null.
  Map<String, Object?>? get locationJson =>
      hasLocation ? {'lat': lat, 'lng': lng} : null;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'landmark': landmark,
    'toCampusMin': toCampusMin,
    'fromCampusMin': fromCampusMin,
    'location': locationJson,
  };
}

/// One departure: from the first stop (to campus) or from campus.
/// [weekdays] are ISO (1 = Monday ... 7 = Sunday).
class BusTrip {
  const BusTrip({
    this.id = '',
    required this.direction,
    required this.departsMin,
    required this.weekdays,
    this.note = '',
  });

  factory BusTrip.fromJson(Map<String, Object?> j) => BusTrip(
    id: j['id'] as String? ?? '',
    direction: BusDirection.parse(j['direction'] as String?),
    departsMin: Clock.parse(j['departs']! as String),
    weekdays: {
      for (final d in (j['weekdays'] as List? ?? const [])) (d as num).toInt(),
    },
    note: j['note'] as String? ?? '',
  );

  final String id;
  final BusDirection direction;
  final int departsMin;
  final Set<int> weekdays;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'direction': direction.wire,
    'departs': Clock.format(departsMin),
    'weekdays': (weekdays.toList()..sort()),
    'note': note,
  };
}

/// A university bus route.
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    this.color = '#0F766E',
    this.notes = '',
    this.active = true,
    this.stops = const [],
    this.trips = const [],
    this.path,
  });

  factory BusRoute.fromJson(Map<String, Object?> j) => BusRoute(
    id: j['id']! as String,
    name: j['name']! as String,
    color: j['color'] as String? ?? '#0F766E',
    notes: j['notes'] as String? ?? '',
    active: j['active'] as bool? ?? true,
    stops: [
      for (final s in (j['stops'] as List? ?? const []))
        BusStop.fromJson((s as Map).cast()),
    ],
    trips: [
      for (final t in (j['trips'] as List? ?? const []))
        BusTrip.fromJson((t as Map).cast()),
    ],
    path: j['path'] as String?,
  );

  final String id;
  final String name;
  final String color;
  final String notes;
  final bool active;
  final List<BusStop> stops;
  final List<BusTrip> trips;

  /// The road path through the placed stops, an encoded polyline
  /// (precision 5; see [decodePolyline]). Null: draw straight lines.
  final String? path;

  /// "Mirpur 10 → Campus" (to-campus order).
  String get span => stops.isEmpty
      ? ''
      : stops.length == 1
      ? stops.first.name
      : '${stops.first.name} → ${stops.last.name}';

  /// The colour as ARGB (for widgets).
  int get argb {
    final hex = color.replaceFirst('#', '');
    return int.tryParse('FF$hex', radix: 16) ?? 0xFF0F766E;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'notes': notes,
    'active': active,
    'stops': [for (final s in stops) s.toJson()],
    'trips': [for (final t in trips) t.toJson()],
    'path': path,
  };
}

/// Points of an encoded polyline (Google's format, as OSRM sends it),
/// as (lat, lng). Stops at the first malformed character.
List<({double lat, double lng})> decodePolyline(String s, {int precision = 5}) {
  final out = <({double lat, double lng})>[];
  var i = 0, lat = 0, lng = 0;
  final factor = _pow10(precision);
  int? next() {
    var result = 0, shift = 0;
    while (true) {
      if (i >= s.length) return null;
      final b = s.codeUnitAt(i++) - 63;
      if (b < 0) return null;
      result |= (b & 0x1f) << shift;
      shift += 5;
      if (b < 0x20) break;
      if (shift > 30) return null;
    }
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (i < s.length) {
    final dLat = next();
    final dLng = next();
    if (dLat == null || dLng == null) break;
    lat += dLat;
    lng += dLng;
    out.add((lat: lat / factor, lng: lng / factor));
  }
  return out;
}

double _pow10(int n) {
  var v = 1.0;
  for (var k = 0; k < n; k++) {
    v *= 10;
  }
  return v;
}

/// Distance in metres between two points (haversine).
double distanceMetres(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// The placed stop of [route] nearest to (lat, lng), with the distance in
/// metres; null when no stop is placed.
({BusStop stop, double metres})? nearestStop(
  BusRoute route,
  double lat,
  double lng,
) {
  ({BusStop stop, double metres})? best;
  for (final s in route.stops) {
    if (!s.hasLocation) continue;
    final d = distanceMetres(lat, lng, s.lat!, s.lng!);
    if (best == null || d < best.metres) best = (stop: s, metres: d);
  }
  return best;
}

/// The routes of the student's university, and whether they may edit them.
class BusRoutes {
  const BusRoutes({this.routes = const [], this.canEdit = false});

  factory BusRoutes.fromJson(Map<String, Object?> j) => BusRoutes(
    routes: [
      for (final r in (j['routes'] as List? ?? const []))
        BusRoute.fromJson((r as Map).cast()),
    ],
    canEdit: j['canEdit'] as bool? ?? false,
  );

  final List<BusRoute> routes;
  final bool canEdit;

  Map<String, Object?> toJson() => {
    'routes': [for (final r in routes) r.toJson()],
    'canEdit': canEdit,
  };
}

/// A bus passing a stop at a moment.
class BusDeparture {
  const BusDeparture({
    required this.route,
    required this.trip,
    required this.stop,
    required this.at,
  });

  final BusRoute route;
  final BusTrip trip;
  final BusStop stop;
  final DateTime at;
}

/// The next departures of [route] from [stop] (by stop id) in [direction],
/// from [now] on, looking up to [days] days ahead (tomorrow's first bus when
/// today's last one is gone). Times are local wall-clock times.
List<BusDeparture> nextDepartures(
  BusRoute route, {
  required String stopId,
  required BusDirection direction,
  required DateTime now,
  int days = 7,
  int limit = 5,
}) {
  final stop = route.stops.where((s) => s.id == stopId).firstOrNull;
  final offset = stop?.offset(direction);
  if (stop == null || offset == null) return const [];
  final trips = route.trips.where((t) => t.direction == direction).toList()
    ..sort((a, b) => a.departsMin.compareTo(b.departsMin));
  final out = <BusDeparture>[];
  final today = DateTime(now.year, now.month, now.day);
  for (var d = 0; d <= days && out.length < limit; d++) {
    final day = DateTime(today.year, today.month, today.day + d);
    for (final t in trips) {
      if (!t.weekdays.contains(day.weekday)) continue;
      final at = day.add(Duration(minutes: t.departsMin + offset));
      if (at.isBefore(now)) continue;
      out.add(BusDeparture(route: route, trip: t, stop: stop, at: at));
      if (out.length >= limit) break;
    }
  }
  return out;
}

/// The next departure of every route from any stop, for route cards: the
/// first stop going to campus, else from campus.
BusDeparture? nextRouteDeparture(BusRoute route, DateTime now) {
  BusDeparture? best;
  for (final dir in BusDirection.values) {
    final first = dir == BusDirection.toCampus
        ? route.stops.where((s) => s.toCampusMin != null).firstOrNull
        : route.stops.where((s) => s.fromCampusMin != null).lastOrNull;
    if (first == null) continue;
    final next = nextDepartures(
      route,
      stopId: first.id,
      direction: dir,
      now: now,
      limit: 1,
    ).firstOrNull;
    if (next != null && (best == null || next.at.isBefore(best.at))) {
      best = next;
    }
  }
  return best;
}

/// Edits a transport rep (or admin) makes. Throws a `Failure`.
abstract interface class TransportRepository {
  Future<BusRoutes> routes();
  Future<BusRoute> createRoute({
    required String name,
    required String color,
    String notes = '',
    bool active = true,
  });
  Future<BusRoute> updateRoute(
    String id, {
    required String name,
    required String color,
    String notes = '',
    bool active = true,
  });
  Future<void> deleteRoute(String id);
  Future<BusRoute> setStops(String id, List<BusStop> stops);
  Future<BusRoute> setTrips(String id, List<BusTrip> trips);
}
