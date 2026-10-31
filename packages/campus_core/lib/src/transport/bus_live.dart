import '../classes/class_models.dart' show Clock;
import 'transport_models.dart';

/// Live buses (docs/BUS_LIVE.md): students on a bus share where it is,
/// everyone on the route sees it, and riders rate trips.

int? _departs(Object? v) => v is String && v.isNotEmpty ? Clock.parse(v) : null;

String? _departsWire(int? m) => m == null ? null : Clock.format(m);

DateTime _at(Object? v) => DateTime.parse(v! as String).toLocal();

/// One bus on its way today, seen through the students sharing from it.
class BusRun {
  const BusRun({
    required this.direction,
    this.departsMin,
    required this.riders,
    required this.lat,
    required this.lng,
    this.onRoute = true,
    this.progress,
    this.length,
    this.speed,
    this.delayMin,
    this.nextStopId,
    this.passed = const {},
    this.etas = const {},
    required this.updatedAt,
    this.mine = false,
  });

  factory BusRun.fromJson(Map<String, Object?> j) {
    final pos = (j['position']! as Map).cast<String, Object?>();
    return BusRun(
      direction: BusDirection.parse(j['direction'] as String?),
      departsMin: _departs(j['departs']),
      riders: (j['riders'] as num?)?.toInt() ?? 1,
      lat: (pos['lat']! as num).toDouble(),
      lng: (pos['lng']! as num).toDouble(),
      onRoute: j['onRoute'] as bool? ?? true,
      progress: (j['progress'] as num?)?.toDouble(),
      length: (j['length'] as num?)?.toDouble(),
      speed: (j['speed'] as num?)?.toDouble(),
      delayMin: (j['delayMin'] as num?)?.toInt(),
      nextStopId: j['nextStopId'] as String?,
      passed: {for (final s in (j['passed'] as List? ?? const [])) s as String},
      etas: {
        for (final e in (j['etas'] as List? ?? const []))
          (e as Map)['stopId']! as String: _at(e['at']),
      },
      updatedAt: _at(j['updatedAt']),
      mine: j['mine'] as bool? ?? false,
    );
  }

  final BusDirection direction;

  /// The timetable departure (minutes after midnight); null: a bus not on
  /// the timetable.
  final int? departsMin;

  /// Students sharing from it right now.
  final int riders;
  final double lat;
  final double lng;

  /// False while the bus is off its usual line (a detour).
  final bool onRoute;

  /// Metres along the route in the direction of travel, and its length.
  final double? progress;
  final double? length;

  /// Metres per second.
  final double? speed;

  /// Minutes behind the timetable (negative: early); null when unknown.
  final int? delayMin;
  final String? nextStopId;

  /// Stops the bus has passed.
  final Set<String> passed;

  /// When it should reach each stop ahead.
  final Map<String, DateTime> etas;
  final DateTime updatedAt;

  /// The caller shares from this bus.
  final bool mine;

  /// Same run (direction and departure).
  String get key => '${direction.wire}|${departsMin ?? -1}';

  /// How far along the route it is, 0..1 (null: unknown).
  double? get fraction {
    final p = progress, l = length;
    if (p == null || l == null || l <= 0) return null;
    return (p / l).clamp(0, 1).toDouble();
  }
}

/// The caller's own sharing, as the server knows it.
class BusShareRef {
  const BusShareRef({
    required this.id,
    required this.direction,
    this.departsMin,
  });

  factory BusShareRef.fromJson(Map<String, Object?> j) => BusShareRef(
    id: j['id']! as String,
    direction: BusDirection.parse(j['direction'] as String?),
    departsMin: _departs(j['departs']),
  );

  final String id;
  final BusDirection direction;
  final int? departsMin;
}

/// A route's live buses.
class BusLive {
  const BusLive({this.runs = const [], this.mySession});

  factory BusLive.fromJson(Map<String, Object?> j) => BusLive(
    runs: [
      for (final r in (j['runs'] as List? ?? const []))
        BusRun.fromJson((r as Map).cast()),
    ],
    mySession: j['mySession'] is Map
        ? BusShareRef.fromJson((j['mySession']! as Map).cast())
        : null,
  );

  static const none = BusLive();

  final List<BusRun> runs;
  final BusShareRef? mySession;

  bool get isEmpty => runs.isEmpty;
}

/// A point the phone measured while sharing.
class BusPoint {
  const BusPoint({
    required this.at,
    required this.lat,
    required this.lng,
    this.accuracy = 0,
    this.speed,
    this.heading,
  });

  final DateTime at;
  final double lat;
  final double lng;

  /// Metres.
  final double accuracy;

  /// Metres per second, degrees.
  final double? speed;
  final double? heading;

  Map<String, Object?> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'lat': lat,
    'lng': lng,
    'accuracy': accuracy,
    'speed': ?(speed == null || speed! < 0 ? null : speed),
    'heading': ?(heading == null || heading! < 0 ? null : heading),
  };
}

