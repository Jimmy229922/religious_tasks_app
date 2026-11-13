import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';

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
  late final String _dailyQuote;

  static const List<String> _quotes = [
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
    _dailyQuote = _quotes[Random().nextInt(_quotes.length)];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    _loadVersion();
    _checkOnboardingAndNavigate();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${packageInfo.version}';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkOnboardingAndNavigate() async {
    try {
      final prefsFuture = SharedPreferences.getInstance();
      final minDelayFuture = Future.delayed(const Duration(milliseconds: 1200));

      await Future.wait([
        prefsFuture,
        minDelayFuture,
      ]);

      if (!mounted) return;
      
      final prefs = await prefsFuture;
      final bool onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      if (onboardingCompleted) {
        _navigateToHome();
      } else {
        bool allGranted = await _areAllPermissionsGranted().catchError((e) => false);
        if (allGranted) {
          await prefs.setBool('onboarding_completed', true);
          _navigateToHome();
        } else {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const PermissionsOnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Fatal error in Splash Screen: $e");
      _navigateToHome();
    }
  }

  Future<bool> _areAllPermissionsGranted() async {
    final notificationGranted = await Permission.notification.isGranted;
    final locationGranted = await Permission.locationWhenInUse.isGranted;

    if (!notificationGranted || !locationGranted) {
      return false;
    }

    if (Platform.isAndroid) {
      final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
      if (!exactAlarmGranted) {
        return false;
      }
    }

    return true;
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TasksScreen(themeProvider: widget.themeProvider),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
        : const [Color(0xFFF0FDFA), Color(0xFFE0F2F1), Color(0xFFCCFBF1)];
    final titleColor = isDark ? Colors.white : const Color(0xFF0F3D3E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF115E59);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF334155);

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  
                  // Center Logo & Title Block
                  Column(
                    children: [
                      Container(
                        width: 152,
                        height: 152,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFD4AF37), // Metallic Gold
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFFD4AF37)
                                  .withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: ColoredBox(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        kAppName,
                        style: GoogleFonts.arefRuqaa(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          shadows: isDark
                              ? const [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 3),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'رفيقك اليومي في الطاعات والأذكار',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Loading Indicator
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : Colors.teal.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'جاري تحميل البيانات... يرجى الانتظار',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Daily Ayah / Quote Glass Card
                      if (_dailyQuote.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.teal.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.teal.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Text(
                            _dailyQuote,
                            style: GoogleFonts.amiri(
                              color: titleColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  
                  // Footer
                  Column(
                    children: [
                      Text(
                        _version,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2027 جميع الحقوق محفوظة - أحمد جمال',
                        style: TextStyle(
                          color: mutedColor.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
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
