import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final minDelayFuture = Future.delayed(const Duration(milliseconds: 350));

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
        bool allGranted =
            await _areAllPermissionsGranted().catchError((e) => false);
        if (allGranted) {
          await prefs.setBool('onboarding_completed', true);
          _navigateToHome();
        } else {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const PermissionsOnboardingScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
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
    final checks = await Future.wait<bool>([
      Permission.notification.isGranted,
      Permission.locationWhenInUse.isGranted,
      if (Platform.isAndroid) Permission.scheduleExactAlarm.isGranted,
    ]);
    return checks.every((granted) => granted);
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
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = context.appBgGradient;
    final titleColor = isDark ? goldLight : const Color(0xFF0F3D3E);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF78350F);
    final mutedColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SplashLatticePainter(
                      color: gold.withValues(alpha: isDark ? 0.08 : 0.14),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            Container(
                              width: 152,
                              height: 152,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF0A241D)
                                    : Colors.white,
                                border: Border.all(
                                  color: gold,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.35 : 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: gold.withValues(alpha: 0.28),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  isDark
                                      ? 'assets/icon/app_icon_dark.jpg'
                                      : 'assets/icon/app_icon_light.jpg',
                                  fit: BoxFit.cover,
                                  cacheWidth: 456,
                                  cacheHeight: 456,
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
                                          color: Colors.black45,
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
                              style: GoogleFonts.cairo(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? goldLight : context.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'جاري تحميل البيانات... يرجى الانتظار',
                              style: GoogleFonts.cairo(
                                color: mutedColor,
                                fontSize: 12.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_dailyQuote.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? const [
                                            Color(0xFF0E211E),
                                            Color(0xFF0A171C),
                                          ]
                                        : const [
                                            Color(0xFFFFFDF8),
                                            Color(0xFFF8F0DB),
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: gold.withValues(
                                        alpha: isDark ? 0.5 : 0.7),
                                    width: 1.25,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? Colors.black : gold)
                                          .withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _dailyQuote,
                                  style: GoogleFonts.amiri(
                                    color: isDark
                                        ? goldLight
                                        : const Color(0xFF0F3D3E),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.6,
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
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2026 جميع الحقوق محفوظة - أحمد جمال',
                              style: GoogleFonts.cairo(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLatticePainter extends CustomPainter {
  final Color color;
  const _SplashLatticePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x <= size.width + step; x += step) {
      for (double y = 0; y <= size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - 9)
          ..lineTo(x + 9, y)
          ..lineTo(x, y + 9)
          ..lineTo(x - 9, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}
