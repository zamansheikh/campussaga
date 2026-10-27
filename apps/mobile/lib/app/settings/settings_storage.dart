import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/settings_state.dart';

/// Where theme and language are kept between app starts.
abstract interface class SettingsStorage {
  /// Read synchronously, so the first frame already has the right theme.
  SettingsState read();
  Future<void> write(SettingsState settings);
}

/// On-device storage (NSUserDefaults / SharedPreferences).
class PrefsSettingsStorage implements SettingsStorage {
  PrefsSettingsStorage(this._prefs);

  static const themeKey = 'settings.theme';
  static const localeKey = 'settings.locale';
  static const keys = {themeKey, localeKey};

  final SharedPreferencesWithCache _prefs;

  /// Loads the cache once, before runApp.
  static Future<PrefsSettingsStorage> open() async => PrefsSettingsStorage(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
    ),
  );

  @override
  SettingsState read() {
    final theme = switch (_prefs.getString(themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final lang = _prefs.getString(localeKey);
    return SettingsState(
      themeMode: theme,
      locale: lang == 'en' || lang == 'bn' ? Locale(lang!) : null,
    );
  }

  @override
  Future<void> write(SettingsState s) async {
    await _prefs.setString(themeKey, s.themeMode.name);
    final lang = s.locale?.languageCode;
    if (lang == null) {
      await _prefs.remove(localeKey);
    } else {
      await _prefs.setString(localeKey, lang);
    }
  }
}

/// In-memory storage (tests).
class MemorySettingsStorage implements SettingsStorage {
  MemorySettingsStorage([this.saved = const SettingsState()]);

  SettingsState saved;

  @override
  SettingsState read() => saved;

  @override
  Future<void> write(SettingsState s) async => saved = s;
}
