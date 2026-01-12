import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../../tasks/screens/tasks_screen.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  // Permission statuses
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _exactAlarmStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.status;
    final loc = await Permission.locationWhenInUse.status;

    PermissionStatus alarm =
        PermissionStatus.granted; // Default for older android
    if (Platform.isAndroid) {
      // scheduleExactAlarm acts differently on 12+.
      // We usually check ignoreBatteryOptimizations or just request it if needed.
      // Actually scheduleExactAlarm permission status can be checked.
      alarm = await Permission.scheduleExactAlarm.status;
    }

    if (mounted) {
      setState(() {
        _notificationStatus = notif;
        _locationStatus = loc;
        _exactAlarmStatus = alarm;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    // Update state
    await _checkPermissions();

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showOpenSettingsDialog();
      }
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("محتاجين اذنك"),
        content: const Text(
            "تم رفض الصلاحية نهائياً. يرجى فتح الإعدادات وتفعيلها يدوياً لضمان عمل التطبيق."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("الإعدادات"),
          ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    // Check if all essential permissions are granted
    bool isAllGranted =
        _notificationStatus.isGranted && _locationStatus.isGranted;

    if (Platform.isAndroid) {
      // On Android 12+, we want exact alarm too, typically.
      // If it's not granted, we block.
      if (!_exactAlarmStatus.isGranted) {
        isAllGranted = false;
      }
    }

    if (!isAllGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "مينفعش نبدا من غير ما ناخد كل الصلاحيات عشان التطبيق يشتغل صح",
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save that we've finished onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => TasksScreen(themeProvider: themeProvider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.security, size: 80, color: Colors.teal.shade800),
              const SizedBox(height: 20),
              Text(
                "إعداد التطبيق",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "عشان نقدر نفيدك بكل مميزات التطبيق، محتاجين تسمحلنا بالصلاحيات دي",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      title: "الإشعارات",
                      description:
                          "عشان نقدر نبعتلك الأذان وتذكيرات الأوراد في وقتها.",
                      icon: Icons.notifications_active,
                      status: _notificationStatus,
                      onTap: () => _requestPermission(Permission.notification),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      title: "الموقع الجغرافي",
                      description:
                          "لتحديد مواقيت الصلاة واتجاه القبلة بدقة حسب مكانك.",
                      icon: Icons.location_on,
                      status: _locationStatus,
                      onTap: () =>
                          _requestPermission(Permission.locationWhenInUse),
                    ),
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: "المنبه الدقيق",
                        description:
                            "لضمان ان الأذان يشتغل في ميعاده بالظبط حتى لو الموبايل مقفول.",
                        icon: Icons.alarm,
                        status: _exactAlarmStatus,
                        onTap: () =>
                            _requestPermission(Permission.scheduleExactAlarm),
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _finishOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), // Blue
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "ابدأ الرحلة",
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    final bool isGranted = status.isGranted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isGranted ? const Color(0xFFE3F2FD) : Colors.grey[50], // Blue shade
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? const Color(0xFF1565C0) : Colors.grey[300]!,
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFFBBDEFB)
                  : Colors.grey[200], // Blue shade
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.teal : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isGranted ? Colors.teal[800] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isGranted)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "تفعيل",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.teal, size: 28),
        ],
      ),
    );
  }
}
