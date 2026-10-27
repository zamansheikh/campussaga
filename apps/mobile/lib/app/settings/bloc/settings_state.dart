import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Theme and language chosen by the student, and whether the welcome
/// slides were already shown on this device.
class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.onboardingDone = false,
  });

  final ThemeMode themeMode;

  /// null = follow the phone's language.
  final Locale? locale;

  /// The welcome slides are shown once, before the first sign-in.
  final bool onboardingDone;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? Function()? locale,
    bool? onboardingDone,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale != null ? locale() : this.locale,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, onboardingDone];
}
