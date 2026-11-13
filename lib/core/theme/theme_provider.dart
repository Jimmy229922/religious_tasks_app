import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';

enum AppThemeMode { light, dark, system, dynamic }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode_v1';
  static const String _legacyThemeKey = 'app_theme_mode';
  AppThemeMode _appThemeMode = AppThemeMode.system;

  ThemeProvider() {
    _loadThemeModeSync();
    _loadThemeModeAsync();
  }

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.dynamic:
        final hour = DateTime.now().hour;
        return (hour >= 6 && hour < 18) ? ThemeMode.light : ThemeMode.dark;
    }
  }

  void _loadThemeModeSync() {
    try {
      if (StorageService.isInitialized) {
        final savedModeStr = StorageService.instance.getString(_themeKey) ??
            StorageService.instance.getString(_legacyThemeKey);
        if (savedModeStr != null) {
          _appThemeMode = AppThemeMode.values.firstWhere(
            (e) => e.name == savedModeStr,
            orElse: () => AppThemeMode.system,
          );
        }
      }
    } catch (e) {
      debugPrint("Could not load stored theme mode sync: $e");
    }
  }

  Future<void> _loadThemeModeAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeStr =
          prefs.getString(_themeKey) ?? prefs.getString(_legacyThemeKey);
      if (savedModeStr != null) {
        final loadedMode = AppThemeMode.values.firstWhere(
          (e) => e.name == savedModeStr,
          orElse: () => AppThemeMode.system,
        );
        if (_appThemeMode != loadedMode) {
          _appThemeMode = loadedMode;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Could not load stored theme mode async: $e");
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _appThemeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
      await prefs.setString(_legacyThemeKey, mode.name);
      if (StorageService.isInitialized) {
        await StorageService.instance.setString(_themeKey, mode.name);
        await StorageService.instance.setString(_legacyThemeKey, mode.name);
      }
    } catch (e) {
      debugPrint("Could not save theme mode: $e");
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
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