/// Why a sharing session ended.
enum BusShareEnd {
  stopped('stopped'),
  arrived('arrived'),
  expired('expired'),
  replaced('replaced'),
  offRoute('off_route');

  const BusShareEnd(this.wire);
  final String wire;

  static BusShareEnd parse(String? v) =>
      values.where((e) => e.wire == v).firstOrNull ?? stopped;
}

/// The server's answer to a batch of points.
class BusPingResult {
  const BusPingResult({this.ended = false, this.reason, this.riders = 1});

  factory BusPingResult.fromJson(Map<String, Object?> j) => BusPingResult(
    ended: j['ended'] as bool? ?? false,
    reason: j['reason'] is String
        ? BusShareEnd.parse(j['reason']! as String)
        : null,
    riders: (j['riders'] as num?)?.toInt() ?? 1,
  );

  final bool ended;
  final BusShareEnd? reason;
  final int riders;
}

/// After sharing: students who saw the bus, and trips shared in all.
class BusShareThanks {
  const BusShareThanks({this.helped = 0, this.trips = 0});

  factory BusShareThanks.fromJson(Map<String, Object?> j) => BusShareThanks(
    helped: (j['helped'] as num?)?.toInt() ?? 0,
    trips: (j['trips'] as num?)?.toInt() ?? 0,
  );

  final int helped;
  final int trips;
}

/// How a trip went, from a rider.
enum BusTripStatus {
  onTime('on_time'),
  late('late'),
  noShow('no_show');

  const BusTripStatus(this.wire);
  final String wire;
}

/// What riders have said about a trip, and how it ran when shared live,
/// over the last 30 days.
class BusTripInsight {
  const BusTripInsight({
    required this.direction,
    required this.departsMin,
    this.votes = 0,
    this.onTime = 0,
    this.late = 0,
    this.noShow = 0,
    this.crowded = 0,
    this.delayMin,
    this.runs = 0,
  });

  factory BusTripInsight.fromJson(Map<String, Object?> j) => BusTripInsight(
    direction: BusDirection.parse(j['direction'] as String?),
    departsMin: _departs(j['departs']) ?? 0,
    votes: (j['votes'] as num?)?.toInt() ?? 0,
    onTime: (j['onTime'] as num?)?.toInt() ?? 0,
    late: (j['late'] as num?)?.toInt() ?? 0,
    noShow: (j['noShow'] as num?)?.toInt() ?? 0,
    crowded: (j['crowded'] as num?)?.toInt() ?? 0,
    delayMin: (j['delayMin'] as num?)?.toInt(),
    runs: (j['runs'] as num?)?.toInt() ?? 0,
  );

  final BusDirection direction;
  final int departsMin;
  final int votes;
  final int onTime;
  final int late;
  final int noShow;
  final int crowded;

  /// Typical minutes late at stops, measured live (≥ 3 runs).
  final int? delayMin;
  final int runs;

  /// Enough to say anything.
  static const minVotes = 3;
  static const minRuns = 3;

  /// What to tell students, most useful first.
  List<BusTripNote> get notes {
    final out = <BusTripNote>[];
    final measured = runs >= minRuns ? delayMin : null;
    final voted = votes >= minVotes;
    if (measured != null) {
      out.add(
        measured <= 3
            ? const BusTripNote(BusTripNoteKind.usuallyOnTime)
            : BusTripNote(BusTripNoteKind.oftenLate, minutes: measured),
      );
    } else if (voted && late * 2 >= votes) {
      out.add(const BusTripNote(BusTripNoteKind.oftenLate));
    } else if (voted && onTime * 10 >= votes * 6) {
      out.add(const BusTripNote(BusTripNoteKind.usuallyOnTime));
    }
    if (voted && noShow * 5 >= votes) {
      out.add(const BusTripNote(BusTripNoteKind.sometimesNoShow));
    }
    if (voted && crowded * 2 >= votes) {
      out.add(const BusTripNote(BusTripNoteKind.oftenCrowded));
    }
    return out;
  }
}

enum BusTripNoteKind { usuallyOnTime, oftenLate, oftenCrowded, sometimesNoShow }

/// "Often ~8 min late" ([minutes] when measured).
class BusTripNote {
  const BusTripNote(this.kind, {this.minutes});

  final BusTripNoteKind kind;
  final int? minutes;

  /// Worth a warning colour.
  bool get bad => kind != BusTripNoteKind.usuallyOnTime;

  @override
  bool operator ==(Object other) =>
      other is BusTripNote && other.kind == kind && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(kind, minutes);
}

/// "Tell me when the bus is [leadMin] min from my stop."
class BusAlert {
  const BusAlert({
    required this.routeId,
    required this.stopId,
    required this.direction,
    required this.leadMin,
  });

  factory BusAlert.fromJson(Map<String, Object?> j) => BusAlert(
    routeId: j['routeId']! as String,
    stopId: j['stopId']! as String,
    direction: BusDirection.parse(j['direction'] as String?),
    leadMin: (j['leadMin'] as num?)?.toInt() ?? 10,
  );

