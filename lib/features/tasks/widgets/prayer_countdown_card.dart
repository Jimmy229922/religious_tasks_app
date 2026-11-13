import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tasks_view_model.dart';

class PrayerCountdownCard extends StatefulWidget {
  final TasksViewModel vm;
  final bool isDark;

  const PrayerCountdownCard(
      {super.key, required this.vm, required this.isDark});

  @override
  State<PrayerCountdownCard> createState() => _PrayerCountdownCardState();
}

class _PrayerCountdownCardState extends State<PrayerCountdownCard> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update only this widget every second
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

    // Use local _now for calculation to enable smooth countdown
    final diff = widget.vm.nextPrayerTime!.difference(_now);
    final duration = diff.isNegative ? Duration.zero : diff;

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    // Dynamic Gradient & Icon based on Next Prayer
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
                const Color(0xFF0F766E),
                const Color(0xFF0D9488),
                const Color(0xFF14B8A6)
              ];
        timeIcon = Icons.bedtime_rounded;
        break;
      default:
        gradientColors = widget.isDark
            ? [const Color(0xFF141E30), const Color(0xFF243B55)]
            : [const Color(0xFF0F766E), const Color(0xFF14B8A6)];
        timeIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "الصلاة القادمة",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      widget.vm.nextPrayerName,
                      style: GoogleFonts.arefRuqaa(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(timeIcon, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeBlock(seconds, "ثانية"),
                  _buildSeparator(),
                  _buildTimeBlock(minutes, "دقيقة"),
                  _buildSeparator(),
                  _buildTimeBlock(hours, "ساعة"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ":",
        style: GoogleFonts.ibmPlexMono(
          color: Colors.white54,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
