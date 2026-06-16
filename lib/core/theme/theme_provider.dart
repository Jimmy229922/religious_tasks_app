import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system, dynamic }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _appThemeMode = AppThemeMode.system;

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      case AppThemeMode.dynamic:
        return ThemeMode.system;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    _appThemeMode = mode;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _appThemeMode = isDark ? AppThemeMode.dark : AppThemeMode.light;
    notifyListeners();
  }

  Color getDynamicSeedColor(int hour) {
    if (_appThemeMode != AppThemeMode.dynamic) return const Color(0xFF1565C0);

    // Fajr (Dawn)
    if (hour >= 4 && hour < 6) return Colors.indigo;
    // Morning/Sunrise
    if (hour >= 6 && hour < 9) return Colors.orange;
    // Day
    if (hour >= 9 && hour < 16) return Colors.blue;
    // Sunset/Asr
    if (hour >= 16 && hour < 19) return Colors.deepOrange;
    // Night
    return Colors.blueGrey;
  }
}

