import 'package:flutter_test/flutter_test.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NotificationPreferencesService persists and restores pre-Adhan and Dhikr settings', () async {
    SharedPreferences.setMockInitialValues({});
    final service = NotificationPreferencesService();

    final initial = await service.load();
    expect(initial.preAdhanReminderMinutes, 5);
    expect(initial.hourlyDhikrEnabled, isTrue);
    expect(initial.floatingDhikrEnabled, isFalse);

    await service.setPreAdhanReminderMinutes(15);
    await service.setFloatingDhikrEnabled(true);
    await service.setHourlyDhikrIntervalMinutes(15);

    final updated = await service.load();
    expect(updated.preAdhanReminderMinutes, 15);
    expect(updated.floatingDhikrEnabled, isTrue);
    expect(updated.hourlyDhikrIntervalMinutes, 15);
  });

  test('NotificationPreferences copyWith preserves existing values', () {
    final defaults = NotificationPreferences.defaults();
    final modified = defaults.copyWith(preAdhanReminderMinutes: 10);

    expect(modified.preAdhanReminderMinutes, 10);
    expect(modified.hourlyDhikrIntervalMinutes, defaults.hourlyDhikrIntervalMinutes);
    expect(modified.salawatIntervalMinutes, defaults.salawatIntervalMinutes);
    expect(modified.happinessJarHour, defaults.happinessJarHour);
  });
}