  final String routeId;
  final String stopId;
  final BusDirection direction;
  final int leadMin;

  static const leads = [5, 10, 15];
}

/// Live buses over the API. Throws a `Failure`.
abstract interface class BusLiveRepository {
  Future<BusLive> live(String routeId);

  /// Route id → students sharing now, for routes with a live bus.
  Future<Map<String, int>> liveRoutes();

  Future<({String sessionId, BusLive live})> startSharing(
    String routeId, {
    required BusDirection direction,
    int? departsMin,
    required double lat,
    required double lng,
    double accuracy = 0,
  });

  Future<BusPingResult> ping(String sessionId, List<BusPoint> points);
  Future<BusShareThanks> stopSharing(String sessionId);

  Future<BusTripInsight> sendFeedback(
    String routeId, {
    required BusDirection direction,
    required int departsMin,
    required DateTime date,
    required BusTripStatus status,
    bool crowded = false,
  });

  Future<List<BusTripInsight>> insights(String routeId);
  Future<List<BusAlert>> alerts();
  Future<BusAlert> setAlert(
    String routeId, {
    required String stopId,
    required BusDirection direction,
    required int leadMin,
  });
  Future<void> removeAlert(String routeId, BusDirection direction);
}

/// The wire form of a departure ("07:30", or null).
String? busDepartsWire(int? minutes) => _departsWire(minutes);

/// Minutes from a trip's start to its last timed stop that way (0: none).
int busTripSpan(BusRoute route, BusDirection direction) {
  var span = 0;
  for (final s in route.stops) {
    final o = s.offset(direction);
    if (o != null && o > span) span = o;
  }
  return span;
}

/// A timetabled trip on a given day.
typedef BusTripDay = ({BusTrip trip, DateTime day, DateTime departs});

/// Trips running around [now] (from [before] ahead of departure until
/// [after] past its last stop), nearest departure first. Yesterday's late
/// trips count past midnight.
List<BusTripDay> runningTrips(
  BusRoute route,
  DateTime now, {
  BusDirection? direction,
  Duration before = const Duration(minutes: 10),
  Duration after = const Duration(minutes: 30),
}) {
  final out = <BusTripDay>[];
  final today = DateTime(now.year, now.month, now.day);
  for (final back in const [0, 1]) {
    final day = DateTime(today.year, today.month, today.day - back);
    for (final t in route.trips) {
      if (direction != null && t.direction != direction) continue;
      if (!t.weekdays.contains(day.weekday)) continue;
      final dep = day.add(Duration(minutes: t.departsMin));
      final end = dep.add(
        Duration(minutes: busTripSpan(route, t.direction)) + after,
      );
      if (now.isBefore(dep.subtract(before)) || now.isAfter(end)) continue;
      out.add((trip: t, day: day, departs: dep));
    }
  }
  int gap(BusTripDay d) => d.departs.difference(now).inSeconds.abs();
  return out..sort((a, b) => gap(a).compareTo(gap(b)));
}

/// Trips a student on the bus may share now (the server's window: half an
/// hour before departure until 90 minutes past the last stop).
List<BusTripDay> shareableTrips(BusRoute route, DateTime now) => runningTrips(
  route,
  now,
  before: const Duration(minutes: 30),
  after: const Duration(minutes: 90),
);

/// The latest trip that reached [stopId] within [within] before [now]
/// (for "How was the 7:30 bus?"), with when it was due there.
({BusTripDay trip, DateTime at})? recentTripAt(
  BusRoute route,
  String stopId,
  DateTime now, {
  Duration within = const Duration(hours: 3),
}) {
  final stop = route.stops.where((s) => s.id == stopId).firstOrNull;
  if (stop == null) return null;
  ({BusTripDay trip, DateTime at})? best;
  final today = DateTime(now.year, now.month, now.day);
  for (final back in const [0, 1]) {
    final day = DateTime(today.year, today.month, today.day - back);
    for (final t in route.trips) {
      final offset = stop.offset(t.direction);
      if (offset == null || !t.weekdays.contains(day.weekday)) continue;
      final dep = day.add(Duration(minutes: t.departsMin));
      final at = dep.add(Duration(minutes: offset));
      if (at.isAfter(now) || now.difference(at) > within) continue;
      if (best == null || at.isAfter(best.at)) {
        best = (trip: (trip: t, day: day, departs: dep), at: at);
      }
    }
  }
  return best;
}

/// The stop the bus is at (within [atMetres]) or nearest to.
({BusStop stop, double metres, bool at})? busPlace(
  BusRoute route,
  BusRun run, {
  double atMetres = 200,
}) {
  final near = nearestStop(route, run.lat, run.lng);
  if (near == null) return null;
  return (stop: near.stop, metres: near.metres, at: near.metres <= atMetres);
}
