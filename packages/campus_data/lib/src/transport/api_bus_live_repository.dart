import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Live buses over HTTP (docs/BUS_LIVE.md §3).
class ApiBusLiveRepository implements BusLiveRepository {
  ApiBusLiveRepository(this._api);

  final ApiClient _api;

  static Map<String, Object?> _map(Object? v) => (v! as Map).cast();

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<BusLive> live(String routeId) async =>
      BusLive.fromJson(_map(await _api.get('/transport/routes/$routeId/live')));

  @override
  Future<Map<String, int>> liveRoutes() async {
    final j = _map(await _api.get('/transport/live'));
    return {
      for (final r in (j['routes'] as List? ?? const []))
        (r as Map)['routeId']! as String: (r['riders'] as num?)?.toInt() ?? 1,
    };
  }

  @override
  Future<({String sessionId, BusLive live})> startSharing(
    String routeId, {
    required BusDirection direction,
    int? departsMin,
    required double lat,
    required double lng,
    double accuracy = 0,
  }) async {
    final j = _map(
      await _api.post('/transport/routes/$routeId/live/share', {
        'direction': direction.wire,
        'departs': busDepartsWire(departsMin),
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
      }),
    );
    return (
      sessionId: j['sessionId']! as String,
      live: j['live'] is Map ? BusLive.fromJson(_map(j['live'])) : BusLive.none,
    );
  }

  @override
  Future<BusPingResult> ping(String sessionId, List<BusPoint> points) async =>
      BusPingResult.fromJson(
        _map(
          await _api.post('/transport/live/$sessionId/pings', {
            'points': [for (final p in points) p.toJson()],
          }),
        ),
      );

  @override
  Future<BusShareThanks> stopSharing(String sessionId) async =>
      BusShareThanks.fromJson(
        _map(await _api.post('/transport/live/$sessionId/stop')),
      );

  @override
  Future<BusTripInsight> sendFeedback(
    String routeId, {
    required BusDirection direction,
    required int departsMin,
    required DateTime date,
    required BusTripStatus status,
    bool crowded = false,
  }) async => BusTripInsight.fromJson(
    _map(
      await _api.post('/transport/routes/$routeId/feedback', {
        'direction': direction.wire,
        'departs': busDepartsWire(departsMin),
        'date': _date(date),
        'status': status.wire,
        'crowded': crowded,
      }),
    ),
  );

  @override
  Future<List<BusTripInsight>> insights(String routeId) async {
    final j = _map(await _api.get('/transport/routes/$routeId/insights'));
    return [
      for (final t in (j['trips'] as List? ?? const []))
        BusTripInsight.fromJson((t as Map).cast()),
    ];
  }

  @override
  Future<List<BusAlert>> alerts() async {
    final j = _map(await _api.get('/transport/alerts'));
    return [
      for (final a in (j['alerts'] as List? ?? const []))
        BusAlert.fromJson((a as Map).cast()),
    ];
  }

  @override
  Future<BusAlert> setAlert(
    String routeId, {
    required String stopId,
    required BusDirection direction,
    required int leadMin,
  }) async {
    await _api.put('/transport/routes/$routeId/alert', {
      'stopId': stopId,
      'direction': direction.wire,
      'leadMin': leadMin,
    });
    return BusAlert(
      routeId: routeId,
      stopId: stopId,
      direction: direction,
      leadMin: leadMin,
    );
  }

  @override
  Future<void> removeAlert(String routeId, BusDirection direction) => _api
      .delete('/transport/routes/$routeId/alert?direction=${direction.wire}');
}
