import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';

class AthkarHeader extends StatelessWidget {
  final String title;
  final bool isMorning;
  final bool isSleep;
  final int totalTarget;
  final int totalCurrent;
  final double progress;
  final bool allDone;

  const AthkarHeader({
    super.key,
    required this.title,
    required this.isMorning,
    this.isSleep = false,
    required this.totalTarget,
    required this.totalCurrent,
    required this.progress,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.appCardGradient,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: allDone
              ? const Color(0xFF10B981)
              : gold.withValues(alpha: isDark ? 0.55 : 0.75),
          width: 1.35,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : gold).withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: isDark ? 0.16 : 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gold.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(
                  isSleep
                      ? Icons.bedtime_rounded
                      : (isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
                  color: isDark ? goldLight : const Color(0xFF78350F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: isDark ? goldLight : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (allDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Text(
                    'مكتملة ✓',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF10B981),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0),
              color: allDone ? const Color(0xFF10B981) : gold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.ibmPlexMono(
                  color: isDark ? goldLight : const Color(0xFF78350F),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              Text(
                '$totalCurrent / $totalTarget',
                style: GoogleFonts.ibmPlexMono(
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
