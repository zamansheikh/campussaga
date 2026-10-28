import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bus routes saved on the phone (they open offline) and each route's
/// "my stop". Saved per account.
abstract interface class TransportStore {
  Future<BusRoutes?> routes(String userId);
  Future<void> saveRoutes(String userId, BusRoutes routes);

  /// Route id → the stop id the student picked.
  Future<Map<String, String>> myStops(String userId);
  Future<void> saveMyStops(String userId, Map<String, String> stops);
}

class PrefsTransportStore implements TransportStore {
  PrefsTransportStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static String _routesKey(String user) => 'transport.routes.$user';
  static String _stopsKey(String user) => 'transport.myStops.$user';

  @override
  Future<BusRoutes?> routes(String userId) async {
    try {
      final raw = await _prefs.getString(_routesKey(userId));
      if (raw == null) return null;
      return BusRoutes.fromJson((jsonDecode(raw) as Map).cast());
    } on Object {
      return null; // an old or broken copy: fetch again
    }
  }

  @override
  Future<void> saveRoutes(String userId, BusRoutes routes) =>
      _prefs.setString(_routesKey(userId), jsonEncode(routes.toJson()));

  @override
  Future<Map<String, String>> myStops(String userId) async {
    try {
      final raw = await _prefs.getString(_stopsKey(userId));
      if (raw == null) return {};
      return (jsonDecode(raw) as Map).cast<String, String>();
    } on Object {
      return {};
    }
  }

  @override
  Future<void> saveMyStops(String userId, Map<String, String> stops) =>
      _prefs.setString(_stopsKey(userId), jsonEncode(stops));
}

/// In-memory store (tests).
class MemoryTransportStore implements TransportStore {
  final saved = <String, BusRoutes>{};
  final stops = <String, Map<String, String>>{};

  @override
  Future<BusRoutes?> routes(String userId) async => saved[userId];

  @override
  Future<void> saveRoutes(String userId, BusRoutes routes) async =>
      saved[userId] = routes;

  @override
  Future<Map<String, String>> myStops(String userId) async =>
      Map.of(stops[userId] ?? const {});

  @override
  Future<void> saveMyStops(String userId, Map<String, String> s) async =>
      stops[userId] = Map.of(s);
}
