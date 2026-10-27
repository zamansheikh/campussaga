import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where reminder choices are kept on the phone.
abstract interface class ReminderStore {
  Future<ReminderSettings> read();
  Future<void> write(ReminderSettings settings);
}

class PrefsReminderStore implements ReminderStore {
  PrefsReminderStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const key = 'reminders.settings';
  final SharedPreferencesAsync _prefs;

  @override
  Future<ReminderSettings> read() async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null) return const ReminderSettings();
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const ReminderSettings();
    }
  }

  @override
  Future<void> write(ReminderSettings s) =>
      _prefs.setString(key, jsonEncode(s.toJson()));
}

/// In-memory store (tests).
class MemoryReminderStore implements ReminderStore {
  MemoryReminderStore([this.saved = const ReminderSettings()]);

  ReminderSettings saved;

  @override
  Future<ReminderSettings> read() async => saved;

  @override
  Future<void> write(ReminderSettings s) async => saved = s;
}
