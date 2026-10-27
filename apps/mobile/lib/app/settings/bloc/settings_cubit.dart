import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_state.dart';

/// App-wide settings. A Cubit (no events) because every change is a single
/// direct call; flows with several steps (sign-in, routine sync) use a Bloc.
// TODO(R0): persist settings on the device so they survive a restart.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setThemeMode(ThemeMode mode) => emit(state.copyWith(themeMode: mode));

  /// null follows the phone's language.
  void setLocale(Locale? locale) => emit(state.copyWith(locale: () => locale));
}
