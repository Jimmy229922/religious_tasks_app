// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool _isLoading = true;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesService.load();
    if (!mounted) return;

    setState(() {
      _preferences = preferences;
      _isLoading = false;
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
    await _rescheduleRecurringNotifications(
      successMessage: 'تم تحديث مدة التذكير المتكرر',
    );
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
      _showMessage('حدثت مشكلة أثناء تحديث الإشعارات');
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
                          RadioListTile<AdhanSoundType>(
                            title: const Text('أذان كامل (صوت المؤذن)'),
                            subtitle: const Text(
                                'تشغيل الأذان كاملاً عند دخول وقت الصلاة'),
                            value: AdhanSoundType.full,
                            groupValue: _preferences.adhanSoundType,
                            onChanged: _isApplying ? null : _updateAdhanSoundType,
                          ),
                          RadioListTile<AdhanSoundType>(
                            title: const Text('تنبيه قصير'),
                            subtitle:
                                const Text('تشغيل صوت تنبيه بسيط لوقت الأذان'),
                            value: AdhanSoundType.short,
                            groupValue: _preferences.adhanSoundType,
                            onChanged: _isApplying ? null : _updateAdhanSoundType,
                          ),
                          RadioListTile<AdhanSoundType>(
                            title: const Text('صامت (إشعار فقط)'),
                            subtitle:
                                const Text('إظهار إشعار بدون صوت عند وقت الأذان'),
                            value: AdhanSoundType.none,
                            groupValue: _preferences.adhanSoundType,
                            onChanged: _isApplying ? null : _updateAdhanSoundType,
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
                        child: DropdownButtonFormField<int>(
                          key:
                              ValueKey(_preferences.hourlyDhikrIntervalMinutes),
                          initialValue: _preferences.hourlyDhikrIntervalMinutes,
                          decoration: const InputDecoration(
                            labelText: 'مدة التذكير المتكرر',
                            border: OutlineInputBorder(),
                          ),
                          items: NotificationPreferencesService
                              .dhikrIntervalOptions
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
                      ),
                    ),
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
    if (minutes == 10) {
      return 'كل 10 دقائق';
    }
    if (minutes == 60) {
      return 'كل 60 دقيقة';
    }
    return 'كل $minutes دقيقة';
  }
}
