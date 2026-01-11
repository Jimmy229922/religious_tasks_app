import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import '../constants/app_constants.dart';
import 'tasks_screen.dart';
import 'permissions_onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SplashScreen({super.key, required this.themeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingAndNavigate();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
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
    return const Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E5128), Color(0xFF43A047)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 1),
                  Column(
                    children: [
                      Icon(Icons.mosque, size: 100, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        kAppName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '\u062c\u0627\u0631\u064a\u0020\u062a\u062d\u0645\u064a\u0644\u0020\u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a\u002e\u002e\u002e\u0020\u064a\u0631\u062c\u0649\u0020\u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '\u0627\u062f\u0639\u0648\u0644\u064a\u0020\u0628\u0627\u0644\u062a\u064a\u0633\u064a\u0631',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    '\u00a9\u00202026\u0020\u062c\u0645\u064a\u0639\u0020\u0627\u0644\u062d\u0642\u0648\u0642\u0020\u0645\u062d\u0641\u0648\u0638\u0629\u0020-\u0020\u0623\u062d\u0645\u062f\u0020\u062c\u0645\u0627\u0644',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
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
