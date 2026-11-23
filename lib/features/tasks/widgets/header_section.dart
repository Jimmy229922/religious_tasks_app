import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;

import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import '../../prayers/screens/prayer_details_screen.dart';
import '../providers/tasks_view_model.dart';
import 'clock_dialog.dart';

class HeaderSection extends StatefulWidget {
  final TasksViewModel vm;
  final bool isDark;

  const HeaderSection({super.key, required this.vm, required this.isDark});

  static const Color _prayerRingColor = Color(0xFFD4AF37);
  static const Color _athkarRingColor = Color(0xFF10B981);
  static const Color _quranRingColor = Color(0xFF0EA5E9);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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

  String _greetingForHour(int hour) {
    if (hour >= 4 && hour < 12) return "صباح الخيرات والبركة";
    if (hour >= 12 && hour < 17) return "طاب يومك بذكر الله";
    if (hour >= 17 && hour < 21) return "مساء السكينة والطمأنينة";
    return "سكينة الليل وقيامه";
  }

  List<Color> _dashboardGradient() {
    if (!widget.isDark) {
      return const [Color(0xFFFFFFFF), Color(0xFFEEF7F5)];
    }

    final prayerTimes = widget.vm.prayerTimes;
    if (prayerTimes != null) {
      var nextPrayer = prayerTimes.nextPrayer();
      if (nextPrayer == Prayer.none) nextPrayer = Prayer.fajr;
      switch (nextPrayer) {
        case Prayer.fajr:
          return const [Color(0xFF0E1B2B), Color(0xFF16283E)];
        case Prayer.sunrise:
          return const [Color(0xFF281934), Color(0xFF182233)];
        case Prayer.dhuhr:
          return const [Color(0xFF0D253F), Color(0xFF142130)];
        case Prayer.asr:
          return const [Color(0xFF2B1C10), Color(0xFF172231)];
        case Prayer.maghrib:
          return const [Color(0xFF211438), Color(0xFF141E2F)];
        case Prayer.isha:
          return const [Color(0xFF0A2426), Color(0xFF111C2B)];
        default:
          break;
      }
    }
    return const [Color(0xFF0B2527), Color(0xFF141E2D)];
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final isDark = widget.isDark;
    final hijriDate = HijriCalendar.now();
    final hijriStr =
        "${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} هـ";
    final gregorianStr =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(_now);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final hasNextPrayer =
        vm.prayerTimes != null && vm.nextPrayerTime != null;
    final progressPercent = (vm.progress.clamp(0.0, 1.0) * 100).toInt();

    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF475569);
    final greetingColor =
        isDark ? const Color(0xFFFDE68A) : const Color(0xFF0F766E);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF0F766E).withValues(alpha: 0.12);
    final pillBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.9);
    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : const Color(0xFF0F766E).withValues(alpha: 0.28);
    final innerSurface = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.94);
    final innerBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFF0F766E).withValues(alpha: 0.24);
    final progressTrack = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFD9EAE5);
    final progressFill =
        isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _dashboardGradient(),
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? const Color(0xFFD4AF37).withValues(alpha: 0.50)
              : const Color(0xFF0F766E).withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F766E))
                .withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxWidth < 285 || textScale >= 1.26;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Greeting + Date + Location
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingForHour(_now.hour),
                        style: GoogleFonts.cairo(
                          color: greetingColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                const CalendarExplorerDialog(initialTab: 0),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 13.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF0F766E),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  "$hijriStr • $gregorianStr",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    color: secondaryText,
                                    fontSize: 11.5,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: pillBorder, width: 1.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF5EEAD4)
                              : const Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.52,
                          ),
                          child: Text(
                            vm.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: primaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: dividerColor, height: 1),
              const SizedBox(height: 12),

              // 2. Side-by-Side Next Prayer Countdown + Completion Dial on standard phones
              if (isCompact) ...[
                _buildCenterLeftBlock(
                  hasNextPrayer: hasNextPrayer,
                  isCompact: isCompact,
                  isDark: isDark,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                const SizedBox(height: 12),
                _buildRingsSummaryBlock(
                  progressPercent: progressPercent,
                  isCompact: isCompact,
                  isDark: isDark,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildCenterLeftBlock(
                        hasNextPrayer: hasNextPrayer,
                        isCompact: isCompact,
                        isDark: isDark,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildRingsSummaryBlock(
                      progressPercent: progressPercent,
                      isCompact: isCompact,
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // 3. Integrated Daily Progress Bar + Legend
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: innerSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: innerBorder, width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "إنجازك اليومي (${vm.completedCount} من ${vm.totalCount})",
                            style: GoogleFonts.cairo(
                              color: primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "$progressPercent%",
                          style: GoogleFonts.ibmPlexMono(
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF0F766E),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: vm.progress.clamp(0.0, 1.0),
                        minHeight: 6.5,
                        backgroundColor: progressTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(progressFill),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildLegendDot(
                          'الصلوات',
                          HeaderSection._prayerRingColor,
                          secondaryText,
                        ),
                        _buildLegendDot(
                          'الأذكار',
                          HeaderSection._athkarRingColor,
                          secondaryText,
                        ),
                        _buildLegendDot(
                          'القرآن',
                          HeaderSection._quranRingColor,
                          secondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCenterLeftBlock({
    required bool hasNextPrayer,
    required bool isCompact,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final vm = widget.vm;

    if (!hasNextPrayer) {
      return Column(
        crossAxisAlignment:
            isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFF0F766E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF0F766E).withValues(alpha: 0.26),
              ),
            ),
            child: Text(
              "الوقت الآن",
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : const Color(0xFF0F766E),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                intl.DateFormat('hh:mm a', 'ar').format(_now),
                style: GoogleFonts.ibmPlexMono(
                  color: primaryText,
                  fontSize: isCompact ? 24 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "تابع صلواتك وأذكارك اليوم بطمأنينة",
            textAlign: isCompact ? TextAlign.center : TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: secondaryText,
              fontSize: 11.5,
            ),
          ),
        ],
      );
    }

    final diff = vm.nextPrayerTime!.difference(_now);
    final duration = diff.isNegative ? Duration.zero : diff;
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final formattedTime =
        intl.DateFormat('hh:mm a', 'ar').format(vm.nextPrayerTime!);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final pName = vm.nextPrayerName;
        if (pName.isNotEmpty) {
          final taskIndex = vm.tasks.indexWhere((t) => t.name.contains(pName));
          final isDone =
              taskIndex != -1 ? vm.tasks[taskIndex].isCompleted : false;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrayerDetailsScreen(
                prayerName: "صلاة $pName",
                prayerTime: vm.nextPrayerTime,
                isCompleted: isDone,
                onToggleCompletion:
                    taskIndex != -1 ? () => vm.toggleTask(taskIndex) : null,
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment:
            isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: isCompact ? WrapAlignment.center : WrapAlignment.start,
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFD4AF37)
                        .withValues(alpha: isDark ? 0.62 : 0.72),
                    width: 1.1,
                  ),
                ),
                child: Text(
                  "الصلاة القادمة",
                  style: GoogleFonts.cairo(
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFF0F766E).withValues(alpha: 0.26),
                  ),
                ),
                child: Text(
                  formattedTime,
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white : const Color(0xFF0F766E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vm.nextPrayerName,
            style: GoogleFonts.arefRuqaa(
              color: primaryText,
              fontSize: isCompact ? 26 : 27,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeCell(hours, "س", isDark, primaryText, secondaryText),
                  _buildColon(isDark),
                  _buildTimeCell(
                      minutes, "د", isDark, primaryText, secondaryText),
                  _buildColon(isDark),
                  _buildTimeCell(
                      seconds, "ث", isDark, primaryText, secondaryText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCell(
    String val,
    String unit,
    bool isDark,
    Color primaryText,
    Color secondaryText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFF0F766E).withValues(alpha: 0.26),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            val,
            style: GoogleFonts.ibmPlexMono(
              color: primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            unit,
            style: GoogleFonts.cairo(
              color: secondaryText,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColon(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        ":",
        style: GoogleFonts.ibmPlexMono(
          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF0F766E),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRingsSummaryBlock({
    required int progressPercent,
    required bool isCompact,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final vm = widget.vm;
    final double dialSize = isCompact ? 92 : 88;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) =>
              ProfessionalClockDialog(vm: vm, isDark: isDark),
        );
      },
      child: SizedBox(
        width: dialSize,
        height: dialSize,
        child: CustomPaint(
          painter: _RingsPainter(
            prayersProgress: vm.prayersProgress,
            athkarProgress: vm.athkarProgress,
            quranProgress: vm.quranProgress,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(dialSize * 0.23),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$progressPercent%",
                      style: GoogleFonts.ibmPlexMono(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      intl.DateFormat('hh:mm').format(_now),
                      style: GoogleFonts.ibmPlexMono(
                        color: secondaryText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: textColor,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double prayersProgress;
  final double athkarProgress;
  final double quranProgress;

  _RingsPainter({
    required this.prayersProgress,
    required this.athkarProgress,
    required this.quranProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) - 4;
    const strokeWidth = 5.0;

    _drawRing(canvas, center, baseRadius, prayersProgress,
        HeaderSection._prayerRingColor, strokeWidth);
    _drawRing(canvas, center, baseRadius - 7.5, athkarProgress,
        HeaderSection._athkarRingColor, strokeWidth);
    _drawRing(canvas, center, baseRadius - 15, quranProgress,
        HeaderSection._quranRingColor, strokeWidth);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress,
      Color color, double width) {
    if (radius <= 0) return;
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.prayersProgress != prayersProgress ||
        oldDelegate.athkarProgress != athkarProgress ||
        oldDelegate.quranProgress != quranProgress;
  }
}
