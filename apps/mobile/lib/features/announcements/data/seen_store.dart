import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// When the student last looked at each group's announcements (for the
/// "New" badge). Kept on the phone only.
abstract interface class SeenStore {
  Future<Map<String, DateTime>> read();
  Future<void> write(Map<String, DateTime> seen);
}

class PrefsSeenStore implements SeenStore {
  PrefsSeenStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const key = 'announcements.seen';
  final SharedPreferencesAsync _prefs;

  @override
  Future<Map<String, DateTime>> read() async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null) return {};
      return {
        for (final e in (jsonDecode(raw) as Map<String, Object?>).entries)
          e.key: DateTime.parse(e.value! as String),
      };
    } on Object {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, DateTime> seen) => _prefs.setString(
    key,
    jsonEncode({
      for (final e in seen.entries) e.key: e.value.toUtc().toIso8601String(),
    }),
  );
}

class MemorySeenStore implements SeenStore {
  Map<String, DateTime> saved = {};

  @override
  Future<Map<String, DateTime>> read() async => Map.of(saved);

  @override
  Future<void> write(Map<String, DateTime> seen) async => saved = Map.of(seen);
}
