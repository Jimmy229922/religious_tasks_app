import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/core/services/notifications_service.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../../settings/screens/permissions_onboarding_screen.dart';
import '../../tasks/screens/tasks_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SplashScreen({super.key, required this.themeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1200);
  static const Duration _quoteRotationDuration = Duration(milliseconds: 1400);

  final List<String> _quotes = [
    'وَقُل رَّبِّ زِدْنِي عِلْمًا',
    'فَاذْكُرُونِي أَذْكُرْكُمْ',
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    'وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ',
    'خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ',
    'الدَّالُّ عَلَى الْخَيْرِ كَفَاعِلِهِ',
  ];

  late final Stopwatch _splashStopwatch;
  Timer? _quoteTimer;
  int _quoteIndex = 0;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _splashStopwatch = Stopwatch()..start();
    _quoteIndex = Random().nextInt(_quotes.length);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    _startQuoteRotation();
    _loadVersion();
    _resolveStartup();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _startQuoteRotation() {
    _quoteTimer = Timer.periodic(_quoteRotationDuration, (_) {
      if (!mounted) return;
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      });
    });
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = 'v${packageInfo.version}';
    });
  }

  Future<void> _resolveStartup() async {
    try {
      await NotificationManager().init();
    } catch (e) {
      debugPrint("Notification init error: $e");
    }

    try {
      final prefs = StorageService.instance.prefs;
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      if (onboardingCompleted) {
        await _finishWith(
          TasksScreen(themeProvider: widget.themeProvider),
        );
        return;
      }

      final allGranted = await _areAllPermissionsGranted();
      if (!mounted) return;

      if (allGranted) {
        await prefs.setBool('onboarding_completed', true);
        await _finishWith(
          TasksScreen(themeProvider: widget.themeProvider),
        );
      } else {
        await _finishWith(const PermissionsOnboardingScreen());
      }
    } catch (e) {
      debugPrint("Startup resolution error: $e");
      await _finishWith(
        TasksScreen(themeProvider: widget.themeProvider),
      );
    }
  }

  Future<void> _finishWith(Widget screen) async {
    await _ensureMinimumSplashDuration();
    _quoteTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _ensureMinimumSplashDuration() async {
    final remaining = _minimumSplashDuration - _splashStopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  Future<bool> _areAllPermissionsGranted() async {
    final notif = await Permission.notification.status;
    final loc = await Permission.locationWhenInUse.status;

    if (!notif.isGranted || !loc.isGranted) return false;

    if (Platform.isAndroid) {
      final alarm = await Permission.scheduleExactAlarm.status;
      if (!alarm.isGranted) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 1),
                  Column(
                    children: [
                      const Icon(Icons.mosque, size: 100, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        kAppName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'جاري تحميل البيانات... يرجى الانتظار',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          _quotes[_quoteIndex],
                          key: ValueKey<int>(_quoteIndex),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Amiri',
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _version,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '© 2026 جميع الحقوق محفوظة - أحمد جمال',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
