import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../../tasks/screens/tasks_screen.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> with WidgetsBindingObserver {
  // Permission statuses
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _exactAlarmStatus = PermissionStatus.denied;
  PermissionStatus _ignoreBatteryStatus = PermissionStatus.denied;
  PermissionStatus _overlayStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // تحديث الصلاحيات فور العودة للتطبيق من الإعدادات
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.status;
    final loc = await Permission.locationWhenInUse.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;
    final overlay = await Permission.systemAlertWindow.status;

    PermissionStatus alarm =
        PermissionStatus.granted; // Default for older android
    if (Platform.isAndroid) {
      alarm = await Permission.scheduleExactAlarm.status;
    }

    if (mounted) {
      setState(() {
        _notificationStatus = notif;
        _locationStatus = loc;
        _exactAlarmStatus = alarm;
        _ignoreBatteryStatus = battery;
        _overlayStatus = overlay;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    if (permission == Permission.ignoreBatteryOptimizations) {
      // محاولة الطلب المباشر أولاً
      final status = await permission.request();
      if (!status.isGranted) {
        // إذا لم يظهر الحوار، نفتح إعدادات التطبيق مباشرة
        // في شاومي، إعدادات البطارية موجودة داخل إعدادات التطبيق
        await openAppSettings();
      }
      // تحديث الحالة فوراً
      await _checkPermissions();
      return;
    }

    if (permission == Permission.systemAlertWindow) {
      // صلاحية الظهور فوق التطبيقات تحتاج فتح الإعدادات دائماً
      await permission.request();
      await _checkPermissions();
      return;
    }

    final status = await permission.request();
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
        const SnackBar(
          content: Text(
            "يرجى السماح بكافة الصلاحيات المطلوبة لضمان عمل الأذان والتنبيهات بدقة عالية.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save that we've finished onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // تفعيل الأذكار العائمة تلقائياً لو المستخدم وافق على الصلاحية
    if (_overlayStatus.isGranted) {
      final prefsService = NotificationPreferencesService();
      await prefsService.setFloatingDhikrEnabled(true);
    }

    AppNotificationService().init().catchError((Object error) {
      debugPrint("Notification init error: $error");
    });

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.security,
                size: 80,
                color: isDark ? Colors.tealAccent.shade400 : Colors.teal.shade800,
              ),
              const SizedBox(height: 20),
              Text(
                "إعداد التطبيق",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "عشان نقدر نفيدك بكل مميزات التطبيق، محتاجين تسمحلنا بالصلاحيات دي",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      title: "الإشعارات",
                      description: "لتلقي تنبيهات الأذان والأذكار في مواعيدها.",
                      icon: Icons.notifications_active,
                      status: _notificationStatus,
                      isDark: isDark,
                      onTap: () => _requestPermission(Permission.notification),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      title: "الموقع الجغرافي",
                      description:
                          "لحساب مواقيت الصلاة والقبلة بدقة لمكانك الحالي.",
                      icon: Icons.location_on,
                      status: _locationStatus,
                      isDark: isDark,
                      onTap: () =>
                          _requestPermission(Permission.locationWhenInUse),
                    ),
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: "المنبه الدقيق",
                        description:
                            "لضمان انطلاق صوت الأذان في الوقت المحدد تماماً.",
                        icon: Icons.alarm,
                        status: _exactAlarmStatus,
                        isDark: isDark,
                        onTap: () =>
                            _requestPermission(Permission.scheduleExactAlarm),
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: "إلغاء قيود البطارية",
                        description:
                            "لضمان استمرار عمل التنبيهات والأذكار دون توقف في الخلفية.",
                        icon: Icons.battery_charging_full,
                        status: _ignoreBatteryStatus,
                        isDark: isDark,
                        onTap: () => _requestPermission(
                            Permission.ignoreBatteryOptimizations),
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: "الظهور فوق التطبيقات",
                        description:
                            "لعرض الأذكار العائمة على الشاشة أثناء استخدامك للهاتف.",
                        icon: Icons.layers,
                        status: _overlayStatus,
                        isDark: isDark,
                        onTap: () =>
                            _requestPermission(Permission.systemAlertWindow),
                      ),
                      const SizedBox(height: 16),
                      _buildGuideCard(isDark),
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
                child: const Text(
                  "ابدأ الرحلة",
                  style: TextStyle(
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

  Widget _buildGuideCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withValues(alpha: 0.12)
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.orange.shade200,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 300;
          final button = TextButton(
            onPressed: _showLockGuideDialog,
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "كيف؟",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "تأمين التطبيق (Lock App)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.orange.shade200
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "اضغط هنا لتعرف كيف تمنع النظام من إغلاق الأذان تلقائياً.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: button,
                ),
              ],
            );
          }

          return Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "تأمين التطبيق (Lock App)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.orange.shade200
                            : Colors.orange.shade900,
                      ),
                    ),
                    Text(
                      "اضغط هنا لتعرف كيف تمنع النظام من إغلاق الأذان تلقائياً.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              button,
            ],
          );
        },
      ),
    );
  }

  void _showLockGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("كيفية قفل التطبيق في المهام"),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("1. افتح قائمة التطبيقات الأخيرة (المهام)."),
              Text("2. اضغط مطولاً على أيقونة تطبيق 'رفيق المسلم'."),
              Text("3. اضغط على علامة القفل (Lock) 🔒."),
              SizedBox(height: 10),
              Text(
                "ملاحظة: هذا يضمن بقاء الأذان والأذكار قيد العمل حتى لو قمت بتنظيف الرامات.",
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("فهمت")),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required PermissionStatus status,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bool isGranted = status.isGranted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? (isDark
                ? Colors.teal.withValues(alpha: 0.15)
                : const Color(0xFFE3F2FD))
            : (isDark ? const Color(0xFF161616) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? (isDark
                  ? Colors.tealAccent.withValues(alpha: 0.5)
                  : const Color(0xFF1565C0))
              : (isDark ? Colors.white12 : Colors.grey[300]!),
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 300;
          final actionWidget = !isGranted
              ? TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "تفعيل",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : Icon(
                  Icons.check_circle,
                  color: isDark ? Colors.tealAccent : Colors.teal,
                  size: 28,
                );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? (isDark
                                ? Colors.teal.withValues(alpha: 0.25)
                                : const Color(0xFFBBDEFB))
                            : (isDark ? Colors.white10 : Colors.grey[200]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isGranted
                            ? (isDark ? Colors.tealAccent : Colors.teal)
                            : (isDark ? Colors.white70 : Colors.grey[600]),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isGranted
                              ? (isDark
                                  ? Colors.tealAccent.shade100
                                  : Colors.teal[800])
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: actionWidget,
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted
                      ? (isDark
                          ? Colors.teal.withValues(alpha: 0.25)
                          : const Color(0xFFBBDEFB))
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isGranted
                      ? (isDark ? Colors.tealAccent : Colors.teal)
                      : (isDark ? Colors.white70 : Colors.grey[600]),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isGranted
                            ? (isDark
                                ? Colors.tealAccent.shade100
                                : Colors.teal[800])
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              actionWidget,
            ],
          );
        },
      ),
    );
  }
}
