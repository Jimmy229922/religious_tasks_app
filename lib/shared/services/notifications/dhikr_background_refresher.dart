import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'app_notification_service.dart';

class DhikrBackgroundRefresher {
  static const int refreshAlarmId = 5001;

  @pragma('vm:entry-point')
  static Future<void> refreshCallback() async {
    try {
      debugPrint("🔄 Dhikr Background Refresher Started");
      
      // Initialize timezones since this runs in a separate isolate
      tz_data.initializeTimeZones();
      
      final notificationService = AppNotificationService();
      // We don't need to call init() here because scheduleDhikrNotifications 
      // calls _ensureInitialized which handles it.
      
      await notificationService.scheduleDhikrNotifications(forceReschedule: false);
      
      debugPrint("✅ Dhikr Background Refresher Completed Successfully");
    } catch (e, stack) {
      debugPrint("❌ Dhikr Background Refresher Failed: $e\n$stack");
    }
  }
}
