import 'package:flutter/material.dart';

class AthkarTimeHelper {
  /// Checks if current time is within Morning Athkar window
  /// Primary time: After Fajr prayer (~4:00 AM) until Dhuhr prayer (~12:59 PM)
  static bool isMorningWindow(
    DateTime now, {
    DateTime? fajrTime,
    DateTime? dhuhrTime,
  }) {
    if (fajrTime != null && dhuhrTime != null) {
      return now.isAfter(fajrTime.subtract(const Duration(minutes: 15))) &&
          now.isBefore(dhuhrTime);
    }
    final hour = now.hour;
    return hour >= 4 && hour < 13;
  }

  /// Checks if current time is within Evening Athkar window
  /// Primary time: After Asr prayer (~3:00 PM / 15:00) through Dusk until Midnight / Fajr
  static bool isEveningWindow(
    DateTime now, {
    DateTime? asrTime,
    DateTime? fajrTime,
  }) {
    if (asrTime != null) {
      final isAfterAsr =
          now.isAfter(asrTime.subtract(const Duration(minutes: 15)));
      final isBeforeFajrNextDay =
          fajrTime != null ? now.isBefore(fajrTime) : now.hour < 4;
      return isAfterAsr || isBeforeFajrNextDay;
    }
    final hour = now.hour;
    return hour >= 15 || hour < 4;
  }

  /// Label explaining Morning Athkar time window according to Islamic Consensus
  static String getMorningWindowDesc() {
    return 'وقتها الشرعي المستحب يبدأ من بعد صلاة الفجر ويمتد جوازاً لمن نسيها حتى زوال الشمس (قبل صلاة الظهر).';
  }

  /// Label explaining Evening Athkar time window according to Islamic Consensus
  static String getEveningWindowDesc() {
    return 'وقتها الشرعي المستحب يبدأ من بعد صلاة العصر وحتى غروب الشمس ويمتد جوازاً لمن نسيها حتى منتصف الليل.';
  }

  /// Shows an informative modal bottom sheet explaining that the requested Athkar is outside its primary time window
  static Future<bool?> showInactiveTimeDialog({
    required BuildContext context,
    required bool isMorning,
    required VoidCallback onProceedAnyway,
    required VoidCallback onSwitchToActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestedTitle = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final activeTitle = isMorning ? 'أذكار المساء' : 'أذكار الصباح';
    final windowDesc =
        isMorning ? getMorningWindowDesc() : getEveningWindowDesc();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خارج الوقت المخصص لـ $requestedTitle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    windowDesc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'الوقت الحالي مخصص لـ $activeTitle (مفتوحة الآن).',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onSwitchToActive();
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'الانتقال إلى $activeTitle الآن',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onProceedAnyway();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'تصفح $requestedTitle استثنائياً',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
