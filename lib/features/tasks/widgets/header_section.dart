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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151515)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white24,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _RingsPainter(
                          prayersProgress: vm.prayersProgress,
                          athkarProgress: vm.athkarProgress,
                          quranProgress: vm.quranProgress,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                intl.DateFormat('hh:mm')
                                    .format(vm.now), // 12-hour format
                                style: GoogleFonts.ibmPlexMono(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26, // Bigger font
                                    shadows: [
                                      Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ]),
                              ),
                              Text(
                                intl.DateFormat('a', 'ar')
                                    .format(vm.now), // AM/PM
                                style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Date & Location Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Weather Info Widget
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    vm.weatherInfo['temp'] ?? "",
                                    style: GoogleFonts.ibmPlexMono(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.cloud_outlined,
                                      color: Colors.white70, size: 16),
                                ],
                              ),
                              if (vm.weatherInfo['advice'] != null)
                                Text(
                                  vm.weatherInfo['advice']!,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                              Text(gregorianStr,
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text(hijriStr,
                                  style: GoogleFonts.arefRuqaa(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.tealAccent, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(vm.locationName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
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
