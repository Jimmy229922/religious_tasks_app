import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';

class AthkarFocusNavigator extends StatelessWidget {
  final bool isMorning;
  final bool isNightMode;
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const AthkarFocusNavigator({
    super.key,
    required this.isMorning,
    required this.isNightMode,
    required this.currentIndex,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final isDark = isNightMode;
    final accent = isDark ? goldLight : context.primaryColor;
    final border = gold.withValues(alpha: isDark ? 0.5 : 0.65);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_right),
            label: Text(
              'السابق',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: isDark ? 0.18 : 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            '${currentIndex + 1} / $totalCount',
            style: GoogleFonts.ibmPlexMono(
              color: isDark ? goldLight : const Color(0xFF78350F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_left),
            label: Text(
              'التالي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
