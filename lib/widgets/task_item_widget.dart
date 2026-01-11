import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/strings.dart';
import '../models/task_item.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskItem task;
  final int index;
  final bool isDark;
  final DateTime now;
  final PrayerTimes? prayerTimes;
  final PrayerTimes? prayerTimesTomorrow;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.index,
    required this.isDark,
    required this.now,
    required this.onTap,
    this.onIncrement, // if null, means it's a toggle task
    this.prayerTimes,
    this.prayerTimesTomorrow,
  });

  @override
  Widget build(BuildContext context) {
    final isProphetPrayer = task.name.contains(kProphetPrayer);
    final isCounterTask = task.targetCount > 1 && !isProphetPrayer;
    final isAthkar = task.name.contains(kAthkarLabel);
    final accent = _taskAccent(task, isDark);
    final icon = _taskIcon(task);
    final surface = isDark ? const Color(0xFF151A1F) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;

    Widget? subtitleWidget = _buildSubtitle(accent, textMuted, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCounterTask ? onIncrement : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.22 : 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 64,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted ? textMuted : textPrimary,
                      ),
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 6),
                      subtitleWidget,
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: task.isCompleted ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: task.isCompleted
                              ? accent
                              : accent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  if (isCounterTask) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${task.currentCount}/${task.targetCount}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accent,
                            fontSize: 11),
                      ),
                    ),
                  ] else if (isProphetPrayer || isAthkar) ...[
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(Color accent, Color textMuted, bool isDark) {
    if (prayerTimes != null && prayerTimesTomorrow != null) {
      DateTime? prayerTime;
      if (task.name.contains(kPrayerFajr)) {
        prayerTime = prayerTimes!.fajr;
      } else if (task.name.contains(kPrayerDhuhr)) {
        prayerTime = prayerTimes!.dhuhr;
      } else if (task.name.contains(kPrayerAsr)) {
        prayerTime = prayerTimes!.asr;
      } else if (task.name.contains(kPrayerMaghrib)) {
        prayerTime = prayerTimes!.maghrib;
      } else if (task.name.contains(kPrayerIsha)) {
        prayerTime = prayerTimes!.isha;
      }

      if (prayerTime != null) {
        DateTime target = prayerTime;
        if (now.isAfter(target)) {
          // If passed, find next day
          if (task.name.contains(kPrayerFajr)) {
            target = prayerTimesTomorrow!.fajr;
          } else if (task.name.contains(kPrayerDhuhr)) {
            target = prayerTimesTomorrow!.dhuhr;
          } else if (task.name.contains(kPrayerAsr)) {
            target = prayerTimesTomorrow!.asr;
          } else if (task.name.contains(kPrayerMaghrib)) {
            target = prayerTimesTomorrow!.maghrib;
          } else if (task.name.contains(kPrayerIsha)) {
            target = prayerTimesTomorrow!.isha;
          }
        }

        Duration diff = target.difference(now);
        if (diff.isNegative) diff = Duration.zero;

        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        final countdownColor =
            isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57C00);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_filled, size: 14, color: countdownColor),
                const SizedBox(width: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text("$hours:$minutes:$seconds",
                      style: TextStyle(
                          color: countdownColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto')),
                ),
                const SizedBox(width: 4),
                Text(AppStrings.remaining,
                    style: TextStyle(color: countdownColor, fontSize: 10)),
              ],
            ),
          ],
        );
      }
    }

    if (task.description.isNotEmpty) {
      return Text(
        task.description,
        style: TextStyle(
          color: task.description.contains(":") ? accent : textMuted,
          fontWeight: task.description.contains(":")
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );
    }
    return null;
  }

  IconData _taskIcon(TaskItem task) {
    if (task.name.contains(kProphetPrayer)) {
      return Icons.favorite;
    }
    if (task.name.contains(kAthkarLabel)) {
      return Icons.auto_awesome;
    }
    if (task.name.contains(kQuranWird)) {
      return Icons.menu_book;
    }
    if (task.name.contains(kPrayerFajr) ||
        task.name.contains(kPrayerDhuhr) ||
        task.name.contains(kPrayerAsr) ||
        task.name.contains(kPrayerMaghrib) ||
        task.name.contains(kPrayerIsha)) {
      return Icons.mosque;
    }
    return Icons.check_circle_outline;
  }

  Color _taskAccent(TaskItem task, bool isDark) {
    if (task.name.contains(kProphetPrayer)) {
      return isDark ? const Color(0xFFF48FB1) : const Color(0xFFD81B60);
    }
    if (task.name.contains(kAthkarLabel)) {
      return isDark ? const Color(0xFFFFCC80) : const Color(0xFFF57C00);
    }
    if (task.name.contains(kQuranWird)) {
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1E88E5);
    }
    if (task.name.contains(kPrayerFajr) ||
        task.name.contains(kPrayerDhuhr) ||
        task.name.contains(kPrayerAsr) ||
        task.name.contains(kPrayerMaghrib) ||
        task.name.contains(kPrayerIsha)) {
      return isDark ? const Color(0xFF4DD0E1) : const Color(0xFF006064);
    }
    return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
  }
}
