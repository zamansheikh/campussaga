import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// [TransportRepository] on top of the VarsityKotha API (/transport).
class ApiTransportRepository implements TransportRepository {
  ApiTransportRepository(this._api);

  final ApiClient _api;

  static BusRoute _route(Object? data) =>
      BusRoute.fromJson((data! as Map).cast());

  @override
  Future<BusRoutes> routes() async => BusRoutes.fromJson(
    ((await _api.get('/transport/routes'))! as Map).cast(),
  );

  Map<String, Object?> _fields(
    String name,
    String color,
    String notes,
    bool active,
  ) => {'name': name, 'color': color, 'notes': notes, 'active': active};

  @override
  Future<BusRoute> createRoute({
    required String name,
    required String color,
    String notes = '',
    bool active = true,
  }) async => _route(
    await _api.post('/transport/routes', _fields(name, color, notes, active)),
  );

  @override
  Future<BusRoute> updateRoute(
    String id, {
    required String name,
    required String color,
    String notes = '',
    bool active = true,
  }) async => _route(
    await _api.put(
      '/transport/routes/$id',
      _fields(name, color, notes, active),
    ),
  );

  @override
  Future<void> deleteRoute(String id) => _api.delete('/transport/routes/$id');

  @override
  Future<BusRoute> setStops(String id, List<BusStop> stops) async => _route(
    await _api.put('/transport/routes/$id/stops', {
      'stops': [
        for (final s in stops)
          {
            'name': s.name,
            'landmark': s.landmark,
            'toCampusMin': s.toCampusMin,
            'fromCampusMin': s.fromCampusMin,
            // Always sent: null removes the stop's place on the map.
            'location': s.locationJson,
          },
      ],
    }),
  );

  @override
  Future<BusRoute> setTrips(String id, List<BusTrip> trips) async => _route(
    await _api.put('/transport/routes/$id/trips', {
      'trips': [
        for (final t in trips)
          {
            'direction': t.direction.wire,
            'departs': Clock.format(t.departsMin),
            'weekdays': (t.weekdays.toList()..sort()),
            'note': t.note,
          },
      ],
    }),
  );
}
