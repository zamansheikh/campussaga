import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in student's profile saved on the phone, so the app opens
/// without internet (with the saved routine) instead of signing out.
/// Removed on sign-out.
abstract interface class ProfileCache {
  Future<UserProfile?> read();
  Future<void> write(UserProfile user);
  Future<void> clear();
}

class PrefsProfileCache implements ProfileCache {
  PrefsProfileCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const key = 'auth.profile';
  final SharedPreferencesAsync _prefs;

  @override
  Future<UserProfile?> read() async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null) return null;
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null; // unreadable: as if none
    }
  }

  @override
  Future<void> write(UserProfile user) =>
      _prefs.setString(key, jsonEncode(user.toJson()));

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// Keeps the profile in memory (tests).
class MemoryProfileCache implements ProfileCache {
  MemoryProfileCache([this.saved]);

  UserProfile? saved;

  @override
  Future<UserProfile?> read() async => saved;

  @override
  Future<void> write(UserProfile user) async => saved = user;

  @override
  Future<void> clear() async => saved = null;
}
