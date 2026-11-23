import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/constants/strings.dart';
import 'package:religious_tasks_app/core/widgets/full_adhan_overlay_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/happiness_jar/screens/happiness_jar_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color _emerald = Color(0xFF0F766E);
  static const Color _emeraldDark = Color(0xFF064E3B);
  static const Color _gold = Color(0xFFD4AF37);

  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();
  final AppNotificationService _notificationService = AppNotificationService();

  NotificationPreferences _preferences = NotificationPreferences.defaults();
  List<String> _customDhikrs = [];
  final TextEditingController _dhikrController = TextEditingController();
  final ValueNotifier<Duration?> _remainingDhikrNotifier =
      ValueNotifier<Duration?>(null);
  bool _isLoading = true;
  bool _isApplying = false;

  bool _permNotification = true;
  bool _permLocation = true;
  bool _permBattery = true;
  bool _permOverlay = true;
  bool _permAlarm = true;

  Timer? _countdownTimer;
  DateTime? _dhikrStartTime;

  bool get _isAllPermissionsGranted =>
      _permNotification &&
      _permLocation &&
      _permBattery &&
      _permOverlay &&
      _permAlarm;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkAllPermissions();
    _startCountdownTimer();
  }

  Future<void> _checkAllPermissions() async {
    final statusNotif = await Permission.notification.isGranted;
    final statusLoc = await Permission.locationWhenInUse.isGranted;
    final statusBattery = await Permission.ignoreBatteryOptimizations.isGranted;
    final statusOverlay = await Permission.systemAlertWindow.isGranted;

    bool statusAlarm = true;
    if (Platform.isAndroid) {
      statusAlarm = await Permission.scheduleExactAlarm.isGranted;
    }

    if (mounted) {
      setState(() {
        _permNotification = statusNotif;
        _permLocation = statusLoc;
        _permBattery = statusBattery;
        _permOverlay = statusOverlay;
        _permAlarm = statusAlarm;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _remainingDhikrNotifier.dispose();
    _dhikrController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesService.load();
    final sharedPrefs = await SharedPreferences.getInstance();
    final startTimeMillis =
        sharedPrefs.getInt(AppNotificationService.dhikrCycleStartTimeKey);

    final customDhikrsJson =
        sharedPrefs.getString(AppNotificationService.customDhikrKey);
    final List<String> customDhikrs = customDhikrsJson != null
        ? List<String>.from(jsonDecode(customDhikrsJson))
        : [];

    if (!mounted) return;

    setState(() {
      _preferences = preferences;
      _customDhikrs = customDhikrs;
      _dhikrStartTime = startTimeMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(startTimeMillis)
          : null;
      _isLoading = false;
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_preferences.hourlyDhikrEnabled || _dhikrStartTime == null) {
        if (_remainingDhikrNotifier.value != null) {
          _remainingDhikrNotifier.value = null;
        }
        return;
      }

      final now = DateTime.now();
      final diffSeconds = now.difference(_dhikrStartTime!).inSeconds;
      final intervalSeconds = _preferences.hourlyDhikrIntervalMinutes * 60;
      if (intervalSeconds <= 0) return;

      final elapsedInInterval = diffSeconds % intervalSeconds;

      if (diffSeconds < 0) {
        final remaining = intervalSeconds + diffSeconds;
        _remainingDhikrNotifier.value = Duration(seconds: remaining);
        return;
      }

      final remainingSeconds = intervalSeconds - elapsedInInterval;
      _remainingDhikrNotifier.value = Duration(seconds: remainingSeconds);
    });
  }

  Future<void> _updateMorningReminder(bool value) async {
    setState(() {
      _preferences = _preferences.copyWith(
        morningAthkarReminderEnabled: value,
      );
    });

    await _preferencesService.setMorningAthkarReminderEnabled(value);
    await _rescheduleRecurringNotifications(
      successMessage: 'تم تحديث تذكير أذكار الصباح',
    );
  }

  Future<void> _updateEveningReminder(bool value) async {
    setState(() {
      _preferences = _preferences.copyWith(
        eveningAthkarReminderEnabled: value,
      );
    });

    await _preferencesService.setEveningAthkarReminderEnabled(value);
    await _rescheduleRecurringNotifications(
      successMessage: 'تم تحديث تذكير أذكار المساء',
    );
  }

  Future<void> _updateHourlyDhikrEnabled(bool value) async {
    setState(() {
      _preferences = _preferences.copyWith(hourlyDhikrEnabled: value);
    });

    await _preferencesService.setHourlyDhikrEnabled(value);
    await _rescheduleRecurringNotifications(
      successMessage: 'تم تحديث التذكير المتكرر',
    );
  }

  Future<void> _updateHourlyInterval(int minutes) async {
    setState(() {
      _preferences = _preferences.copyWith(
        hourlyDhikrIntervalMinutes: minutes,
      );
    });

    await _preferencesService.setHourlyDhikrIntervalMinutes(minutes);
    await _runApplyingTask(() async {
      await _notificationService.scheduleDhikrNotifications(
        settings: _preferences,
        forceReschedule: true,
      );
      await _loadPreferences();
      _showMessage('تم تحديث مدة التذكير المتكرر');
    });
  }

  Future<void> _updateSalawatReminderEnabled(bool value) async {
    setState(() {
      _preferences = _preferences.copyWith(salawatReminderEnabled: value);
    });

    await _preferencesService.setSalawatReminderEnabled(value);
    await _runApplyingTask(() async {
      await _notificationService.scheduleSalawatNotifications(
        settings: _preferences,
        forceReschedule: true,
      );
      await _loadPreferences();
      _showMessage('تم تحديث إعدادات الصلاة على النبي الدوري');
    });
  }

  Future<void> _updateSalawatInterval(int minutes) async {
    setState(() {
      _preferences = _preferences.copyWith(
        salawatIntervalMinutes: minutes,
      );
    });

    await _preferencesService.setSalawatIntervalMinutes(minutes);
    await _runApplyingTask(() async {
      await _notificationService.scheduleSalawatNotifications(
        settings: _preferences,
        forceReschedule: true,
      );
      await _loadPreferences();
      _showMessage('تم تحديث مدة التذكير بالصلاة على النبي');
    });
  }

  Future<void> _testSalawatNotification() async {
    await _runApplyingTask(() async {
      await _notificationService.testSalawatNotification();
      _showMessage('تم إرسال تجربة إشعار الصلاة على النبي بنجاح');
    });
  }

  Future<void> _updateHappinessJarEnabled(bool value) async {
    setState(() {
      _preferences = _preferences.copyWith(happinessJarEnabled: value);
    });
    await _preferencesService.setHappinessJarEnabled(value);
    await _runApplyingTask(() async {
      await _notificationService.scheduleHappinessJarNotifications(
        settings: _preferences,
      );
      _showMessage(value
          ? 'تم تفعيل إشعار برطمان السعادة اليومي'
          : 'تم إيقاف إشعار برطمان السعادة اليومي');
    });
  }

  Future<void> _pickHappinessJarTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _preferences.happinessJarHour,
        minute: _preferences.happinessJarMinute,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preferences = _preferences.copyWith(
        happinessJarEnabled: true,
        happinessJarHour: picked.hour,
        happinessJarMinute: picked.minute,
      );
    });
    await _preferencesService.setHappinessJarEnabled(true);
    await _preferencesService.setHappinessJarTime(picked.hour, picked.minute);
    await _runApplyingTask(() async {
      await _notificationService.scheduleHappinessJarNotifications(
        settings: _preferences,
      );
      _showMessage('تم تحديث وقت رسالة السعادة اليومية');
    });
  }

  Future<void> _testHappinessJarNotification() async {
    await _runApplyingTask(() async {
      await _notificationService.testHappinessJarNotification();
      _showMessage('تم إرسال رسالة سعادة تجريبية بنجاح 💛');
    });
  }

  String _formatHappinessTime(int hour, int minute) {
    final isPm = hour >= 12;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return QuranTextFormatter.toArabicDigits('$h:$m ${isPm ? "م" : "ص"}');
  }

  Future<void> _updateFloatingDhikrEnabled(bool value) async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    try {
      if (value) {
        final alreadyGranted =
            await _notificationService.ensureFloatingDhikrPermission();
        if (!alreadyGranted) {
          setState(() {
            _isApplying = false;
          });
          _showMessage('يرجى تفعيل صلاحية الظهور فوق التطبيقات');
          return;
        }
      } else {
        await _notificationService.closeDhikrOverlay();
      }

      final updatedPreferences =
          _preferences.copyWith(floatingDhikrEnabled: value);

      setState(() {
        _preferences = updatedPreferences;
      });

      await _preferencesService.setFloatingDhikrEnabled(value);
      await _notificationService.scheduleDhikrNotifications(
        settings: updatedPreferences,
      );

      _showMessage(
          value ? 'تم تفعيل الأذكار العائمة' : 'تم تعطيل الأذكار العائمة');
    } catch (e) {
      debugPrint('Error updating floating dhikr: $e');
      _showMessage('حدثت مشكلة أثناء تحديث الأذكار العائمة');
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _rescheduleRecurringNotifications({
    String? successMessage,
  }) async {
    await _runApplyingTask(() async {
      await _notificationService.syncRecurringSchedules();
      await _loadPreferences();
      if (successMessage != null) {
        _showMessage(successMessage);
      }
    });
  }

  Future<void> _rescheduleEverything() async {
    await _runApplyingTask(() async {
      final tasksViewModel = context.read<TasksViewModel>();
      await _notificationService.init();
      final today = tasksViewModel.prayerTimes;
      final tomorrow = tasksViewModel.tomorrowPrayerTimes;

      if (today != null && tomorrow != null) {
        await _notificationService.schedulePrayerNotifications(
          today: today,
          tomorrow: tomorrow,
        );
      }

      _showMessage('تمت إعادة جدولة جميع الإشعارات بنجاح');
    });
  }

  Future<void> _testFajrNotification() async {
    await _runApplyingTask(() async {
      await _notificationService.testAdhanNotification('fajr', AppStrings.fajr);
      _showMessage('تم إرسال إشعار تجريبي للفجر');
    });
  }

  Future<void> _testDhikrNotification() async {
    await _runApplyingTask(() async {
      await _notificationService.testDhikrNotification();
      _showMessage('تم إرسال إشعار ذكر تجريبي');
    });
  }

  Future<void> _runApplyingTask(Future<void> Function() task) async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    try {
      await task();
    } catch (e, stack) {
      debugPrint('Error updating notifications: $e\n$stack');
      String errorMessage = 'حدثت مشكلة أثناء تحديث الإشعارات';
      if (e is String) {
        errorMessage = e;
      }
      _showMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: GoogleFonts.cairo()),
      ),
    );
  }

  Future<void> _addCustomDhikr() async {
    final text = _dhikrController.text.trim();
    if (text.isEmpty) return;

    final sharedPrefs = await SharedPreferences.getInstance();
    final updatedList = [..._customDhikrs, text];
    await sharedPrefs.setString(
        AppNotificationService.customDhikrKey, jsonEncode(updatedList));

    _dhikrController.clear();
    await _loadPreferences();
    _showMessage('تم إضافة الذكر المخصص');

    await _notificationService.scheduleDhikrNotifications(
        settings: _preferences, forceReschedule: true);
  }

  Future<void> _deleteCustomDhikr(int index) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final updatedList = List<String>.from(_customDhikrs)..removeAt(index);
    await sharedPrefs.setString(
        AppNotificationService.customDhikrKey, jsonEncode(updatedList));

    await _loadPreferences();
    _showMessage('تم حذف الذكر');

    await _notificationService.scheduleDhikrNotifications(
        settings: _preferences, forceReschedule: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B131E) : const Color(0xFFF3F8F6),
      appBar: AppBar(
        title: Text(
          'التشخيص المتقدم والإشعارات',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0B131E) : _emerald,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // 1. Permissions Health Card
                  _buildPermissionsCard(isDark),

                  const SizedBox(height: 18),

                  // 2. Daily & Recurring Reminders
                  _buildSectionHeader(
                    Icons.notifications_active_rounded,
                    'تذكيرات الأذكار والصلاة على النبي ﷺ',
                  ),
                  _buildReminderCard(
                    isDark: isDark,
                    icon: Icons.wb_sunny_rounded,
                    accent: const Color(0xFFD97706),
                    title: 'أذكار الصباح',
                    subtitle: 'إشعار يومي ثابت في وقت الصباح',
                    value: _preferences.morningAthkarReminderEnabled,
                    onChanged: _updateMorningReminder,
                  ),
                  _buildReminderCard(
                    isDark: isDark,
                    icon: Icons.nights_stay_rounded,
                    accent: const Color(0xFF6366F1),
                    title: 'أذكار المساء',
                    subtitle: 'إشعار يومي ثابت في وقت المساء',
                    value: _preferences.eveningAthkarReminderEnabled,
                    onChanged: _updateEveningReminder,
                  ),
                  _buildReminderCard(
                    isDark: isDark,
                    icon: Icons.mosque_rounded,
                    accent: _emerald,
                    title: 'التذكير بالصلاة على النبي ﷺ',
                    subtitle: _preferences.salawatReminderEnabled
                        ? 'مُفعّل — كل ${_intervalLabel(_preferences.salawatIntervalMinutes)}'
                        : 'مُعطّل — التذكير والصوت متوقفان',
                    value: _preferences.salawatReminderEnabled,
                    onChanged: _updateSalawatReminderEnabled,
                  ),
                  if (_preferences.salawatReminderEnabled)
                    _buildCardContainer(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تكرار الصلاة على النبي ﷺ:',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: NotificationPreferencesService
                                .salawatIntervalOptions
                                .map((minutes) {
                              final selected =
                                  _preferences.salawatIntervalMinutes ==
                                      minutes;
                              return ChoiceChip(
                                label: Text(
                                  _intervalLabel(minutes),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                ),
                                selected: selected,
                                selectedColor: _emerald,
                                showCheckmark: false,
                                onSelected: _isApplying
                                    ? null
                                    : (_) => _updateSalawatInterval(minutes),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                    side:
                                        BorderSide(color: Colors.red.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.stop_circle_outlined,
                                      size: 18),
                                  label: Text(
                                    'إيقاف الصوت',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                  onPressed: _isApplying
                                      ? null
                                      : () =>
                                          _updateSalawatReminderEnabled(false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _emerald,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.volume_up_rounded,
                                      size: 18),
                                  label: Text(
                                    'تجربة الصوت',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                  onPressed: _isApplying
                                      ? null
                                      : _testSalawatNotification,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  _buildReminderCard(
                    isDark: isDark,
                    icon: Icons.timer_rounded,
                    accent: const Color(0xFF0284C7),
                    title: 'التذكير المتكرر بالذكر',
                    subtitle: 'تنبيه بالأذكار والأدعية بفواصل زمنية مخصصة',
                    value: _preferences.hourlyDhikrEnabled,
                    onChanged: _updateHourlyDhikrEnabled,
                  ),
                  if (_preferences.hourlyDhikrEnabled)
                    _buildCardContainer(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مدة التذكير المتكرر:',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: NotificationPreferencesService
                                .dhikrIntervalOptions
                                .map((minutes) {
                              final selected =
                                  _preferences.hourlyDhikrIntervalMinutes ==
                                      minutes;
                              return ChoiceChip(
                                label: Text(
                                  _intervalLabel(minutes),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                ),
                                selected: selected,
                                selectedColor: const Color(0xFF0284C7),
                                showCheckmark: false,
                                onSelected: _isApplying
                                    ? null
                                    : (_) => _updateHourlyInterval(minutes),
                              );
                            }).toList(),
                          ),
                          ValueListenableBuilder<Duration?>(
                            valueListenable: _remainingDhikrNotifier,
                            builder: (context, remainingTime, _) {
                              if (remainingTime == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_bottom_rounded,
                                        size: 18, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'التذكير القادم خلال:',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(remainingTime),
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  _buildReminderCard(
                    isDark: isDark,
                    icon: Icons.layers_rounded,
                    accent: const Color(0xFF7C3AED),
                    title: 'الأذكار العائمة (على الشاشة)',
                    subtitle: 'إظهار الأذكار بشكل عائم فوق التطبيقات',
                    value: _preferences.floatingDhikrEnabled,
                    onChanged: _updateFloatingDhikrEnabled,
                  ),

                  _buildReminderCard(
                    isDark: isDark,
                    icon: Icons.card_giftcard_rounded,
                    accent: const Color(0xFFD97706),
                    title: 'برطمان السعادة اليومي 💛',
                    subtitle: _preferences.happinessJarEnabled
                        ? 'رسالة مبهجة كل يوم الساعة ${_formatHappinessTime(_preferences.happinessJarHour, _preferences.happinessJarMinute)}'
                        : 'مُعطّل حالياً',
                    value: _preferences.happinessJarEnabled,
                    onChanged: _updateHappinessJarEnabled,
                  ),
                  if (_preferences.happinessJarEnabled)
                    _buildCardContainer(
                      isDark: isDark,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isApplying ? null : _pickHappinessJarTime,
                              icon: const Icon(Icons.access_time_rounded,
                                  size: 18),
                              label: Text(
                                'تغيير الوقت (${_formatHappinessTime(_preferences.happinessJarHour, _preferences.happinessJarMinute)})',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD97706),
                                side: BorderSide(
                                  color: const Color(0xFFD97706)
                                      .withValues(alpha: 0.45),
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
                              onPressed: _isApplying
                                  ? null
                                  : _testHappinessJarNotification,
                              icon: const Icon(
                                  Icons.notifications_active_rounded,
                                  size: 18),
                              label: Text(
                                'تجربة السعادة',
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
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HappinessJarScreen()),
                      ).then((_) => _loadPreferences()),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        'فتح برطمان السعادة وقراءة الرسائل',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _emerald,
                        side:
                            BorderSide(color: _emerald.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Custom Dhikrs
                  _buildSectionHeader(
                      Icons.bookmark_add_rounded, 'الأذكار المخصصة'),
                  _buildCardContainer(
                    isDark: isDark,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dhikrController,
                                style: GoogleFonts.cairo(fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'أضف ذكراً مخصصاً هنا...',
                                  hintStyle: GoogleFonts.cairo(fontSize: 12),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E2B3C)
                                      : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        if (_customDhikrs.isNotEmpty) ...[
                          const Divider(height: 24),
                          ...List.generate(_customDhikrs.length, (index) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _customDhikrs[index],
                                style: GoogleFonts.cairo(fontSize: 13.5),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteCustomDhikr(index),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Quick Diagnostic & Test Tools
                  _buildSectionHeader(
                      Icons.build_circle_rounded, 'أدوات واختبارات سريعة'),
                  _buildCardContainer(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _isApplying ? null : _rescheduleEverything,
                          icon: const Icon(Icons.schedule_send_rounded),
                          label: Text(
                            'إعادة جدولة جميع الإشعارات الآن',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              _isApplying ? null : _testFajrNotification,
                          icon: const Icon(Icons.notifications_active_rounded),
                          label: Text('تجربة إشعار الفجر',
                              style: GoogleFonts.cairo()),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed:
                              _isApplying ? null : _testDhikrNotification,
                          icon: const Icon(Icons.notifications_active_rounded),
                          label: Text('تجربة إشعار ذكر ودعاء',
                              style: GoogleFonts.cairo()),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed:
                              _isApplying ? null : _testSalawatNotification,
                          icon:
                              const Icon(Icons.favorite_rounded, color: _emerald),
                          label: Text('تجربة إشعار الصلاة على النبي',
                              style: GoogleFonts.cairo()),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const FullAdhanOverlayDialog(
                                prayerName: "العَصْر",
                                prayerKey: "asr",
                              ),
                            );
                          },
                          icon: const Icon(Icons.mosque_rounded,
                              color: Colors.amberAccent),
                          label: Text(
                            'تجربة شاشة الأذان الفاخرة الكاملة',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emeraldDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_isApplying) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isAllPermissionsGranted
              ? (isDark
                  ? const [Color(0xFF0E2926), Color(0xFF132234)]
                  : const [_emerald, _emeraldDark])
              : (isDark
                  ? const [Color(0xFF312214), Color(0xFF1F1812)]
                  : const [Color(0xFFB45309), Color(0xFF92400E)]),
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isAllPermissionsGranted
                    ? Icons.verified_user_rounded
                    : Icons.warning_amber_rounded,
                color: Colors.amberAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isAllPermissionsGranted
                      ? 'جميع صلاحيات الإشعارات مكتملة'
                      : 'بعض الصلاحيات تحتاج تفعيل لضمان وصول الأذان',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPermChip('الإشعارات', _permNotification),
              _buildPermChip('الموقع', _permLocation),
              _buildPermChip('تجاهل البطارية', _permBattery),
              _buildPermChip('الطفو', _permOverlay),
              _buildPermChip('المنبه الدقيق', _permAlarm),
            ],
          ),
          if (!_isAllPermissionsGranted) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
                Future.delayed(
                  const Duration(seconds: 1),
                  () => _checkAllPermissions(),
                );
              },
              icon: const Icon(Icons.settings_applications_rounded, size: 18),
              label: Text(
                'فتح إعدادات الصلاحيات',
                style: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermChip(String label, bool granted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: granted ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: granted
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : Colors.amberAccent.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 13,
            color: granted ? Colors.greenAccent : Colors.amberAccent,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReminderCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
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
            onChanged: _isApplying ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, top: 6),
      child: Row(
        children: [
          Icon(icon, color: _emerald, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _emerald,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _intervalLabel(int minutes) {
    final ar = QuranTextFormatter.toArabicDigits(minutes.toString());
    if (minutes <= 10) {
      return 'كل $ar دقائق';
    }
    return 'كل $ar دقيقة';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return QuranTextFormatter.toArabicDigits(
          '${twoDigits(duration.inHours)}:$minutes:$seconds');
    }
    return QuranTextFormatter.toArabicDigits('$minutes:$seconds');
  }
}
