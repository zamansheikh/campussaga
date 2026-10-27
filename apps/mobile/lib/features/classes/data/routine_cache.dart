import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The student's groups and routine saved on the phone, so the app opens
/// instantly and works without internet. Saved per account: a different
/// student signing in on the same phone never sees it.
abstract interface class RoutineCache {
  Future<SavedRoutine?> read(String userId);
  Future<void> write(String userId, SavedRoutine routine);
  Future<void> clear();
}

/// What is kept: the groups (with their routines) and personal classes.
typedef SavedRoutine = ({List<ClassGroup> groups, List<ClassSlot> personal});

class PrefsRoutineCache implements RoutineCache {
  PrefsRoutineCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const key = 'classes.groups';
  final SharedPreferencesAsync _prefs;

  @override
  Future<SavedRoutine?> read(String userId) async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, Object?>;
      if (json['userId'] != userId) return null;
      return (
        groups: [
          for (final g in json['groups']! as List<Object?>)
            ClassGroup.fromJson(g! as Map<String, Object?>),
        ],
        personal: [
          for (final p in json['personal'] as List<Object?>? ?? const [])
            ClassSlot.fromJson(p! as Map<String, Object?>),
        ],
      );
    } on Object {
      return null; // unreadable (older format): fetch again
    }
  }

  @override
  Future<void> write(String userId, SavedRoutine routine) => _prefs.setString(
    key,
    jsonEncode({
      'userId': userId,
      'groups': [for (final g in routine.groups) g.toJson()],
      'personal': [for (final p in routine.personal) p.toJson()],
    }),
  );

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// In-memory cache (tests).
class MemoryRoutineCache implements RoutineCache {
  String? userId;
  List<ClassGroup>? groups;
  List<ClassSlot> personal = const [];

  @override
  Future<SavedRoutine?> read(String userId) async =>
      userId == this.userId && groups != null
      ? (groups: groups!, personal: personal)
      : null;

  @override
  Future<void> write(String userId, SavedRoutine routine) async {
    this.userId = userId;
    groups = routine.groups;
    personal = routine.personal;
  }

  @override
  Future<void> clear() async {
    userId = null;
    groups = null;
    personal = const [];
  }
}
