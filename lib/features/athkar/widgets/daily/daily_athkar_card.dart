import 'package:flutter/material.dart';
import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/features/athkar/models/athkar_time_helper.dart';
import '../../providers/athkar_view_model.dart';

class DailyAthkarCard extends StatelessWidget {
  final AthkarDataState data;
  final bool isMorning;
  final VoidCallback onTap;
  final VoidCallback? onSwitchToActive;

  const DailyAthkarCard({
    super.key,
    required this.data,
    required this.isMorning,
    required this.onTap,
    this.onSwitchToActive,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentTimeActive = isMorning
        ? AthkarTimeHelper.isMorningWindow(now)
        : AthkarTimeHelper.isEveningWindow(now);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));
    final surface = isDark ? const Color(0xFF151B20) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final progress = isMorning ? data.morning : data.evening;
    final label = isMorning ? kAthkarMorning : kAthkarEvening;

    final statusLabel = !isCurrentTimeActive
        ? 'مغلقة الآن'
        : (progress.isComplete
            ? 'مكتملة'
            : (progress.current > 0 ? 'تابع' : 'مفتوحة الآن'));

    final badgeColor = !isCurrentTimeActive
        ? (isDark ? Colors.amber.shade300 : Colors.amber.shade800)
        : accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (isCurrentTimeActive) {
            onTap();
          } else {
            AthkarTimeHelper.showInactiveTimeDialog(
              context: context,
              isMorning: isMorning,
              onProceedAnyway: onTap,
              onSwitchToActive: () {
                if (onSwitchToActive != null) {
                  onSwitchToActive!();
                } else {
                  onTap();
                }
              },
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: !isCurrentTimeActive
                  ? badgeColor.withValues(alpha: 0.3)
                  : border,
              width: !isCurrentTimeActive ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      !isCurrentTimeActive
                          ? Icons.lock_clock_rounded
                          : (isMorning
                              ? Icons.wb_sunny_rounded
                              : Icons.nights_stay),
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isCurrentTimeActive
                              ? 'الوقت المناسب الآن'
                              : (isMorning ? 'موعدها الفجر - الظهر' : 'موعدها العصر - الليل'),
                          style: TextStyle(
                            color: isCurrentTimeActive ? Colors.teal : textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCurrentTimeActive) ...[
                            Icon(Icons.lock_rounded, size: 12, color: badgeColor),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              statusLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'التقدم: ${progress.current} / ${progress.total}',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 8,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
