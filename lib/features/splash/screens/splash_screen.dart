import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/constants/app_constants.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../settings/screens/permissions_onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SplashScreen({super.key, required this.themeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';
  String _dailyQuote = '';

  final List<String> _quotes = [
    'وَقُل رَّبِّ زِدْنِي عِلْمًا',
    'فَاذْكُرُونِي أَذْكُرْكُمْ',
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    'وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ',
    'خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ',
    'الدّالُّ عَلَى الْخَيْرِ كَفَاعِلِهِ',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 Splash Screen Init Started");
    
    // Remove the native splash immediately to reveal our Flutter Mosque splash
    // This prevents the "grey" native screen from staying too long
    FlutterNativeSplash.remove();

    _loadVersion();
    _picksRandomQuote();
    _checkOnboardingAndNavigate();
  }

  void _picksRandomQuote() {
    setState(() {
      _dailyQuote = _quotes[Random().nextInt(_quotes.length)];
    });
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${packageInfo.version}';
    });
  }

  Future<void> _checkOnboardingAndNavigate() async {
    // 1. Start initialization tasks
    final initFuture = AppNotificationService().init();
    
    // 2. Load preferences
    final prefsFuture = SharedPreferences.getInstance();

    // 3. Keep the mosque screen visible for at least 3 seconds
    await Future.wait([
      initFuture,
      prefsFuture,
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted) return;
    
    final prefs = await prefsFuture;
    final bool onboardingCompleted =
        prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;

    if (onboardingCompleted) {
      _navigateToHome();
    } else {
      // Check if all permissions are already granted
      bool allGranted = await _areAllPermissionsGranted();
      if (allGranted) {
        // Mark as completed silently and go home
        await prefs.setBool('onboarding_completed', true);
        _navigateToHome();
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PermissionsOnboardingScreen()),
        );
      }
    }
  }

  Future<bool> _areAllPermissionsGranted() async {
    final notif = await Permission.notification.status;
    final loc = await Permission.locationWhenInUse.status;

    if (!notif.isGranted || !loc.isGranted) return false;

    if (Platform.isAndroid) {
      // Check exact alarm if needed (often granted by default on older androids,
      // but strictly required on Android 12+)
      // Note: On some devices/versions status might be restricted/denied.
      // We'll check if it is explicitly denied.
      final alarm = await Permission.scheduleExactAlarm.status;
      // If it is permanently denied or denied, we might want to show onboarding.
      // However, scheduleExactAlarm is tricky. Let's assume if it is NOT granted, we show onboarding.
      // But verify if the platform actually supports asking for it.
      // For simplicity, if it's denied, return false.
      if (!alarm.isGranted) return false;
    }

    return true;
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              TasksScreen(themeProvider: widget.themeProvider)),
    );
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
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      Text(
                        _dailyQuote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily:
                              'Amiri', // Assuming you might have a font or default
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _version,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
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
