import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/core/constants/strings.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../models/task_item.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskItem task;
  final int index;
  final bool isDark;
  final DateTime now;
  final PrayerTimes? prayerTimes;
  final PrayerTimes? prayerTimesTomorrow;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onIncrement;
  final bool compactGridCard;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.index,
    required this.isDark,
    required this.now,
    required this.onTap,
    this.onToggle,
    this.onIncrement,
    this.prayerTimes,
    this.prayerTimesTomorrow,
    this.compactGridCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isProphetPrayer = task.name.contains(kProphetPrayer);
    final isCounterTask = task.targetCount > 1 && !isProphetPrayer;
    final isAthkar = task.name.contains(kAthkarLabel);
    final accent = _taskAccent(task, isDark);
    final icon = _taskIcon(task);
    final surface = isDark ? const Color(0xFF172231) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF64748B);

    if (compactGridCard) {
      return _buildGridTile(
        context,
        isProphetPrayer: isProphetPrayer,
        isCounterTask: isCounterTask,
        isAthkar: isAthkar,
        accent: accent,
        icon: icon,
        surface: surface,
        textPrimary: textPrimary,
        textMuted: textMuted,
      );
    }

    final Widget? subtitleWidget = _buildSubtitle(accent, textMuted, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCounterTask ? onIncrement : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: task.isCompleted
                  ? accent.withValues(alpha: isDark ? 0.50 : 0.42)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : const Color(0xFFCBD5E1)),
              width: task.isCompleted ? 1.45 : 1.25,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: 12,
                bottom: 12,
                start: 10,
                width: 4.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(22, 13, 13, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: isDark ? 0.34 : 0.24),
                        ),
                      ),
                      child: Icon(icon, color: accent, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.name,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              height: 1.3,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted ? textMuted : textPrimary,
                            ),
                          ),
                          if (subtitleWidget != null) ...[
                            const SizedBox(height: 5),
                            subtitleWidget,
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildCheckCircle(accent),
                        if (isCounterTask) ...[
                          const SizedBox(height: 8),
                          _buildCounterBadge(
                              "${task.currentCount}/${task.targetCount}",
                              accent),
                        ] else if (isProphetPrayer) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCounterBadge(
                                  "${task.currentCount}/200", accent),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: textMuted,
                              ),
                            ],
                          ),
                        ] else if (isAthkar) ...[
                          const SizedBox(height: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: textMuted,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(
    BuildContext context, {
    required bool isProphetPrayer,
    required bool isCounterTask,
    required bool isAthkar,
    required Color accent,
    required IconData icon,
    required Color surface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final String statusText;
    double? barProgress;

    if (isProphetPrayer) {
      const target = 200;
      barProgress = (task.currentCount / target).clamp(0.0, 1.0);
      statusText = task.currentCount >= target
          ? "مكتمل 🎉 (200)"
          : "${task.currentCount} / 200";
    } else if (isCounterTask) {
      barProgress = (task.currentCount / task.targetCount).clamp(0.0, 1.0);
      statusText = "${task.currentCount} / ${task.targetCount}";
    } else if (task.isCompleted) {
      statusText = "تم الإنجاز ✓";
    } else if (isAthkar) {
      statusText = "ابدأ الأذكار ←";
    } else if (task.description.isNotEmpty) {
      statusText = task.description;
    } else {
      statusText = "اضغط للإتمام";
    }

    const completedBgLight = Color(0xFFF0FDF9);
    const completedBgDark = Color(0xFF0E2A26);
    final emerald = context.primaryColor;
    final emeraldLight = context.primaryLightColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCounterTask ? onIncrement : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? (isDark ? completedBgDark : completedBgLight)
                : surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: task.isCompleted
                  ? (isDark
                      ? emeraldLight.withValues(alpha: 0.56)
                      : emerald.withValues(alpha: 0.48))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : const Color(0xFFCBD5E1)),
              width: task.isCompleted ? 1.45 : 1.25,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: accent.withValues(alpha: isDark ? 0.34 : 0.24),
                          ),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      _buildCheckCircle(accent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.25,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? textMuted : textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  if (barProgress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: barProgress,
                        minHeight: 5,
                        backgroundColor: accent.withValues(alpha: 0.16),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: task.isCompleted || barProgress != null
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: task.isCompleted || barProgress != null
                          ? accent
                          : textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckCircle(Color accent) {
    return GestureDetector(
      onTap: onToggle ?? onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: task.isCompleted ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: task.isCompleted ? accent : accent.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        child: task.isCompleted
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _buildCounterBadge(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          fontWeight: FontWeight.bold,
          color: accent,
          fontSize: 11,
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

        return _PrayerItemCountdownWidget(
          target: target,
          description: task.description,
          accent: accent,
          isDark: isDark,
        );
      }
    }

    if (task.name.contains(kProphetPrayer)) {
      final remaining = (200 - task.currentCount).clamp(0, 200);
      final subtitleText = task.currentCount > 0
          ? (remaining > 0
              ? "${task.currentCount} من 200 (متبقي $remaining)"
              : "مكتمل 🎉 (200 من 200)")
          : AppStrings.count200;
      return Text(
        subtitleText,
        style: GoogleFonts.cairo(
          fontSize: 12.5,
          color: task.currentCount > 0 ? accent : textMuted,
          fontWeight:
              task.currentCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }

    if (task.description.isNotEmpty) {
      return Text(
        task.description,
        style: GoogleFonts.cairo(
          fontSize: 12.5,
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
      return Icons.favorite_rounded;
    }
    if (task.name.contains(kAthkarMorning)) {
      return Icons.wb_sunny_rounded;
    }
    if (task.name.contains(kAthkarEvening)) {
      return Icons.nights_stay_rounded;
    }
    if (task.name.contains(kAthkarSleep)) {
      return Icons.bedtime_rounded;
    }
    if (task.name.contains(kAthkarLabel)) {
      return Icons.spa_rounded;
    }
    if (task.name.contains(kPrayerQiyam) || task.name.contains('قيام')) {
      return Icons.dark_mode_rounded;
    }
    if (task.name.contains(kQuranWird)) {
      return Icons.menu_book_rounded;
    }
    if (task.name.contains(kPrayerFajr) ||
        task.name.contains(kPrayerDhuhr) ||
        task.name.contains(kPrayerAsr) ||
        task.name.contains(kPrayerMaghrib) ||
        task.name.contains(kPrayerIsha)) {
      return Icons.mosque_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Color _taskAccent(TaskItem task, bool isDark) {
    if (task.name.contains(kProphetPrayer)) {
      return isDark ? const Color(0xFFF48FB1) : const Color(0xFFD81B60);
    }
    if (task.name.contains(kAthkarMorning)) {
      return isDark ? const Color(0xFFFFCA68) : const Color(0xFFD97706);
    }
    if (task.name.contains(kAthkarEvening)) {
      return isDark ? const Color(0xFFB39DDB) : const Color(0xFF7C3AED);
    }
    if (task.name.contains(kAthkarSleep)) {
      return isDark ? const Color(0xFF818CF8) : const Color(0xFF3949AB);
    }
    if (task.name.contains(kAthkarLabel)) {
      return isDark ? const Color(0xFFFFCC80) : const Color(0xFFF57C00);
    }
    if (task.name.contains(kPrayerQiyam) || task.name.contains('قيام')) {
      return isDark ? const Color(0xFF9FA8DA) : const Color(0xFF4338CA);
    }
    if (task.name.contains(kQuranWird)) {
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1E88E5);
    }
    if (task.name.contains(kPrayerFajr) ||
        task.name.contains(kPrayerDhuhr) ||
        task.name.contains(kPrayerAsr) ||
        task.name.contains(kPrayerMaghrib) ||
        task.name.contains(kPrayerIsha)) {
      return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    }
    return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
  }
}

class _PrayerItemCountdownWidget extends StatefulWidget {
  final DateTime target;
  final String description;
  final Color accent;
  final bool isDark;

  const _PrayerItemCountdownWidget({
    required this.target,
    required this.description,
    required this.accent,
    required this.isDark,
  });

  @override
  State<_PrayerItemCountdownWidget> createState() =>
      __PrayerItemCountdownWidgetState();
}

class __PrayerItemCountdownWidgetState
    extends State<_PrayerItemCountdownWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration diff = widget.target.difference(_currentTime);
    if (diff.isNegative) diff = Duration.zero;

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final countdownColor =
        widget.isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: GoogleFonts.cairo(
            color: widget.accent,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          runSpacing: 2,
          children: [
            Icon(Icons.access_time_filled, size: 13, color: countdownColor),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                "$hours:$minutes:$seconds",
                style: GoogleFonts.ibmPlexMono(
                  color: countdownColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              AppStrings.remaining,
              style: GoogleFonts.cairo(
                color: countdownColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
