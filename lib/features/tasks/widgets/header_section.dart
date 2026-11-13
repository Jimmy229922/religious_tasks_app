import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:hijri/hijri_calendar.dart';
import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import '../providers/tasks_view_model.dart';
import 'clock_dialog.dart';

class HeaderSection extends StatelessWidget {
  final TasksViewModel vm;
  final bool isDark;

  const HeaderSection({super.key, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hijriDate = HijriCalendar.now();
    final hijriStr =
        "${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}";
    final gregorianStr =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now());

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final cardBg = isDark ? const Color(0xFF151515) : Colors.white;
    final cardBorder = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
    final weatherBg = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9);
    final weatherBorder = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rings Section
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        ProfessionalClockDialog(vm: vm, isDark: isDark),
                  );
                },
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: _RingsPainter(
                      prayersProgress: vm.prayersProgress,
                      athkarProgress: vm.athkarProgress,
                      quranProgress: vm.quranProgress,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                intl.DateFormat('hh:mm')
                                    .format(vm.now), // 12-hour format
                                style: GoogleFonts.ibmPlexMono(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    shadows: isDark
                                        ? [
                                            const Shadow(
                                                color: Colors.black54,
                                                blurRadius: 4,
                                                offset: Offset(0, 2))
                                          ]
                                        : null),
                              ),
                              Text(
                                intl.DateFormat('a', 'ar')
                                    .format(vm.now), // AM/PM
                                style: GoogleFonts.cairo(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Date & Weather Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Weather Info Widget
                    if (vm.weatherInfo['temp'] != null &&
                        vm.weatherInfo['temp']!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: weatherBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: weatherBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vm.weatherInfo['temp']!,
                                  style: GoogleFonts.ibmPlexMono(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.cloud_outlined,
                                    color: secondaryTextColor, size: 16),
                              ],
                            ),
                            if (vm.weatherInfo['advice'] != null &&
                                vm.weatherInfo['advice']!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                vm.weatherInfo['advice']!,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: () {
                        // Open Calendar
                        showDialog(
                          context: context,
                          builder: (context) =>
                              const CalendarExplorerDialog(initialTab: 0),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              gregorianStr,
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hijriStr,
                              style: GoogleFonts.arefRuqaa(
                                  color: secondaryTextColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_rounded,
                  color: isDark ? Colors.tealAccent : Colors.teal, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(vm.locationName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
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
    final baseRadius = size.width / 2;
    const strokeWidth = 6.0;

    _drawRing(canvas, center, baseRadius, prayersProgress,
        const Color(0xFFFFD700), strokeWidth);
    _drawRing(canvas, center, baseRadius - 8, athkarProgress,
        const Color(0xFF00E676), strokeWidth);
    _drawRing(canvas, center, baseRadius - 16, quranProgress,
        const Color(0xFF00B0FF), strokeWidth);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress,
      Color color, double width) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
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
      final sweepAngle = 2 * math.pi * progress;
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
