import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The student's groups and routine saved on the phone, so the app opens
/// instantly and works without internet. Saved per account: a different
/// student signing in on the same phone never sees it.
abstract interface class RoutineCache {
  Future<List<ClassGroup>?> read(String userId);
  Future<void> write(String userId, List<ClassGroup> groups);
  Future<void> clear();
}

class PrefsRoutineCache implements RoutineCache {
  PrefsRoutineCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const key = 'classes.groups';
  final SharedPreferencesAsync _prefs;

  @override
  Future<List<ClassGroup>?> read(String userId) async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, Object?>;
      if (json['userId'] != userId) return null;
      return [
        for (final g in json['groups']! as List<Object?>)
          ClassGroup.fromJson(g! as Map<String, Object?>),
      ];
    } on Object {
      return null; // unreadable (older format): fetch again
    }
  }

  @override
  Future<void> write(String userId, List<ClassGroup> groups) =>
      _prefs.setString(
        key,
        jsonEncode({
          'userId': userId,
          'groups': [for (final g in groups) g.toJson()],
        }),
      );

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// In-memory cache (tests).
class MemoryRoutineCache implements RoutineCache {
  String? userId;
  List<ClassGroup>? groups;

  @override
  Future<List<ClassGroup>?> read(String userId) async =>
      userId == this.userId ? groups : null;

  @override
  Future<void> write(String userId, List<ClassGroup> groups) async {
    this.userId = userId;
    this.groups = groups;
  }

  @override
  Future<void> clear() async {
    userId = null;
    groups = null;
  }
}
