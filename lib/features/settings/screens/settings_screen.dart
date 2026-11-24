import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/constants/strings.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/services/backup_service.dart';
import 'package:religious_tasks_app/core/widgets/full_adhan_overlay_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/happiness_jar/screens/happiness_jar_screen.dart';
import 'package:religious_tasks_app/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color get _emerald => context.primaryColor;
  Color get _emeraldDark => context.primaryDarkColor;
  static const Color _gold = Color(0xFFD4AF37);

  static const List<Map<String, String>> _availableMoazzens = [
    {
      'id': 'afasy',
      'name': 'الشيخ مشاري راشد العفاسي',
      'desc': 'أذان عذب بصوت الشيخ مشاري العفاسي',
    },
    {
      'id': 'basit',
      'name': 'الشيخ عبد الباسط عبد الصمد',
      'desc': 'أذان خاشع بصوت الشيخ عبد الباسط',
    },
    {
      'id': 'minshawi',
      'name': 'الشيخ محمد صديق المنشاوي',
      'desc': 'أذان رصين بصوت الشيخ المنشاوي',
    },
    {
      'id': 'muaiqly',
      'name': 'الشيخ ماهر المعيقلي',
      'desc': 'أذان الحرم المكي بصوت الشيخ المعيقلي',
    },
    {
      'id': 'dosari',
      'name': 'الشيخ ياسر الدوسري',
      'desc': 'أذان مميز بصوت الشيخ ياسر الدوسري',
    },
    {
      'id': 'default',
      'name': 'الأذان الافتراضي',
      'desc': 'صوت الأذان الافتراضي للتطبيق',
    },
    {
      'id': 'system',
      'name': 'صوت النظام (المنبه)',
      'desc': 'نغمة التنبيه الافتراضية لجهازك',
    },
  ];

  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();

  Map<String, bool> adhanSettings = {
    'fajr': true,
    'sunrise': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  Map<String, int> prayerOffsets = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };
  NotificationPreferences _prefs = NotificationPreferences.defaults();
  AdhanSoundType _soundType = AdhanSoundType.full;
  String _selectedMoazzenId = 'system';
  bool _stopAdhanOnVolumeButton = false;
  bool _stopSalawatOnVolumeButton = false;
  bool _isPreviewPlaying = false;

  List<String> _customDhikrs = [];
  final TextEditingController _customDhikrController = TextEditingController();
  final ValueNotifier<Duration?> _remainingDhikrNotifier =
      ValueNotifier<Duration?>(null);
  Timer? _dhikrCountdownTimer;
  DateTime? _dhikrStartTime;
  bool _isApplyingAthkar = false;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  String _appVersion = "";

  String? _linkedGoogleEmail;
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startDhikrCountdownTimer();
  }

  @override
  void dispose() {
    _dhikrCountdownTimer?.cancel();
    _remainingDhikrNotifier.dispose();
    _customDhikrController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefsService.load();
    final sharedPrefs = await SharedPreferences.getInstance();
    final startTimeMillis =
        sharedPrefs.getInt(AppNotificationService.dhikrCycleStartTimeKey);
    final customDhikrsJson =
        sharedPrefs.getString(AppNotificationService.customDhikrKey);
    final List<String> customDhikrs = customDhikrsJson != null
        ? List<String>.from(jsonDecode(customDhikrsJson))
        : [];
    final packageInfo = await PackageInfo.fromPlatform();
    final email = await BackupService.getSavedGoogleAccount();
    final syncTime = await BackupService.getLastBackupFormattedTime();

    if (!mounted) return;

    setState(() {
      _prefs = prefs;
      adhanSettings = Map.from(prefs.adhanEnabled);
      prayerOffsets = Map.from(prefs.prayerOffsets);
      _soundType = prefs.adhanSoundType;
      _selectedMoazzenId = prefs.selectedMoazzenId;
      _stopAdhanOnVolumeButton = prefs.stopAdhanOnVolumeButton;
      _stopSalawatOnVolumeButton = prefs.stopSalawatOnVolumeButton;
      _customDhikrs = customDhikrs;
      _dhikrStartTime = startTimeMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(startTimeMillis)
          : null;
      _appVersion = packageInfo.version;
      _linkedGoogleEmail = email;
      _lastSyncTime = syncTime;
      _isLoading = false;
    });
  }

  void _startDhikrCountdownTimer() {
    _dhikrCountdownTimer?.cancel();
    _dhikrCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_prefs.hourlyDhikrEnabled || _dhikrStartTime == null) {
        if (_remainingDhikrNotifier.value != null) {
          _remainingDhikrNotifier.value = null;
        }
        return;
      }
      final now = DateTime.now();
      final diffSeconds = now.difference(_dhikrStartTime!).inSeconds;
      final intervalSeconds = _prefs.hourlyDhikrIntervalMinutes * 60;
      if (intervalSeconds <= 0) return;
      if (diffSeconds < 0) {
        _remainingDhikrNotifier.value =
            Duration(seconds: intervalSeconds + diffSeconds);
        return;
      }
      final elapsed = diffSeconds % intervalSeconds;
      _remainingDhikrNotifier.value =
          Duration(seconds: intervalSeconds - elapsed);
    });
  }

  String _formatCountdown(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final mins = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return QuranTextFormatter.toArabicDigits(
          "${twoDigits(duration.inHours)}:$mins:$secs");
    }
    return QuranTextFormatter.toArabicDigits("$mins:$secs");
  }

  void _showAthkarSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: GoogleFonts.cairo()),
      ),
    );
  }

  Future<void> _updateMorningReminder(bool value) async {
    setState(() {
      _prefs = _prefs.copyWith(morningAthkarReminderEnabled: value);
    });
    await _prefsService.setMorningAthkarReminderEnabled(value);
    await AppNotificationService().syncRecurringSchedules();
    _showAthkarSnack(
        value ? "تم تفعيل تذكير أذكار الصباح" : "تم تعطيل تذكير أذكار الصباح");
  }

  Future<void> _updateEveningReminder(bool value) async {
    setState(() {
      _prefs = _prefs.copyWith(eveningAthkarReminderEnabled: value);
    });
    await _prefsService.setEveningAthkarReminderEnabled(value);
    await AppNotificationService().syncRecurringSchedules();
    _showAthkarSnack(
        value ? "تم تفعيل تذكير أذكار المساء" : "تم تعطيل تذكير أذكار المساء");
  }

  Future<void> _updateSalawatEnabled(bool value) async {
    if (_isApplyingAthkar) return;
    setState(() {
      _isApplyingAthkar = true;
      _prefs = _prefs.copyWith(salawatReminderEnabled: value);
    });
    try {
      await _prefsService.setSalawatReminderEnabled(value);
      await AppNotificationService().scheduleSalawatNotifications(
        settings: _prefs,
        forceReschedule: true,
      );
      await _loadSettings();
      _showAthkarSnack(value
          ? "تم تفعيل التذكير بالصلاة على النبي ﷺ"
          : "تم إيقاف التذكير بالصلاة على النبي ﷺ");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  Future<void> _updateSalawatInterval(int minutes) async {
    if (_isApplyingAthkar) return;
    setState(() {
      _isApplyingAthkar = true;
      _prefs = _prefs.copyWith(salawatIntervalMinutes: minutes);
    });
    try {
      await _prefsService.setSalawatIntervalMinutes(minutes);
      await AppNotificationService().scheduleSalawatNotifications(
        settings: _prefs,
        forceReschedule: true,
      );
      await _loadSettings();
      _showAthkarSnack(
          "تم ضبط تكرار الصلاة على النبي كل ${QuranTextFormatter.toArabicDigits(minutes.toString())} دقيقة");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  Future<void> _updateHourlyDhikrEnabled(bool value) async {
    if (_isApplyingAthkar) return;
    setState(() {
      _isApplyingAthkar = true;
      _prefs = _prefs.copyWith(hourlyDhikrEnabled: value);
    });
    try {
      await _prefsService.setHourlyDhikrEnabled(value);
      await AppNotificationService().scheduleDhikrNotifications(
        settings: _prefs,
        forceReschedule: true,
      );
      await _loadSettings();
      _showAthkarSnack(
          value ? "تم تفعيل الذكر المتكرر" : "تم إيقاف الذكر المتكرر");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  Future<void> _updateHourlyDhikrInterval(int minutes) async {
    if (_isApplyingAthkar) return;
    setState(() {
      _isApplyingAthkar = true;
      _prefs = _prefs.copyWith(hourlyDhikrIntervalMinutes: minutes);
    });
    try {
      await _prefsService.setHourlyDhikrIntervalMinutes(minutes);
      await AppNotificationService().scheduleDhikrNotifications(
        settings: _prefs,
        forceReschedule: true,
      );
      await _loadSettings();
      _showAthkarSnack(
          "تم ضبط الذكر المتكرر كل ${QuranTextFormatter.toArabicDigits(minutes.toString())} دقيقة");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  Future<void> _updateFloatingDhikr(bool value) async {
    if (_isApplyingAthkar) return;
    setState(() => _isApplyingAthkar = true);
    try {
      if (value) {
        final granted =
            await AppNotificationService().ensureFloatingDhikrPermission();
        if (!granted) {
          _showAthkarSnack("يرجى تفعيل صلاحية الظهور فوق التطبيقات");
          return;
        }
      } else {
        await AppNotificationService().closeDhikrOverlay();
      }
      final updated = _prefs.copyWith(floatingDhikrEnabled: value);
      setState(() => _prefs = updated);
      await _prefsService.setFloatingDhikrEnabled(value);
      await AppNotificationService().scheduleDhikrNotifications(
        settings: updated,
      );
      _showAthkarSnack(
          value ? "تم تفعيل الأذكار العائمة" : "تم تعطيل الأذكار العائمة");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  Future<void> _updateHappinessJarEnabled(bool value) async {
    if (_isApplyingAthkar) return;
    setState(() {
      _isApplyingAthkar = true;
      _prefs = _prefs.copyWith(happinessJarEnabled: value);
    });
    try {
      await _prefsService.setHappinessJarEnabled(value);
      await AppNotificationService().scheduleHappinessJarNotifications(
        settings: _prefs,
      );
      _showAthkarSnack(value
          ? "تم تفعيل إشعار برطمان السعادة اليومي 💛"
          : "تم إيقاف إشعار برطمان السعادة اليومي");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  Future<void> _pickHappinessJarTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _prefs.happinessJarHour,
        minute: _prefs.happinessJarMinute,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _isApplyingAthkar = true;
      _prefs = _prefs.copyWith(
        happinessJarEnabled: true,
        happinessJarHour: picked.hour,
        happinessJarMinute: picked.minute,
      );
    });
    try {
      await _prefsService.setHappinessJarEnabled(true);
      await _prefsService.setHappinessJarTime(picked.hour, picked.minute);
      await AppNotificationService().scheduleHappinessJarNotifications(
        settings: _prefs,
      );
      _showAthkarSnack("تم ضبط موعد رسالة برطمان السعادة بنجاح");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  String _formatHappinessTime(int hour, int minute) {
    final isPm = hour >= 12;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return QuranTextFormatter.toArabicDigits("$h:$m ${isPm ? 'م' : 'ص'}");
  }

  Future<void> _addCustomDhikr() async {
    final text = _customDhikrController.text.trim();
    if (text.isEmpty) return;
    final sharedPrefs = await SharedPreferences.getInstance();
    final updated = [..._customDhikrs, text];
    await sharedPrefs.setString(
        AppNotificationService.customDhikrKey, jsonEncode(updated));
    _customDhikrController.clear();
    await _loadSettings();
    await AppNotificationService().scheduleDhikrNotifications(
      settings: _prefs,
      forceReschedule: true,
    );
    _showAthkarSnack("تمت إضافة الذكر المخصص بنجاح");
  }

  Future<void> _deleteCustomDhikr(int index) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_customDhikrs)..removeAt(index);
    await sharedPrefs.setString(
        AppNotificationService.customDhikrKey, jsonEncode(updated));
    await _loadSettings();
    await AppNotificationService().scheduleDhikrNotifications(
      settings: _prefs,
      forceReschedule: true,
    );
    _showAthkarSnack("تم حذف الذكر المخصص");
  }

  Future<void> _rescheduleAllAthkarNotifications() async {
    if (_isApplyingAthkar) return;
    setState(() => _isApplyingAthkar = true);
    try {
      await AppNotificationService().syncRecurringSchedules();
      await _loadSettings();
      _showAthkarSnack("تمت إعادة جدولة جميع تنبيهات الأذكار بنجاح");
    } finally {
      if (mounted) setState(() => _isApplyingAthkar = false);
    }
  }

  void _updateSoundType(AdhanSoundType type) async {
    setState(() {
      _soundType = type;
    });
    await _prefsService.setAdhanSoundType(type);
    _reschedulePrayers();
  }

  Future<void> _updateSelectedMoazzen(String moazzenId) async {
    setState(() {
      _selectedMoazzenId = moazzenId;
    });
    await _prefsService.setSelectedMoazzenId(moazzenId);
    _reschedulePrayers();
    if (!mounted) return;
    final moazzen = _availableMoazzens.firstWhere(
      (m) => m['id'] == moazzenId,
      orElse: () => _availableMoazzens.last,
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          "تم اختيار صوت: ${moazzen['name']}",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _previewMoazzen(String moazzenId) async {
    await _prefsService.setSelectedMoazzenId(moazzenId);
    setState(() {
      _selectedMoazzenId = moazzenId;
      _isPreviewPlaying = true;
    });
    _reschedulePrayers();
    await AppNotificationService().testAdhanNotification('fajr', AppStrings.fajr);
  }

  Future<void> _stopPreviewSound() async {
    await AppNotificationService().stopAdhanAudio();
    if (mounted) {
      setState(() {
        _isPreviewPlaying = false;
      });
    }
  }

  Future<void> _updateStopAdhanOnVolume(bool value) async {
    setState(() {
      _stopAdhanOnVolumeButton = value;
    });
    await _prefsService.setStopAdhanOnVolumeButton(value);
  }

  Future<void> _updateStopSalawatOnVolume(bool value) async {
    setState(() {
      _stopSalawatOnVolumeButton = value;
    });
    await _prefsService.setStopSalawatOnVolumeButton(value);
  }

  void _reschedulePrayers() async {
    final tasksViewModel = Provider.of<TasksViewModel>(context, listen: false);
    if (tasksViewModel.prayerTimes != null &&
        tasksViewModel.tomorrowPrayerTimes != null) {
      await AppNotificationService().schedulePrayerNotifications(
        today: tasksViewModel.prayerTimes!,
        tomorrow: tasksViewModel.tomorrowPrayerTimes!,
      );
    }
  }

  void _updateSetting(String key, bool value) async {
    setState(() {
      adhanSettings[key] = value;
    });

    await _prefsService.setAdhanEnabled(key, value);
    _reschedulePrayers();
  }

  void _updateOffset(String key, int value) async {
    final safeValue = value.clamp(-60, 60);
    setState(() {
      prayerOffsets[key] = safeValue;
    });

    await _prefsService.setPrayerOffset(key, safeValue);

    if (mounted) {
      final tasksViewModel =
          Provider.of<TasksViewModel>(context, listen: false);
      await tasksViewModel.refreshLocation();
    }
    _reschedulePrayers();
  }

  void _showRestoreDialog() {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("استعادة نسخة احتياطية"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "الصق نص النسخة الاحتياطية لدمج مفاتيحها المعتمدة مع بيانات التطبيق الحالية:",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "الصق البيانات هنا...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await BackupService.restoreBackupData(controller.text.trim());
              if (ctx.mounted && mounted) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "تم دمج البيانات بنجاح. أعد فتح التطبيق لتحديث جميع الشاشات."
                        : "عذراً، نص النسخة الاحتياطية غير صالح"),
                  ),
                );
              }
            },
            child: const Text("استعادة"),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoogleCloudBackupDialog() async {
    final email = await BackupService.selectGoogleAccount();
    if (!mounted) return;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر توثيق حساب Google. تحقق من إعداد تسجيل الدخول ثم حاول مجددًا.',
          ),
        ),
      );
      return;
    }

    final success = await BackupService.uploadToCloud(email);
    await _loadSettings();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم توثيق الحساب ورفع النسخة الاحتياطية بأمان.'
              : 'تم توثيق الحساب، لكن تعذر رفع النسخة الاحتياطية.',
        ),
      ),
    );
  }

  Future<void> _deleteAuthenticatedCloudData() async {
    final email = _linkedGoogleEmail;
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف البيانات السحابية'),
        content: const Text(
          'سيتم حذف النسخة الاحتياطية المرتبطة بحسابك الحالي نهائيًا، '
          'ثم تسجيل الخروج من المزامنة السحابية. لن تُحذف بيانات الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deleted = await BackupService.deleteCloudBackup(email);
    await _loadSettings();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'تم حذف بياناتك السحابية وتسجيل الخروج.'
              : 'تعذر حذف البيانات السحابية. لم يتم اعتبار الطلب مكتملًا.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        appBar: AppBar(
          title: Text(
            AppStrings.settings,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? const Color(0xFFFDE68A) : Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? context.appHeaderBg : _emerald,
          foregroundColor: isDark ? const Color(0xFFFDE68A) : Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _gold,
            indicatorWeight: 3,
            labelColor: isDark ? const Color(0xFFFDE68A) : Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.mosque_rounded, size: 20),
                text: "الصلاة والمواقيت",
              ),
              Tab(
                icon: Icon(Icons.notifications_active_rounded, size: 20),
                text: "الأذكار والتنبيهات",
              ),
              Tab(
                icon: Icon(Icons.palette_rounded, size: 20),
                text: "المظهر والسمات",
              ),
              Tab(
                icon: Icon(Icons.cloud_sync_rounded, size: 20),
                text: "الحساب والمزامنة",
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Directionality(
                textDirection: TextDirection.rtl,
                child: TabBarView(
                  children: [
                    _buildPrayerTab(),
                    _buildAthkarTab(),
                    _buildThemeTab(),
                    _buildAccountTab(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  // TAB 1: Prayer, Sheikh Voice, Volume Stop Controls & Location (Redesigned)
  Widget _buildPrayerTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksViewModel = context.watch<TasksViewModel>();
    final currentMoazzen = _availableMoazzens.firstWhere(
      (m) => m['id'] == _selectedMoazzenId,
      orElse: () => _availableMoazzens.last,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Hero Location Card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0E2926), Color(0xFF132234)]
                  : [_emerald, _emeraldDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? Colors.black : _emerald).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.amberAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الموقع الجغرافي للمواقيت",
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tasksViewModel.locationName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isRefreshingLocation
                    ? null
                    : () async {
                        setState(() => _isRefreshingLocation = true);
                        await tasksViewModel.refreshLocation();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                "تم تحديث الموقع ومواقيت الصلاة بنجاح",
                                style: GoogleFonts.cairo(),
                              ),
                            ),
                          );
                          setState(() => _isRefreshingLocation = false);
                        }
                      },
                icon: _isRefreshingLocation
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  "تحديث",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Adhan Sound Type & Sheikh Voice Picker Card
        _buildSectionHeader(
          Icons.record_voice_over_rounded,
          "صوت الأذان واختيار الشيخ",
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _emerald.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "نوع التنبيه عند دخول الوقت",
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSoundTypeOption(
                    isDark: isDark,
                    type: AdhanSoundType.full,
                    label: "أذان كامل",
                    icon: Icons.mosque_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildSoundTypeOption(
                    isDark: isDark,
                    type: AdhanSoundType.short,
                    label: "تنبيه قصير",
                    icon: Icons.notifications_active_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildSoundTypeOption(
                    isDark: isDark,
                    type: AdhanSoundType.none,
                    label: "صامت",
                    icon: Icons.notifications_off_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "صوت الشيخ لوقت الأذان",
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_soundType != AdhanSoundType.full)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "يعمل مع الأذان الكامل",
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.amberAccent
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showMoazzenPickerSheet(isDark),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2B3C)
                        : const Color(0xFFF6FAF9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _emerald.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: _emerald,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentMoazzen['name']!,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentMoazzen['desc']!,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _emerald,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMoazzenPickerSheet(isDark),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(
                        "اختيار صوت الشيخ",
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.tealAccent : _emerald,
                        side: BorderSide(
                          color: _emerald.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPreviewPlaying
                          ? _stopPreviewSound
                          : () => _previewMoazzen(_selectedMoazzenId),
                      icon: Icon(
                        _isPreviewPlaying
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isPreviewPlaying ? "إيقاف الصوت" : "معاينة الصوت",
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isPreviewPlaying ? Colors.redAccent : _emerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Volume-Button Quick Stop Card (2 Dedicated Switches)
        _buildSectionHeader(
          Icons.volume_off_rounded,
          "الإيقاف السريع بأزرار الصوت",
          badgeText: "ميزة ذكية",
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.35 : 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 18,
                      color: isDark ? Colors.amberAccent : _emerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "عند تفعيل الخيار، الضغط على زر رفع أو خفض الصوت يفصل التنبيه تماماً فوراً.",
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : _emeraldDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildVolumeStopSwitchTile(
                isDark: isDark,
                icon: Icons.mosque_rounded,
                iconColor: _emerald,
                title: "إيقاف الأذان بأزرار الصوت",
                subtitle: _stopAdhanOnVolumeButton
                    ? "مُفعّل • زر رفع أو خفض الصوت يفصل الأذان فوراً"
                    : "معطّل • أزرار الصوت تتحكم في مستوى الصوت فقط",
                value: _stopAdhanOnVolumeButton,
                onChanged: _updateStopAdhanOnVolume,
              ),
              Divider(
                height: 20,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              _buildVolumeStopSwitchTile(
                isDark: isDark,
                icon: Icons.favorite_rounded,
                iconColor: _gold,
                title: "إيقاف الصلاة على النبي بأزرار الصوت",
                subtitle: _stopSalawatOnVolumeButton
                    ? "مُفعّل • زر رفع أو خفض الصوت يفصل التذكير فوراً"
                    : "معطّل • أزرار الصوت تتحكم في مستوى الصوت فقط",
                value: _stopSalawatOnVolumeButton,
                onChanged: _updateStopSalawatOnVolume,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. Prayer Alerts & Manual Time Adjustments
        _buildSectionHeader(
          Icons.access_time_filled_rounded,
          "الصلوات الخمس والتعديل اليدوي للمواقيت",
        ),
        _buildPrayerCard(
          keyName: 'fajr',
          title: AppStrings.fajr,
          prayer: Prayer.fajr,
          icon: Icons.wb_twilight_rounded,
          accent: const Color(0xFF3B82F6),
          tasksVm: tasksViewModel,
          isDark: isDark,
        ),
        _buildPrayerCard(
          keyName: 'sunrise',
          title: AppStrings.sunrise,
          prayer: Prayer.sunrise,
          icon: Icons.wb_sunny_outlined,
          accent: const Color(0xFFF59E0B),
          tasksVm: tasksViewModel,
          isDark: isDark,
          isAdhanSupported: false,
        ),
        _buildPrayerCard(
          keyName: 'dhuhr',
          title: AppStrings.dhuhr,
          prayer: Prayer.dhuhr,
          icon: Icons.wb_sunny_rounded,
          accent: const Color(0xFFEAB308),
          tasksVm: tasksViewModel,
          isDark: isDark,
        ),
        _buildPrayerCard(
          keyName: 'asr',
          title: AppStrings.asr,
          prayer: Prayer.asr,
          icon: Icons.light_mode_rounded,
          accent: const Color(0xFFEA580C),
          tasksVm: tasksViewModel,
          isDark: isDark,
        ),
        _buildPrayerCard(
          keyName: 'maghrib',
          title: AppStrings.maghrib,
          prayer: Prayer.maghrib,
          icon: Icons.nights_stay_outlined,
          accent: const Color(0xFFEC4899),
          tasksVm: tasksViewModel,
          isDark: isDark,
        ),
        _buildPrayerCard(
          keyName: 'isha',
          title: AppStrings.isha,
          prayer: Prayer.isha,
          icon: Icons.bedtime_rounded,
          accent: const Color(0xFF6366F1),
          tasksVm: tasksViewModel,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSoundTypeOption({
    required bool isDark,
    required AdhanSoundType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _soundType == type;
    return Expanded(
      child: InkWell(
        onTap: () => _updateSoundType(type),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? _emerald
                : (isDark ? const Color(0xFF1E2B3C) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _gold : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : _emerald),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeStopSwitchTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: value
                      ? (isDark ? Colors.tealAccent : _emerald)
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          activeTrackColor: _emerald,
          activeThumbColor: Colors.white,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showMoazzenPickerSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D2B) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _emerald.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.record_voice_over_rounded,
                              color: _emerald,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "اختر صوت الشيخ لوقت الأذان",
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isPreviewPlaying)
                            TextButton.icon(
                              onPressed: () async {
                                await _stopPreviewSound();
                                setSheetState(() {});
                              },
                              icon: const Icon(
                                Icons.stop_circle_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              label: Text(
                                "إيقاف",
                                style: GoogleFonts.cairo(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: _availableMoazzens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = _availableMoazzens[index];
                          final id = item['id']!;
                          final isSelected = _selectedMoazzenId == id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await _updateSelectedMoazzen(id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _emerald.withValues(alpha: 0.14)
                                    : (isDark
                                        ? const Color(0xFF1B2738)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? _emerald
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? _emerald
                                        : (isDark
                                            ? Colors.white38
                                            : Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name']!,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          item['desc']!,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "استماع للمعاينة",
                                    icon: Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: isSelected ? _emerald : _gold,
                                      size: 28,
                                    ),
                                    onPressed: () async {
                                      await _previewMoazzen(id);
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrayerCard({
    required String keyName,
    required String title,
    required Prayer prayer,
    required IconData icon,
    required Color accent,
    required TasksViewModel tasksVm,
    required bool isDark,
    bool isAdhanSupported = true,
  }) {
    final isEnabled = adhanSettings[keyName] ?? false;
    final offset = prayerOffsets[keyName] ?? 0;
    final time = tasksVm.prayerTimes?.timeForPrayer(prayer);
    final formattedTime = time != null
        ? QuranTextFormatter.toArabicDigits(
            intl.DateFormat.jm('ar').format(time),
          )
        : "--:--";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled
              ? accent.withValues(alpha: isDark ? 0.4 : 0.25)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formattedTime,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : _emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isAdhanSupported
                            ? (isEnabled
                                ? "الأذان والتنبيه مُفعّل"
                                : "التنبيه معطّل")
                            : (isEnabled
                                ? "إشعار الشروق مُفعّل"
                                : "وقت الشروق للعرض فقط"),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: isEnabled
                              ? (isDark ? Colors.tealAccent : _emerald)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdhanSupported)
                  IconButton(
                    tooltip: "تجربة صوت $title",
                    onPressed: () {
                      AppNotificationService().testAdhanNotification(
                        keyName,
                        title,
                      );
                    },
                    icon: Icon(
                      Icons.play_circle_outline_rounded,
                      color: isEnabled ? _emerald : Colors.grey,
                    ),
                  ),
                Switch.adaptive(
                  value: isEnabled,
                  activeTrackColor: _emerald,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => _updateSetting(keyName, val),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2B3C)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "تعديل يدوي (بالدقائق)",
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (offset != 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        onTap: () => _updateOffset(keyName, 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Text(
                          "تصفير",
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _emerald,
                          ),
                        ),
                      ),
                    ),
                  _buildOffsetButton(keyName, -1),
                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      offset > 0
                          ? "+${QuranTextFormatter.toArabicDigits(offset.toString())} د"
                          : "${QuranTextFormatter.toArabicDigits(offset.toString())} د",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: offset == 0
                            ? (isDark ? Colors.white60 : Colors.grey.shade700)
                            : _emerald,
                      ),
                    ),
                  ),
                  _buildOffsetButton(keyName, 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: Athkar & Notifications (Redesigned Full Control Center)
  Widget _buildAthkarTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = [
      _prefs.morningAthkarReminderEnabled,
      _prefs.eveningAthkarReminderEnabled,
      _prefs.salawatReminderEnabled,
      _prefs.hourlyDhikrEnabled,
      _prefs.floatingDhikrEnabled,
    ].where((e) => e).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Hero Summary Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0E2926), Color(0xFF132234)]
                  : [_emerald, _emeraldDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? Colors.black : _emerald).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.amberAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "مركز الأذكار والتنبيهات",
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${QuranTextFormatter.toArabicDigits(activeCount.toString())} من ${QuranTextFormatter.toArabicDigits('5')} منبهات نشطة حالياً",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isApplyingAthkar
                    ? null
                    : _rescheduleAllAthkarNotifications,
                icon: _isApplyingAthkar
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  "تحديث",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Morning & Evening Athkar
        _buildSectionHeader(
          Icons.wb_twilight_rounded,
          "أذكار الصباح والمساء اليومية",
        ),
        _buildAthkarToggleCard(
          isDark: isDark,
          icon: Icons.wb_sunny_rounded,
          accent: const Color(0xFFD97706),
          title: "أذكار الصباح",
          subtitle: "تنبيه يومي ثابت في وقت الصباح لبدء يومك بالذكر",
          value: _prefs.morningAthkarReminderEnabled,
          onChanged: _updateMorningReminder,
        ),
        _buildAthkarToggleCard(
          isDark: isDark,
          icon: Icons.nights_stay_rounded,
          accent: const Color(0xFF6366F1),
          title: "أذكار المساء",
          subtitle: "تنبيه يومي ثابت في وقت المساء لتحصين نفسك",
          value: _prefs.eveningAthkarReminderEnabled,
          onChanged: _updateEveningReminder,
        ),

        const SizedBox(height: 14),

        // 3. Salawat Reminder Card
        _buildSectionHeader(
          Icons.favorite_rounded,
          "التذكير الدوري بالصلاة على النبي ﷺ",
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _prefs.salawatReminderEnabled
                  ? _emerald.withValues(alpha: isDark ? 0.45 : 0.28)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      color: isDark ? Colors.tealAccent : _emerald,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "الصلاة على النبي ﷺ",
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _prefs.salawatReminderEnabled
                              ? "يعمل كل ${QuranTextFormatter.toArabicDigits(_prefs.salawatIntervalMinutes.toString())} دقيقة"
                              : "التنبيه الصوتي متوقف حالياً",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: _prefs.salawatReminderEnabled
                                ? (isDark ? Colors.tealAccent : _emerald)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _prefs.salawatReminderEnabled,
                    activeTrackColor: _emerald,
                    activeThumbColor: Colors.white,
                    onChanged:
                        _isApplyingAthkar ? null : _updateSalawatEnabled,
                  ),
                ],
              ),
              if (_prefs.salawatReminderEnabled) ...[
                const SizedBox(height: 12),
                Text(
                  "الفاصل الزمني للتكرار:",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NotificationPreferencesService
                      .salawatIntervalOptions
                      .map((mins) {
                    final selected = _prefs.salawatIntervalMinutes == mins;
                    return ChoiceChip(
                      label: Text(
                        "كل ${QuranTextFormatter.toArabicDigits(mins.toString())} د",
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: selected,
                      selectedColor: _emerald,
                      backgroundColor: isDark
                          ? const Color(0xFF1F2D3E)
                          : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: selected
                            ? _emerald
                            : (isDark
                                ? Colors.white12
                                : Colors.grey.shade300),
                      ),
                      showCheckmark: false,
                      onSelected: _isApplyingAthkar
                          ? null
                          : (_) => _updateSalawatInterval(mins),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isApplyingAthkar
                            ? null
                            : () async {
                                await AppNotificationService().stopAdhanAudio();
                                _showAthkarSnack("تم إيقاف الصوت الجاري");
                              },
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: Text(
                          "إيقاف الصوت",
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isApplyingAthkar
                            ? null
                            : () async {
                                await AppNotificationService()
                                    .testSalawatNotification();
                                _showAthkarSnack(
                                    "تم إرسال تجربة الصلاة على النبي ﷺ");
                              },
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: Text(
                          "تجربة الصوت",
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emerald,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_stopSalawatOnVolumeButton) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volume_off_rounded,
                            size: 16,
                            color: isDark ? Colors.tealAccent : _emerald),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "الإيقاف السريع بأزرار الصوت مُفعّل (من تبويب الصلاة والمواقيت)",
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: isDark ? Colors.tealAccent : _emeraldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. Recurring Dhikr & Floating Overlay
        _buildSectionHeader(
          Icons.notifications_active_rounded,
          "الذكر المتكرر والأذكار العائمة",
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _prefs.hourlyDhikrEnabled
                  ? const Color(0xFF0284C7)
                      .withValues(alpha: isDark ? 0.45 : 0.25)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.timer_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "التذكير المتكرر بالأذكار",
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _prefs.hourlyDhikrEnabled
                              ? "تنبيه كل ${QuranTextFormatter.toArabicDigits(_prefs.hourlyDhikrIntervalMinutes.toString())} دقيقة بالأذكار والأدعية"
                              : "معطّل حالياً",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: _prefs.hourlyDhikrEnabled
                                ? const Color(0xFF0284C7)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _prefs.hourlyDhikrEnabled,
                    activeTrackColor: const Color(0xFF0284C7),
                    activeThumbColor: Colors.white,
                    onChanged: _isApplyingAthkar
                        ? null
                        : _updateHourlyDhikrEnabled,
                  ),
                ],
              ),
              if (_prefs.hourlyDhikrEnabled) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NotificationPreferencesService.dhikrIntervalOptions
                      .map((mins) {
                    final selected = _prefs.hourlyDhikrIntervalMinutes == mins;
                    return ChoiceChip(
                      label: Text(
                        "كل ${QuranTextFormatter.toArabicDigits(mins.toString())} د",
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: isDark
                          ? const Color(0xFF1F2D3E)
                          : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF0284C7)
                            : (isDark
                                ? Colors.white12
                                : Colors.grey.shade300),
                      ),
                      showCheckmark: false,
                      onSelected: _isApplyingAthkar
                          ? null
                          : (_) => _updateHourlyDhikrInterval(mins),
                    );
                  }).toList(),
                ),
                ValueListenableBuilder<Duration?>(
                  valueListenable: _remainingDhikrNotifier,
                  builder: (context, remaining, _) {
                    if (remaining == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7)
                            .withValues(alpha: isDark ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              const Color(0xFF0284C7).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_bottom_rounded,
                              size: 18, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "التذكير القادم خلال:",
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatCountdown(remaining),
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.lightBlueAccent
                                  : const Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isApplyingAthkar
                        ? null
                        : () async {
                            await AppNotificationService()
                                .testDhikrNotification();
                            _showAthkarSnack("تم إرسال إشعار ذكر تجريبي");
                          },
                    icon: const Icon(Icons.notifications_none_rounded, size: 18),
                    label: Text(
                      "تجربة إشعار ذكر الآن",
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: BorderSide(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildAthkarToggleCard(
          isDark: isDark,
          icon: Icons.layers_rounded,
          accent: const Color(0xFF7C3AED),
          title: "الأذكار العائمة فوق التطبيقات",
          subtitle: "إظهار نافذة ذكر لطيفة تطفو على الشاشة بشكل دوري",
          value: _prefs.floatingDhikrEnabled,
          onChanged: _updateFloatingDhikr,
        ),

        const SizedBox(height: 18),

        // 4.5 Happiness Jar Daily Notification Card
        _buildSectionHeader(
          Icons.card_giftcard_rounded,
          "برطمان السعادة اليومي 💛",
          badgeText: "جديد",
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _prefs.happinessJarEnabled
                  ? const Color(0xFFD97706)
                      .withValues(alpha: isDark ? 0.45 : 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "رسالة سعادة يومية للجميع",
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _prefs.happinessJarEnabled
                              ? "تصل يومياً الساعة ${_formatHappinessTime(_prefs.happinessJarHour, _prefs.happinessJarMinute)}"
                              : "معطّل حالياً",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: _prefs.happinessJarEnabled
                                ? const Color(0xFFD97706)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _prefs.happinessJarEnabled,
                    activeTrackColor: const Color(0xFFD97706),
                    activeThumbColor: Colors.white,
                    onChanged: _isApplyingAthkar
                        ? null
                        : _updateHappinessJarEnabled,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isApplyingAthkar ? null : _pickHappinessJarTime,
                      icon: const Icon(Icons.access_time_rounded, size: 17),
                      label: Text(
                        "الموعد (${_formatHappinessTime(_prefs.happinessJarHour, _prefs.happinessJarMinute)})",
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: BorderSide(
                          color:
                              const Color(0xFFD97706).withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HappinessJarScreen()),
                      ).then((_) => _loadSettings()),
                      icon: const Icon(Icons.card_giftcard_rounded, size: 17),
                      label: Text(
                        "فتح البرطمان",
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 5. Custom Dhikrs
        _buildSectionHeader(
          Icons.bookmark_add_rounded,
          "أذكارك المخصصة (${QuranTextFormatter.toArabicDigits(_customDhikrs.length.toString())})",
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customDhikrController,
                      style: GoogleFonts.cairo(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: "أضف ذكراً أو دعاءً مخصصاً ليظهر في الإشعارات...",
                        hintStyle: GoogleFonts.cairo(fontSize: 12),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E2B3C)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addCustomDhikr,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (_customDhikrs.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...List.generate(_customDhikrs.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D2A3A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_rounded,
                            size: 16,
                            color: isDark ? Colors.amberAccent : _gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _customDhikrs[index],
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          tooltip: "حذف",
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteCustomDhikr(index),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 6. Advanced Diagnostics & Overlay Preview Shortcut
        _buildSectionHeader(
          Icons.build_circle_rounded,
          "التشخيص المتقدم وتجربة شاشة الأذان",
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _emerald.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mosque_rounded,
                      color: isDark ? Colors.tealAccent : _emerald),
                ),
                title: Text(
                  "تجربة شاشة الأذان الفاخرة الكاملة",
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "معاينة شاشة الأذان التي تظهر وقت دخول الصلاة",
                  style: GoogleFonts.cairo(fontSize: 11.5),
                ),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const FullAdhanOverlayDialog(
                      prayerName: "العَصْر",
                      prayerKey: "asr",
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: Color(0xFFB45309)),
                ),
                title: Text(
                  "مركز تشخيص الإشعارات والصلاحيات",
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "فحص أذونات النظام والبطارية واختبارات الإشعارات المفصلة",
                  style: GoogleFonts.cairo(fontSize: 11.5),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ).then((_) => _loadSettings());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAthkarToggleCard({
    required bool isDark,
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? accent.withValues(alpha: isDark ? 0.45 : 0.28)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: accent,
            activeThumbColor: Colors.white,
            onChanged: _isApplyingAthkar ? null : onChanged,
          ),
        ],
      ),
    );
  }

  // TAB 3: Appearance & Themes (Redesigned Theme Studio)
  Widget _buildThemeTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentHour = DateTime.now().hour;
    final activeSeed = themeProvider.getDynamicSeedColor(currentHour);
    final isDynamic = themeProvider.appThemeMode == AppThemeMode.dynamic;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Live Appearance Preview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                activeSeed,
                Color.lerp(activeSeed, Colors.black, 0.35) ?? activeSeed,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _gold.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: activeSeed.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.palette_rounded,
                            color: Colors.amberAccent, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          "معاينة حية للمظهر",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isDynamic
                        ? themeProvider.getDynamicPhaseLabel(currentHour)
                        : themeProvider.accentColor.label,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? (themeProvider.useOledBlack
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF172231))
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: activeSeed, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "نموذج عرض النصوص والبطاقات",
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾",
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: activeSeed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Theme Mode Selector Cards (2x2 Grid)
        _buildSectionHeader(Icons.brightness_6_rounded, "نمط الإضاءة والمظهر"),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.48,
          children: [
            _buildThemeModeTile(
              themeProvider: themeProvider,
              mode: AppThemeMode.light,
              title: "فاتح",
              subtitle: "مريح للقراءة نهاراً",
              icon: Icons.light_mode_rounded,
              iconColor: const Color(0xFFD97706),
              isDark: isDark,
              activeSeed: activeSeed,
            ),
            _buildThemeModeTile(
              themeProvider: themeProvider,
              mode: AppThemeMode.dark,
              title: "داكن",
              subtitle: "مريح للعين ليلاً",
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF6366F1),
              isDark: isDark,
              activeSeed: activeSeed,
            ),
            _buildThemeModeTile(
              themeProvider: themeProvider,
              mode: AppThemeMode.system,
              title: "حسب النظام",
              subtitle: "يتبع وضع الجهاز تلقائياً",
              icon: Icons.phone_android_rounded,
              iconColor: _emerald,
              isDark: isDark,
              activeSeed: activeSeed,
            ),
            _buildThemeModeTile(
              themeProvider: themeProvider,
              mode: AppThemeMode.dynamic,
              title: "تفاعلي مع الصلاة",
              subtitle: "يتلون تلقائياً مع أوقات اليوم",
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFFEA580C),
              isDark: isDark,
              activeSeed: activeSeed,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. Accent Color Palette Picker
        _buildSectionHeader(Icons.color_lens_rounded, "اللون الرئيسي والهوية"),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDynamic)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "الوضع التفاعلي يحدد اللون تلقائياً حسب وقت الصلاة، واختر أي لون أدناه ليتم تفعيله في باقي الأوضاع.",
                          style: GoogleFonts.cairo(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppAccentColor.values.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, idx) {
                  final accent = AppAccentColor.values[idx];
                  final chipColor = accent.colorFor(isDark);
                  final selected = themeProvider.accentColor == accent;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider.setAccentColor(accent);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? chipColor.withValues(alpha: isDark ? 0.24 : 0.14)
                            : (isDark
                                ? context.appCardGradient.first
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? chipColor
                              : (isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300),
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: chipColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: selected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: isDark
                                        ? const Color(0xFF041D16)
                                        : Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            accent.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. Visual Comfort & Text Scaling
        _buildSectionHeader(Icons.text_fields_rounded, "حجم الخط والراحة البصرية"),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.format_size_rounded, color: activeSeed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "حجم الخط العام في التطبيق",
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "${QuranTextFormatter.toArabicDigits((themeProvider.textScaleFactor * 100).round().toString())}٪",
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: activeSeed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  (0.92, "صغير"),
                  (1.0, "قياسي"),
                  (1.08, "كبير"),
                  (1.16, "أكبر"),
                ].map((option) {
                  final scale = option.$1;
                  final label = option.$2;
                  final selected =
                      (themeProvider.textScaleFactor - scale).abs() < 0.02;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => themeProvider.setTextScaleFactor(scale),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? activeSeed
                                : (isDark
                                    ? const Color(0xFF1F2D3E)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: activeSeed.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.contrast_rounded,
                        color: activeSeed, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "أسود OLED خالص في الوضع الداكن",
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          themeProvider.useOledBlack
                              ? "خلفية سوداء عميقة موفرة للطاقة"
                              : "خلفية كحلية داكنة ناعمة للعين",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color:
                                isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: themeProvider.useOledBlack,
                    activeTrackColor: activeSeed,
                    activeThumbColor: Colors.white,
                    onChanged: (val) => themeProvider.setUseOledBlack(val),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () async {
                    await themeProvider.resetAppearanceDefaults();
                    _showAthkarSnack("تمت استعادة إعدادات المظهر الافتراضية");
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(
                    "استعادة المظهر الافتراضي",
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeTile({
    required ThemeProvider themeProvider,
    required AppThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color activeSeed,
  }) {
    final selected = themeProvider.appThemeMode == mode;
    return InkWell(
      onTap: () => themeProvider.setThemeMode(mode),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? activeSeed.withValues(alpha: isDark ? 0.22 : 0.1)
              : (isDark ? const Color(0xFF172231) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? activeSeed
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 19,
                  color: selected
                      ? activeSeed
                      : (isDark ? Colors.white30 : Colors.grey.shade400),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 4: Account, Sync, Support & Updates
  Widget _buildAccountTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(
          Icons.cloud_sync_rounded,
          "النسخ الاحتياطي والمزامنة السحابية ☁️",
          badgeText: "قريباً ⏳",
        ),
        _buildGlassmorphicCloudSection(isDark),
        const SizedBox(height: 20),
        _buildSectionHeader(Icons.support_agent_rounded, "تواصل معنا والدعم"),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined, color: Colors.blue),
                title: const Text("أرسل اقتراحاتك"),
                subtitle: const Text("ahmed9ahmed779@gmail.com"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'ahmed9ahmed779@gmail.com',
                    query: 'subject=اقتراح لتطبيق رفيق المسلم',
                  );
                  try {
                    await launchUrl(emailUri);
                  } catch (_) {}
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.green),
                title: const Text("تواصل عبر واتساب"),
                subtitle: const Text("+201096304673"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final Uri whatsappUri =
                      Uri.parse('https://wa.me/201096304673');
                  try {
                    await launchUrl(whatsappUri,
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_2_rounded, color: Colors.teal),
                title: const Text("قناة التطبيق على واتساب"),
                subtitle: const Text("تابع أحدث التحديثات والورد اليومي"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final Uri url = Uri.parse(
                      'https://whatsapp.com/channel/0029VaNwp3YDzgT3fxWoGx2z');
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("عذراً، لا يمكن فتح الرابط حالياً")));
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.share_rounded, color: Colors.blueAccent),
                title: const Text("مشاركة التطبيق"),
                subtitle: const Text("الدال على الخير كفاعله"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'السلام عليكم، أنصحك بتحميل هذا التطبيق الرائع للمهام الدينية والأذكار:\n\n'
                          'https://whatsapp.com/channel/0029VaNwp3YDzgT3fxWoGx2z\n\n'
                          'نسألكم الدعاء',
                      subject: 'تطبيق رفيق المسلم',
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.star_rate_rounded, color: Colors.amber),
                title: const Text("قيم تطبيق رفيق المسلم"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
            Icons.info_outline_rounded, "عن التطبيق ℹ️"),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.info_outline_rounded,
                color: Colors.blueGrey),
            title: const Text("إصدار تطبيق رفيق المسلم"),
            trailing: Text(_appVersion,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildGlassmorphicCloudSection(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          IgnorePointer(
            child: _buildGoogleAccountCard(isDark),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_clock_rounded,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "قريباً",
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.tealAccent
                                          : Colors.teal.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "مغلق حالياً",
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "خدمة المزامنة السحابية والنسخ الاحتياطي ستتوفر قريباً إن شاء الله",
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountCard(bool isDark) {
    final bool isLinked =
        _linkedGoogleEmail != null && _linkedGoogleEmail!.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLinked
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLinked
                        ? Icons.check_circle_rounded
                        : Icons.mark_email_read_rounded,
                    color: isLinked ? Colors.green.shade700 : Colors.teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isLinked
                                  ? "مرتبط بحساب Google"
                                  : "غير مرتبط بحساب",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLinked
                                    ? (isDark
                                        ? Colors.greenAccent
                                        : Colors.green.shade900)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                          if (isLinked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle,
                                size: 18, color: Colors.green),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLinked
                            ? _linkedGoogleEmail!
                            : "ربط حسابك لمزامنة الأوسمة والختمة محلياً وسحابياً",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLinked && _lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded,
                        size: 14, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      "آخر مزامنة ناجحة: $_lastSyncTime",
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!isLinked) {
                        _showGoogleCloudBackupDialog();
                        return;
                      }
                      final success = await BackupService.uploadToCloud(
                          _linkedGoogleEmail!);
                      await _loadSettings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? "تمت المزامنة ورفع البيانات بنجاح ☁️🎉"
                                : "حدث خطأ أثناء المزامنة السحابية"),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isLinked
                          ? Icons.cloud_upload_rounded
                          : Icons.add_link_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      isLinked ? "رفع ومزامنة الآن" : "ربط حساب Google",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (isLinked) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final metadata =
                          await BackupService.getCloudBackupMetadata(
                              _linkedGoogleEmail!);
                      if (!mounted) return;

                      if (metadata == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "لم نجد أي نسخة احتياطية سحابية لهذا الحساب")),
                        );
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("تأكيد استعادة النسخة السحابية"),
                          content: Text(
                            "وجدت نسخة احتياطية سحابية بتاريخ (${metadata['formattedDate']}).\nهل تريد دمج مفاتيحها المعتمدة مع بيانات التطبيق الحالية؟",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text("إلغاء"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal),
                              child: const Text("تأكيد الاستعادة"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        final success = await BackupService.restoreFromCloud(
                            _linkedGoogleEmail!);
                        await _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? "تم دمج النسخة السحابية. أعد فتح التطبيق لتحديث جميع الشاشات."
                                  : "حدث خطأ أثناء استعادة النسخة"),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cloud_download_rounded, size: 18),
                    label:
                        const Text("استعادة", style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.no_accounts_rounded,
                        color: Colors.red.shade600),
                    tooltip: "إلغاء ربط الحساب",
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("تأكيد إلغاء ربط الحساب"),
                          content: Text(
                            "هل أنت متأكد من إلغاء ربط حساب Google ($_linkedGoogleEmail)؟\n\nتنبيه: لن تُحذف بياناتك المحلية، لكن ستتوقف المزامنة السحابية لهذا الحساب.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("تراجع"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                              ),
                              child: const Text("إلغاء الربط",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await BackupService.unlinkGoogleAccount();
                        await _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("تم إلغاء ربط الحساب بنجاح")),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
            if (isLinked) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: _deleteAuthenticatedCloudData,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('حذف بياناتي السحابية'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await BackupService.shareBackupFile();
                    },
                    icon: const Icon(Icons.folder_zip_rounded,
                        size: 18, color: Colors.blue),
                    label: const Text("تصدير ملف (جوجل درايف / الملفات 📁)",
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showRestoreDialog,
                  icon: const Icon(Icons.text_snippet_rounded,
                      size: 18, color: Colors.amber),
                  label: const Text("نص 📝", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {String? badgeText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldLight = Color(0xFFFDE68A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: isDark ? 0.16 : 0.14),
              border: Border.all(color: _gold.withValues(alpha: 0.45)),
            ),
            child: Icon(
              icon,
              color: isDark ? goldLight : _emerald,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? goldLight : _emeraldDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: isDark ? 0.18 : 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? goldLight : const Color(0xFF78350F),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOffsetButton(String key, int delta) {
    return InkWell(
      onTap: () {
        final current = prayerOffsets[key] ?? 0;
        _updateOffset(key, current + delta);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          delta > 0 ? Icons.add : Icons.remove,
          size: 16,
          color: Colors.teal,
        ),
      ),
    );
  }
}
