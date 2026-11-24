import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../providers/tasks_view_model.dart';
import '../../prayers/screens/prayer_details_screen.dart';

class PrayerCountdownCard extends StatefulWidget {
  final TasksViewModel vm;
  final bool isDark;

  const PrayerCountdownCard({
    super.key,
    required this.vm,
    required this.isDark,
  });

  @override
  State<PrayerCountdownCard> createState() => _PrayerCountdownCardState();
}

class _PrayerCountdownCardState extends State<PrayerCountdownCard> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
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
    if (widget.vm.nextPrayerTime == null || widget.vm.prayerTimes == null) {
      return const SizedBox.shrink();
    }

    final diff = widget.vm.nextPrayerTime!.difference(_now);
    final duration = diff.isNegative ? Duration.zero : diff;

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final formattedTime =
        intl.DateFormat('hh:mm a', 'ar').format(widget.vm.nextPrayerTime!);

    var nextPrayer = widget.vm.prayerTimes!.nextPrayer();
    if (nextPrayer == Prayer.none) nextPrayer = Prayer.fajr;

    List<Color> gradientColors;
    IconData timeIcon;

    switch (nextPrayer) {
      case Prayer.fajr:
        gradientColors = widget.isDark
            ? [const Color(0xFF141E30), const Color(0xFF243B55)]
            : [const Color(0xFF1E3C72), const Color(0xFF2A5298)];
        timeIcon = Icons.nights_stay_rounded;
        break;
      case Prayer.sunrise:
        gradientColors = widget.isDark
            ? [const Color(0xFF753A88), const Color(0xFFCC2B5E)]
            : [const Color(0xFFEA580C), const Color(0xFFF97316)];
        timeIcon = Icons.wb_twilight_rounded;
        break;
      case Prayer.dhuhr:
        gradientColors = widget.isDark
            ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
            : [const Color(0xFF0288D1), const Color(0xFF00ACC1)];
        timeIcon = Icons.wb_sunny_rounded;
        break;
      case Prayer.asr:
        gradientColors = widget.isDark
            ? [const Color(0xFFE65100), const Color(0xFFBF360C)]
            : [const Color(0xFFF59E0B), const Color(0xFFD97706)];
        timeIcon = Icons.wb_sunny_outlined;
        break;
      case Prayer.maghrib:
        gradientColors = widget.isDark
            ? [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]
            : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)];
        timeIcon = Icons.wb_twilight_sharp;
        break;
      case Prayer.isha:
        gradientColors = widget.isDark
            ? [
                const Color(0xFF0F2027),
                const Color(0xFF203A43),
                const Color(0xFF2C5364)
              ]
            : [
                context.primaryColor,
                context.primaryDarkColor,
                context.primaryLightColor,
              ];
        timeIcon = Icons.bedtime_rounded;
        break;
      default:
        gradientColors = widget.isDark
            ? [const Color(0xFF141E30), const Color(0xFF243B55)]
            : [context.primaryColor, context.primaryLightColor];
        timeIcon = Icons.access_time_rounded;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 350;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              final pName = widget.vm.nextPrayerName;
              if (pName.isNotEmpty) {
                final taskIndex =
                    widget.vm.tasks.indexWhere((t) => t.name.contains(pName));
                final isDone = taskIndex != -1
                    ? widget.vm.tasks[taskIndex].isCompleted
                    : false;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrayerDetailsScreen(
                      prayerName: "صلاة $pName",
                      prayerTime: widget.vm.nextPrayerTime,
                      isCompleted: isDone,
                      onToggleCompletion: taskIndex != -1
                          ? () => widget.vm.toggleTask(taskIndex)
                          : null,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                boxShadow: widget.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: gradientColors.first.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "الصلاة القادمة",
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        color: Colors.white70,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        formattedTime,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.vm.nextPrayerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.arefRuqaa(
                                color: Colors.white,
                                fontSize: isCompact ? 24 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    "اضغط لعرض التفاصيل وأذكار بعد الصلاة",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.all(isCompact ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          timeIcon,
                          color: Colors.white,
                          size: isCompact ? 26 : 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 10 : 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTimeBlock(hours, "ساعة", isCompact),
                            _buildSeparator(isCompact),
                            _buildTimeBlock(minutes, "دقيقة", isCompact),
                            _buildSeparator(isCompact),
                            _buildTimeBlock(seconds, "ثانية", isCompact),
                          ],
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

  Widget _buildSeparator(bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8),
      child: Text(
        ":",
        style: GoogleFonts.ibmPlexMono(
          color: Colors.white60,
          fontSize: isCompact ? 20 : 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, String label, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              color: Colors.white,
              fontSize: isCompact ? 21 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
