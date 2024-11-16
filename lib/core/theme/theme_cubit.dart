import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_theme_plus/json_theme_plus.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(ThemeData.light()) {
    // Load the initial theme (e.g., light theme)
    _loadTheme('assets/theme/theme_light.json');
  }

  // Load a theme from a JSON file
  Future<void> _loadTheme(String themePath) async {
    final jsonString = await rootBundle.loadString(themePath);
    final themeJson = json.decode(jsonString);
    final themeData = ThemeDecoder.decodeThemeData(themeJson);

    if (themeData != null) {
      emit(themeData);
    }
  }

  // Switch to light theme
  void setLightTheme() {
    _loadTheme('assets/theme/theme_light.json');
  }

  // Switch to dark theme
  void setDarkTheme() {
    _loadTheme('assets/theme/theme_dark.json');
  }

  // Toggle between light and dark themes
  void toggleTheme(bool isDarkMode) {
    if (isDarkMode) {
      setDarkTheme();
    } else {
      setLightTheme();
    }
  }
}
