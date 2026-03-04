import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  // Switch to light theme
  void setLightTheme() {
    emit(ThemeMode.light);
  }

  // Switch to dark theme
  void setDarkTheme() {
    emit(ThemeMode.dark);
  }

  // Toggle between light and dark themes
  void toggleTheme(bool isDarkMode) {
    if (isDarkMode) {
      setDarkTheme();
    } else {
      setLightTheme();
    }
  }

  // Check if currently in dark mode
  bool get isDarkMode => state == ThemeMode.dark;
}
