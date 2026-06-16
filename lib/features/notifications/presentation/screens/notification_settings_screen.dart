import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:religious_tasks_app/core/constants/strings.dart';
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
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();
  final AppNotificationService _notificationService = AppNotificationService();

  NotificationPreferences _preferences = NotificationPreferences.defaults();
  List<String> _customDhikrs = [];
  final TextEditingController _dhikrController = TextEditingController();
  bool _isLoading = true;
  bool _isApplying = false;
  bool _isAllPermissionsGranted = true;

  Timer? _countdownTimer;
  Duration? _remainingDhikrTime;
  DateTime? _dhikrStartTime;

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
        _isAllPermissionsGranted = statusNotif && statusLoc && statusBattery && statusOverlay && statusAlarm;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesService.load();
    final sharedPrefs = await SharedPreferences.getInstance();
    final startTimeMillis =
        sharedPrefs.getInt(AppNotificationService.dhikrCycleStartTimeKey);
    
    final customDhikrsJson = sharedPrefs.getString(AppNotificationService.customDhikrKey);
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
        if (_remainingDhikrTime != null) {
          setState(() => _remainingDhikrTime = null);
        }
        return;
      }

      final now = DateTime.now();
      final diffSeconds = now.difference(_dhikrStartTime!).inSeconds;
      final intervalSeconds = _preferences.hourlyDhikrIntervalMinutes * 60;

      // Calculate elapsed seconds in current interval
      final elapsedInInterval = diffSeconds % intervalSeconds;
      
      // If diffSeconds is negative (shouldn't happen with current logic but for safety)
      if (diffSeconds < 0) {
        final remaining = intervalSeconds + diffSeconds; // diffSeconds is negative
        setState(() => _remainingDhikrTime = Duration(seconds: remaining));
        return;
      }

      final remainingSeconds = intervalSeconds - elapsedInInterval;
      setState(() {
        _remainingDhikrTime = Duration(seconds: remainingSeconds);
      });
    });
  }

  Future<void> _updateAdhanSetting(String prayerKey, bool value) async {
    final updatedAdhan = Map<String, bool>.from(_preferences.adhanEnabled)
      ..[prayerKey] = value;

    setState(() {
      _preferences = _preferences.copyWith(adhanEnabled: updatedAdhan);
    });

    await _preferencesService.setAdhanEnabled(prayerKey, value);
    await _reschedulePrayerNotifications(
      successMessage: 'تم تحديث إعدادات الأذان',
    );
  }

  Future<void> _updateAdhanSoundType(AdhanSoundType? type) async {
    if (type == null) return;

    setState(() {
      _preferences = _preferences.copyWith(adhanSoundType: type);
    });

    await _preferencesService.setAdhanSoundType(type);
    await _reschedulePrayerNotifications(
      successMessage: 'تم تحديث نوع صوت الأذان',
    );
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
    // نمرر forceReschedule: true هنا لأن المستخدم غير الإعدادات بنفسه
    await _runApplyingTask(() async {
      await _notificationService.scheduleDhikrNotifications(
        settings: _preferences,
        forceReschedule: true,
      );
      await _loadPreferences();
      _showMessage('تم تحديث مدة التذكير المتكرر');
    });
  }

  Future<void> _updateFloatingDhikrEnabled(bool value) async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    try {
      var nextValue = value;

      if (value) {
        final alreadyGranted =
            await _notificationService.ensureFloatingDhikrPermission();
        if (!alreadyGranted) {
          // If not granted, the system settings should have opened.
          // We don't want to stay in "loading" state forever if the user
          // takes time in settings.
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
          _preferences.copyWith(floatingDhikrEnabled: nextValue);

      setState(() {
        _preferences = updatedPreferences;
      });

      await _preferencesService.setFloatingDhikrEnabled(nextValue);
      await _notificationService.scheduleDhikrNotifications(
        settings: updatedPreferences,
      );

      _showMessage(nextValue
          ? 'تم تفعيل الأذكار العائمة'
          : 'تم تعطيل الأذكار العائمة');
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
      await _loadPreferences(); // تحديث وقت البداية بعد الجدولة الجديدة
      if (successMessage != null) {
        _showMessage(successMessage);
      }
    });
  }

  Future<void> _reschedulePrayerNotifications({
    String? successMessage,
  }) async {
    await _runApplyingTask(() async {
      final tasksViewModel = context.read<TasksViewModel>();
      final today = tasksViewModel.prayerTimes;
      final tomorrow = tasksViewModel.tomorrowPrayerTimes;

      if (today == null || tomorrow == null) {
        _showMessage('سيتم تطبيق إعدادات الأذان بعد تحديث مواقيت الصلاة');
        return;
      }

      await _notificationService.schedulePrayerNotifications(
        today: today,
        tomorrow: tomorrow,
      );

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

      _showMessage('تمت إعادة جدولة الإشعارات بنجاح');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addCustomDhikr() async {
    final text = _dhikrController.text.trim();
    if (text.isEmpty) return;

    final sharedPrefs = await SharedPreferences.getInstance();
    final updatedList = [..._customDhikrs, text];
    await sharedPrefs.setString(AppNotificationService.customDhikrKey, jsonEncode(updatedList));
    
    _dhikrController.clear();
    await _loadPreferences();
    _showMessage('تم إضافة الذكر المخصص');
    
    // Reschedule to include new dhikr
    await _notificationService.scheduleDhikrNotifications(settings: _preferences, forceReschedule: true);
  }

  Future<void> _deleteCustomDhikr(int index) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final updatedList = List<String>.from(_customDhikrs)..removeAt(index);
    await sharedPrefs.setString(AppNotificationService.customDhikrKey, jsonEncode(updatedList));
    
    await _loadPreferences();
    _showMessage('تم حذف الذكر');
    
    // Reschedule
    await _notificationService.scheduleDhikrNotifications(settings: _preferences, forceReschedule: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('صوت الأذان'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر نوع التنبيه لوقت الأذان:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildModernRadioTile(
                            title: 'أذان كامل (صوت المؤذن)',
                            subtitle: 'تشغيل الأذان كاملاً عند دخول وقت الصلاة',
                            value: AdhanSoundType.full,
                          ),
                          _buildModernRadioTile(
                            title: 'تنبيه قصير',
                            subtitle: 'تشغيل صوت تنبيه بسيط لوقت الأذان',
                            value: AdhanSoundType.short,
                          ),
                          _buildModernRadioTile(
                            title: 'صامت (إشعار فقط)',
                            subtitle: 'إظهار إشعار بدون صوت عند وقت الأذان',
                            value: AdhanSoundType.none,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('تنبيهات الأذان'),
                  ...NotificationPreferencesService.prayerKeys.map(
                    (prayerKey) => _buildPrayerSwitchTile(
                      prayerKey: prayerKey,
                      title: _prayerTitle(prayerKey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('تذكيرات الأذكار'),
                  _buildReminderTile(
                    title: 'أذكار الصباح',
                    subtitle: 'إشعار يومي ثابت في وقت الصباح',
                    value: _preferences.morningAthkarReminderEnabled,
                    onChanged: _updateMorningReminder,
                  ),
                  _buildReminderTile(
                    title: 'أذكار المساء',
                    subtitle: 'إشعار يومي ثابت في وقت المساء',
                    value: _preferences.eveningAthkarReminderEnabled,
                    onChanged: _updateEveningReminder,
                  ),
                  _buildReminderTile(
                    title: 'التذكير المتكرر بالذكر',
                    subtitle:
                        'يمكنك الآن اختيار التذكير كل 10 دقائق أو بفواصل أطول',
                    value: _preferences.hourlyDhikrEnabled,
                    onChanged: _updateHourlyDhikrEnabled,
                  ),
                  _buildReminderTile(
                    title: 'الأذكار العائمة (على الشاشة)',
                    subtitle: 'إظهار الأذكار بشكل عائم فوق التطبيقات',
                    value: _preferences.floatingDhikrEnabled,
                    onChanged: _updateFloatingDhikrEnabled,
                  ),
                  if (_preferences.hourlyDhikrEnabled)
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(top: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              key: ValueKey(_preferences.hourlyDhikrIntervalMinutes),
                              initialValue: _preferences.hourlyDhikrIntervalMinutes,
                              decoration: const InputDecoration(
                                labelText: 'مدة التذكير المتكرر',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer_outlined),
                              ),
                              items: NotificationPreferencesService.dhikrIntervalOptions
                                  .map(
                                    (minutes) => DropdownMenuItem(
                                      value: minutes,
                                      child: Text(_intervalLabel(minutes)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isApplying
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _updateHourlyInterval(value);
                                      }
                                    },
                            ),
                            if (_remainingDhikrTime != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'التذكير القادم خلال:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_remainingDhikrTime!),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('الأذكار المخصصة'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dhikrController,
                                  decoration: const InputDecoration(
                                    hintText: 'أضف ذكراً مخصصاً هنا...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _addCustomDhikr,
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          if (_customDhikrs.isNotEmpty) ...[
                            const Divider(height: 32),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _customDhikrs.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) => ListTile(
                                title: Text(_customDhikrs[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteCustomDhikr(index),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!_isAllPermissionsGranted) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader('نصيحة لضمان وصول الإشعارات'),
                    Card(
                      color: Colors.amber.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'لضمان استمرار الأذكار حتى عند غلق التطبيق، يرجى تفعيل "التشغيل التلقائي" وإلغاء "قيود البطارية" من إعدادات النظام.',
                                    style: TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () async {
                                await openAppSettings();
                                // إعادة الفحص بعد العودة من الإعدادات
                                Future.delayed(const Duration(seconds: 1), () => _checkAllPermissions());
                              },
                              icon: const Icon(Icons.settings_applications),
                              label: const Text('افتح إعدادات التطبيق الآن'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildSectionHeader('أدوات سريعة'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _isApplying ? null : _rescheduleEverything,
                            icon: const Icon(Icons.schedule_send),
                            label: const Text('إعادة جدولة الإشعارات الآن'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                _isApplying ? null : _testFajrNotification,
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('تجربة إشعار الفجر'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                _isApplying ? null : _testDhikrNotification,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('تجربة إشعار ذكر ودعاء'),
                          ),
                          if (_isApplying) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModernRadioTile({
    required String title,
    required String subtitle,
    required AdhanSoundType value,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      leading: Radio<AdhanSoundType>(
        value: value,
        // ignore: deprecated_member_use
        groupValue: _preferences.adhanSoundType,
        // ignore: deprecated_member_use
        onChanged: _isApplying ? null : _updateAdhanSoundType,
      ),
      contentPadding: EdgeInsets.zero,
      onTap: _isApplying ? null : () => _updateAdhanSoundType(value),
    );
  }

  Widget _buildPrayerSwitchTile({
    required String prayerKey,
    required String title,
  }) {
    final isEnabled = _preferences.isAdhanEnabled(prayerKey);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: isEnabled,
        onChanged: _isApplying
            ? null
            : (value) => _updateAdhanSetting(prayerKey, value),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          isEnabled ? 'مفعل' : 'معطل',
          style: TextStyle(
            color: isEnabled ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        secondary: Icon(
          Icons.mosque,
          color: isEnabled ? Colors.teal : Colors.grey,
        ),
        activeTrackColor: Colors.teal,
      ),
    );
  }

  Widget _buildReminderTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: value,
        onChanged: _isApplying ? null : onChanged,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle),
        secondary: Icon(
          Icons.notifications_outlined,
          color: value ? Colors.teal : Colors.grey,
        ),
        activeTrackColor: Colors.teal,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  String _prayerTitle(String prayerKey) {
    switch (prayerKey) {
      case 'fajr':
        return AppStrings.fajr;
      case 'sunrise':
        return AppStrings.sunrise;
      case 'dhuhr':
        return AppStrings.dhuhr;
      case 'asr':
        return AppStrings.asr;
      case 'maghrib':
        return AppStrings.maghrib;
      case 'isha':
        return AppStrings.isha;
      default:
        return prayerKey;
    }
  }

  String _intervalLabel(int minutes) {
    if (minutes == 5) {
      return 'كل 5 دقائق';
    }
    if (minutes == 10) {
      return 'كل 10 دقائق';
    }
    if (minutes == 60) {
      return 'كل 60 دقيقة';
    }
    return 'كل $minutes دقيقة';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }
}
