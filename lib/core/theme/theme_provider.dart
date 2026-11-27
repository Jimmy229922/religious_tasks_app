import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';

enum AppThemeMode { light, dark, system, dynamic }

enum PrayerThemePhase {
  fajr(Color(0xFF3B5BA9), Color(0xFF8FA8F0), 'أجواء الفجر الهادئة', true),
  duha(Color(0xFFB45309), Color(0xFFFBBF24), 'إشراقة الضحى', false),
  dhuhr(Color(0xFF0F766E), Color(0xFF2DD4BF), 'نور الظهيرة', false),
  asr(Color(0xFF9A3412), Color(0xFFFB923C), 'وقت الأصيل', false),
  maghrib(Color(0xFF7E22CE), Color(0xFFC084FC), 'سكينة الغروب', true),
  isha(Color(0xFF1E3A8A), Color(0xFF93C5FD), 'سكون الليل والقيام', true);

  final Color color;
  final Color darkColor;
  final String label;
  final bool isNight;
  const PrayerThemePhase(this.color, this.darkColor, this.label, this.isNight);

  Color colorFor(bool isDark) => isDark ? darkColor : color;
}

enum AppAccentColor {
  emerald(Color(0xFF0F766E), Color(0xFF2DD4BF), 'الزمردي الإسلامي'),
  royalBlue(Color(0xFF1565C0), Color(0xFF60A5FA), 'الأزرق الملكي'),
  deepTeal(Color(0xFF0E7490), Color(0xFF22D3EE), 'البترولي الهادئ'),
  indigo(Color(0xFF3730A3), Color(0xFF818CF8), 'النيلي الليلي'),
  amberGold(Color(0xFFB45309), Color(0xFFFBBF24), 'الذهبي الدافئ'),
  burgundy(Color(0xFF881337), Color(0xFFFB7185), 'العنابي الوقور'),
  oliveGreen(Color(0xFF3F6212), Color(0xFFA3E635), 'الزيتوني الهادئ'),
  royalPurple(Color(0xFF6D28D9), Color(0xFFA78BFA), 'البنفسجي الملكي'),
  desertBronze(Color(0xFF9A3412), Color(0xFFFB923C), 'البرونزي الدافئ');

  final Color color;
  final Color darkColor;
  final String label;
  const AppAccentColor(this.color, this.darkColor, this.label);

  Color colorFor(bool isDark) => isDark ? darkColor : color;
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode_v1';
  static const String _legacyThemeKey = 'app_theme_mode';
  static const String _accentKey = 'app_accent_color_v1';
  static const String _textScaleKey = 'app_text_scale_v1';
  static const String _oledBlackKey = 'app_oled_black_v1';

  static const List<double> supportedTextScales = [0.92, 1.0, 1.08, 1.16];

  AppThemeMode _appThemeMode = AppThemeMode.system;
  AppAccentColor _accentColor = AppAccentColor.emerald;
  double _textScaleFactor = 1.0;
  bool _useOledBlack = true;
  PrayerThemePhase? _prayerPhase;
  PrayerThemePhase? _nextPrayerPhase;
  DateTime? _nextPhaseAt;
  Timer? _phaseTimer;

  ThemeProvider() {
    _loadThemeModeSync();
    _loadThemeModeAsync();
  }

