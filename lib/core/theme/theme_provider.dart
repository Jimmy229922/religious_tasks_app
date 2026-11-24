import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';

enum AppThemeMode { light, dark, system, dynamic }

enum AppAccentColor {
  royalBlue(Color(0xFF1565C0), 'الأزرق الملكي'),
  emerald(Color(0xFF0F766E), 'الزمردي الإسلامي'),
  deepTeal(Color(0xFF0E7490), 'البترولي الهادئ'),
  indigo(Color(0xFF3730A3), 'النيلي الليلي'),
  amberGold(Color(0xFFB45309), 'الذهبي الدافئ'),
  burgundy(Color(0xFF881337), 'العنابي الوقور');

  final Color color;
  final String label;
  const AppAccentColor(this.color, this.label);
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode_v1';
  static const String _legacyThemeKey = 'app_theme_mode';
  static const String _accentKey = 'app_accent_color_v1';
  static const String _textScaleKey = 'app_text_scale_v1';
  static const String _oledBlackKey = 'app_oled_black_v1';

  static const List<double> supportedTextScales = [0.92, 1.0, 1.08, 1.16];

  AppThemeMode _appThemeMode = AppThemeMode.system;
  AppAccentColor _accentColor = AppAccentColor.royalBlue;
  double _textScaleFactor = 1.0;
  bool _useOledBlack = true;

  ThemeProvider() {
    _loadThemeModeSync();
    _loadThemeModeAsync();
  }

  AppThemeMode get appThemeMode => _appThemeMode;
  AppAccentColor get accentColor => _accentColor;
  double get textScaleFactor => _textScaleFactor;
  bool get useOledBlack => _useOledBlack;

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

        final savedAccentStr = StorageService.instance.getString(_accentKey);
        if (savedAccentStr != null) {
          _accentColor = AppAccentColor.values.firstWhere(
            (e) => e.name == savedAccentStr,
            orElse: () => AppAccentColor.royalBlue,
          );
        }

        final savedScale = StorageService.instance.prefs.getDouble(_textScaleKey);
        if (savedScale != null) {
          _textScaleFactor = savedScale.clamp(0.88, 1.25);
        }

        final savedOled = StorageService.instance.prefs.getBool(_oledBlackKey);
        if (savedOled != null) {
          _useOledBlack = savedOled;
        }
      }
    } catch (e) {
      debugPrint("Could not load stored theme mode sync: $e");
    }
  }

  Future<void> _loadThemeModeAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool changed = false;

      final savedModeStr =
          prefs.getString(_themeKey) ?? prefs.getString(_legacyThemeKey);
      if (savedModeStr != null) {
        final loadedMode = AppThemeMode.values.firstWhere(
          (e) => e.name == savedModeStr,
          orElse: () => AppThemeMode.system,
        );
        if (_appThemeMode != loadedMode) {
          _appThemeMode = loadedMode;
          changed = true;
        }
      }

      final savedAccentStr = prefs.getString(_accentKey);
      if (savedAccentStr != null) {
        final loadedAccent = AppAccentColor.values.firstWhere(
          (e) => e.name == savedAccentStr,
          orElse: () => AppAccentColor.royalBlue,
        );
        if (_accentColor != loadedAccent) {
          _accentColor = loadedAccent;
          changed = true;
        }
      }

      final savedScale = prefs.getDouble(_textScaleKey);
      if (savedScale != null) {
        final clamped = savedScale.clamp(0.88, 1.25);
        if (_textScaleFactor != clamped) {
          _textScaleFactor = clamped;
          changed = true;
        }
      }

      final savedOled = prefs.getBool(_oledBlackKey);
      if (savedOled != null && _useOledBlack != savedOled) {
        _useOledBlack = savedOled;
        changed = true;
      }

      if (changed) {
        notifyListeners();
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

  Future<void> setAccentColor(AppAccentColor accent) async {
    _accentColor = accent;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accentKey, accent.name);
      if (StorageService.isInitialized) {
        await StorageService.instance.setString(_accentKey, accent.name);
      }
    } catch (e) {
      debugPrint("Could not save accent color: $e");
    }
  }

  Future<void> setTextScaleFactor(double scale) async {
    final safeScale = scale.clamp(0.88, 1.25);
    _textScaleFactor = safeScale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textScaleKey, safeScale);
      if (StorageService.isInitialized) {
        await StorageService.instance.prefs.setDouble(_textScaleKey, safeScale);
      }
    } catch (e) {
      debugPrint("Could not save text scale: $e");
    }
  }

  Future<void> setUseOledBlack(bool value) async {
    _useOledBlack = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_oledBlackKey, value);
      if (StorageService.isInitialized) {
        await StorageService.instance.prefs.setBool(_oledBlackKey, value);
      }
    } catch (e) {
      debugPrint("Could not save OLED preference: $e");
    }
  }

  Future<void> resetAppearanceDefaults() async {
    await setThemeMode(AppThemeMode.system);
    await setAccentColor(AppAccentColor.royalBlue);
    await setTextScaleFactor(1.0);
    await setUseOledBlack(true);
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }

  Color getDynamicSeedColor(int hour) {
    if (_appThemeMode != AppThemeMode.dynamic) return _accentColor.color;

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

  String getDynamicPhaseLabel(int hour) {
    if (hour >= 4 && hour < 6) return 'أجواء الفجر الهادئة';
    if (hour >= 6 && hour < 9) return 'إشراقة الصباح والضحى';
    if (hour >= 9 && hour < 16) return 'ضوء النهار والظهر';
    if (hour >= 16 && hour < 19) return 'أصيلاً ووقت الغروب';
    return 'سكون الليل والقيام';
  }
}

extension AppThemeColors on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  Color get primaryDarkColor =>
      Color.lerp(Theme.of(this).colorScheme.primary, Colors.black, 0.36)!;

  Color get primaryLightColor =>
      Color.lerp(Theme.of(this).colorScheme.primary, Colors.white, 0.38)!;
}
