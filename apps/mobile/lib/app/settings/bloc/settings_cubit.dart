import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings_storage.dart';
import 'settings_state.dart';

/// App-wide settings, saved on the device. A Cubit (no events) because
/// every change is a single direct call.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage) : super(_storage.read());

  final SettingsStorage _storage;

  void setThemeMode(ThemeMode mode) => _set(state.copyWith(themeMode: mode));

  /// null follows the phone's language.
  void setLocale(Locale? locale) => _set(state.copyWith(locale: () => locale));

  void _set(SettingsState next) {
    emit(next);
    unawaited(_storage.write(next));
  }
}
