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

  /// Trips the student rated or waved away ("How was the 7:30 bus?").
  Future<Set<String>> feedbackDone(String userId);
  Future<void> saveFeedbackDone(String userId, Set<String> keys);
}

class PrefsTransportStore implements TransportStore {
  PrefsTransportStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static String _routesKey(String user) => 'transport.routes.$user';
  static String _stopsKey(String user) => 'transport.myStops.$user';
  static String _feedbackKey(String user) => 'transport.feedback.$user';

  /// Only the latest are kept: older trips are never asked about.
  static const _keepFeedback = 40;

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

  @override
  Future<Set<String>> feedbackDone(String userId) async {
    try {
      return {...?await _prefs.getStringList(_feedbackKey(userId))};
    } on Object {
      return {};
    }
  }

  @override
  Future<void> saveFeedbackDone(String userId, Set<String> keys) {
    final list = keys.toList();
    return _prefs.setStringList(
      _feedbackKey(userId),
      list.length > _keepFeedback
          ? list.sublist(list.length - _keepFeedback)
          : list,
    );
  }
}

/// In-memory store (tests).
class MemoryTransportStore implements TransportStore {
  final saved = <String, BusRoutes>{};
  final stops = <String, Map<String, String>>{};
  final feedback = <String, Set<String>>{};

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

  @override
  Future<Set<String>> feedbackDone(String userId) async => {
    ...?feedback[userId],
  };

  @override
  Future<void> saveFeedbackDone(String userId, Set<String> keys) async =>
      feedback[userId] = {...keys};
}
