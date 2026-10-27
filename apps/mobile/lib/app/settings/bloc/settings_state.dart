import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Theme and language chosen by the student.
class SettingsState extends Equatable {
  const SettingsState({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// null = follow the phone's language.
  final Locale? locale;

  SettingsState copyWith({ThemeMode? themeMode, Locale? Function()? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale != null ? locale() : this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];
}
