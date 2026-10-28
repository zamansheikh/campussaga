import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The CGPA record, saved only on this phone, per account (another student
/// signing in on the same phone never sees it).
abstract interface class CgpaStore {
  Future<CgpaBook?> read(String userId);
  Future<void> write(String userId, CgpaBook book);
  Future<void> clear(String userId);
}

class PrefsCgpaStore implements CgpaStore {
  PrefsCgpaStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static String key(String userId) => 'cgpa.v${CgpaBook.version}.$userId';

  @override
  Future<CgpaBook?> read(String userId) async {
    try {
      final raw = await _prefs.getString(key(userId));
      if (raw == null) return null;
      return CgpaBook.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null; // unreadable: start fresh rather than crash
    }
  }

  @override
  Future<void> write(String userId, CgpaBook book) =>
      _prefs.setString(key(userId), jsonEncode(book.toJson()));

  @override
  Future<void> clear(String userId) => _prefs.remove(key(userId));
}

/// In memory (tests). Keeps the JSON so tests see the real round trip.
class MemoryCgpaStore implements CgpaStore {
  final saved = <String, String>{};

  @override
  Future<CgpaBook?> read(String userId) async {
    final raw = saved[userId];
    return raw == null
        ? null
        : CgpaBook.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> write(String userId, CgpaBook book) async =>
      saved[userId] = jsonEncode(book.toJson());

  @override
  Future<void> clear(String userId) async => saved.remove(userId);
}
