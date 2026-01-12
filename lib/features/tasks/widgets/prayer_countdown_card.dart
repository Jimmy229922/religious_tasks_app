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
        gradientColors = [
          const Color(0xFF141E30),
          const Color(0xFF243B55)
        ]; // Deep Night
        timeIcon = Icons.nights_stay_rounded;
        break;
      case Prayer.sunrise:
        gradientColors = [
          const Color(0xFFcc2b5e),
          const Color(0xFF753a88)
        ]; // Purple Sunrise
        timeIcon = Icons.wb_twilight_rounded;
        break;
      case Prayer.dhuhr:
        gradientColors = [
          const Color(0xFF2980B9),
          const Color(0xFF6DD5FA)
        ]; // Blue Sky
        timeIcon = Icons.wb_sunny_rounded;
        break;
      case Prayer.asr:
        gradientColors = [
          const Color(0xFFFF8008),
          const Color(0xFFFFC837)
        ]; // Orange Afternoon
        timeIcon = Icons.wb_sunny_outlined;
        break;
      case Prayer.maghrib:
        gradientColors = [
          const Color(0xFF8E2DE2),
          const Color(0xFF4A00E0)
        ]; // Twilight Purple
        timeIcon = Icons.wb_twilight_sharp;
        break;
      case Prayer.isha:
        gradientColors = [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364)
        ]; // Dark Night
        timeIcon = Icons.bedtime_rounded;
        break;
      default:
        gradientColors = [const Color(0xFF141E30), const Color(0xFF243B55)];
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
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الصلاة القادمة",
                    style: GoogleFonts.cairo(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeBlock(seconds, "ثانية"),
                _buildSeparator(),
                _buildTimeBlock(minutes, "دقيقة"),
                _buildSeparator(),
                _buildTimeBlock(hours, "ساعة"),
              ],
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