  AppThemeMode get appThemeMode => _appThemeMode;
  AppAccentColor get accentColor => _accentColor;
  double get textScaleFactor => _textScaleFactor;
  bool get useOledBlack => _useOledBlack;
  PrayerThemePhase get prayerPhase =>
      _prayerPhase ?? _clockPhase(DateTime.now().hour);
  PrayerThemePhase? get nextPrayerPhase => _nextPrayerPhase;
  DateTime? get nextPhaseAt => _nextPhaseAt;

  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.dynamic:
        return prayerPhase.isNight ? ThemeMode.dark : ThemeMode.light;
    }
  }

  PrayerThemePhase _clockPhase(int hour) {
    if (hour >= 4 && hour < 6) return PrayerThemePhase.fajr;
    if (hour >= 6 && hour < 12) return PrayerThemePhase.duha;
    if (hour >= 12 && hour < 15) return PrayerThemePhase.dhuhr;
    if (hour >= 15 && hour < 17) return PrayerThemePhase.asr;
    if (hour >= 17 && hour < 19) return PrayerThemePhase.maghrib;
    return PrayerThemePhase.isha;
  }

  Future<void> refreshPrayerPhase() async {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    if (_appThemeMode != AppThemeMode.dynamic) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = double.tryParse(prefs.getString('last_latitude') ?? '');
      final lng = double.tryParse(prefs.getString('last_longitude') ?? '');

      if (lat == null || lng == null) {
        _applyPrayerPhase(null, null, null);
        _phaseTimer =
            Timer(const Duration(minutes: 2), () => refreshPrayerPhase());
        return;
      }

      final savedMethod = prefs.getString('calculation_method');
      var method = CalculationMethod.egyptian;
      if (savedMethod != null) {
        method = CalculationMethod.values.firstWhere(
          (e) => e.name == savedMethod,
          orElse: () => CalculationMethod.egyptian,
        );
      }

      final params = method.getParameters();
      params.madhab = Madhab.shafi;
      int offset(String key) =>
          (prefs.getInt('prayer_offset_$key') ?? 0).clamp(-60, 60);
      params.adjustments.fajr = offset('fajr');
      params.adjustments.sunrise = offset('sunrise');
      params.adjustments.dhuhr = offset('dhuhr');
      params.adjustments.asr = offset('asr');
      params.adjustments.maghrib = offset('maghrib');
      params.adjustments.isha = offset('isha');

      final coordinates = Coordinates(lat, lng);
      final now = DateTime.now();
      final today = PrayerTimes.today(coordinates, params);
      final tomorrowDate = now.add(const Duration(days: 1));
      final tomorrow = PrayerTimes(
        coordinates,
        DateComponents(tomorrowDate.year, tomorrowDate.month, tomorrowDate.day),
        params,
      );

      final PrayerThemePhase phase;
      final PrayerThemePhase nextPhase;
      final DateTime nextAt;
      if (now.isBefore(today.fajr)) {
        phase = PrayerThemePhase.isha;
        nextPhase = PrayerThemePhase.fajr;
        nextAt = today.fajr;
      } else if (now.isBefore(today.sunrise)) {
        phase = PrayerThemePhase.fajr;
        nextPhase = PrayerThemePhase.duha;
        nextAt = today.sunrise;
      } else if (now.isBefore(today.dhuhr)) {
        phase = PrayerThemePhase.duha;
        nextPhase = PrayerThemePhase.dhuhr;
        nextAt = today.dhuhr;
      } else if (now.isBefore(today.asr)) {
        phase = PrayerThemePhase.dhuhr;
        nextPhase = PrayerThemePhase.asr;
        nextAt = today.asr;
      } else if (now.isBefore(today.maghrib)) {
        phase = PrayerThemePhase.asr;
        nextPhase = PrayerThemePhase.maghrib;
        nextAt = today.maghrib;
      } else if (now.isBefore(today.isha)) {
        phase = PrayerThemePhase.maghrib;
        nextPhase = PrayerThemePhase.isha;
        nextAt = today.isha;
      } else {
        phase = PrayerThemePhase.isha;
        nextPhase = PrayerThemePhase.fajr;
        nextAt = tomorrow.fajr;
      }

      _applyPrayerPhase(phase, nextPhase, nextAt.toLocal());
      final delay = nextAt.difference(now) + const Duration(seconds: 1);
      _phaseTimer = Timer(
        delay.isNegative ? const Duration(seconds: 1) : delay,
        () => refreshPrayerPhase(),
      );
    } catch (e) {
      debugPrint("Could not resolve prayer theme phase: $e");
    }
  }

  void _applyPrayerPhase(
    PrayerThemePhase? phase,
    PrayerThemePhase? nextPhase,
    DateTime? nextAt,
  ) {
    final changed = _prayerPhase != phase ||
        _nextPrayerPhase != nextPhase ||
        _nextPhaseAt != nextAt;
    _prayerPhase = phase;
    _nextPrayerPhase = nextPhase;
    _nextPhaseAt = nextAt;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
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
            orElse: () => AppAccentColor.emerald,
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
    await refreshPrayerPhase();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _appThemeMode = mode;
    notifyListeners();
    unawaited(refreshPrayerPhase());
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
    await setAccentColor(AppAccentColor.emerald);
    await setTextScaleFactor(1.0);
    await setUseOledBlack(true);
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }

  Color getDynamicSeedColor(int hour, {bool isDark = false}) {
    if (_appThemeMode != AppThemeMode.dynamic) {
      return _accentColor.colorFor(isDark);
    }
    return (_prayerPhase ?? _clockPhase(hour)).colorFor(isDark);
  }

  String getDynamicPhaseLabel(int hour) {
    return (_prayerPhase ?? _clockPhase(hour)).label;
  }
}

extension AppThemeColors on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  Color get primaryDarkColor =>
      Color.lerp(Theme.of(this).colorScheme.primary, Colors.black, 0.36)!;

  Color get primaryLightColor =>
      Color.lerp(Theme.of(this).colorScheme.primary, Colors.white, 0.38)!;

  bool get _isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  bool get _isDefaultEmerald =>
      primaryColor.toARGB32() == AppAccentColor.emerald.color.toARGB32() ||
      primaryColor.toARGB32() == AppAccentColor.emerald.darkColor.toARGB32();

  List<Color> get appBgGradient {
    if (_isDarkTheme) {
      if (_isDefaultEmerald) {
        return const [Color(0xFF041D16), Color(0xFF07281F), Color(0xFF041410)];
      }
      return [
        Color.lerp(const Color(0xFF04070B), primaryColor, 0.22)!,
        Color.lerp(const Color(0xFF060B12), primaryColor, 0.30)!,
        Color.lerp(const Color(0xFF030508), primaryColor, 0.15)!,
      ];
    }
    if (_isDefaultEmerald) {
      return const [Color(0xFFFFFDF7), Color(0xFFF8F0DB), Color(0xFFFFFBF0)];
    }
    return [
      Color.lerp(const Color(0xFFFFFDF9), primaryColor, 0.04)!,
      Color.lerp(const Color(0xFFFBF6EC), primaryColor, 0.10)!,
      Color.lerp(const Color(0xFFFFFDF9), primaryColor, 0.05)!,
    ];
  }

  Color get appScaffoldBg => appBgGradient.first;

  Color get appHeaderBg => appBgGradient[1];

  List<Color> get appCardGradient {
    if (_isDarkTheme) {
      if (_isDefaultEmerald) {
        return const [Color(0xFF0E211E), Color(0xFF0A171C)];
      }
      return [
        Color.lerp(const Color(0xFF091017), primaryColor, 0.22)!,
        Color.lerp(const Color(0xFF060B10), primaryColor, 0.14)!,
      ];
    }
    if (_isDefaultEmerald) {
      return const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)];
    }
    return [
      Color.lerp(const Color(0xFFFFFDF9), primaryColor, 0.03)!,
      Color.lerp(const Color(0xFFF8F2E7), primaryColor, 0.10)!,
    ];
  }
}
