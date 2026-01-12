import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import 'package:religious_tasks_app/features/athkar/screens/halqat_dhikr_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/surah_kahf_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/khatmah_screen.dart';
import 'package:religious_tasks_app/features/tasbeeh/screens/custom_tasbeeh_screen.dart';

class QuickAccessSection extends StatelessWidget {
  final TasksViewModel vm;
  final bool isDark;

  const QuickAccessSection({super.key, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAccessItem(
            context,
            "القرآن الكريم",
            Icons.menu_book_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SurahKahfScreen())),
            isDark,
            const Color(0xFF6A1B9A), // Deep Purple
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "التسبيح",
            Icons.fingerprint,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CustomTasbeehScreen())),
            isDark,
            const Color(0xFF1565C0), // Rich Blue
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "القبلة",
            Icons.explore,
            () {
              final coords = vm.prayerTimes?.coordinates ??
                  Coordinates(21.4225, 39.8262); // Fallback to Makkah
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QiblaScreen(coordinates: coords)));
            },
            isDark,
            const Color(0xFF00695C), // Dark Teal
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "متابع الختمة",
            Icons.bookmark_added,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KhatmahScreen())),
            isDark,
            const Color(0xFFD4AF37), // Metallic Gold
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "حلقة الذكر",
            Icons.groups,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HalqatDhikrScreen())),
            isDark,
            const Color(0xFF66BB6A), // Softer Green
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "التقويم",
            Icons.calendar_month,
            () => showDialog(
              context: context,
              builder: (context) => const CalendarExplorerDialog(initialTab: 0),
            ),
            isDark,
            const Color(0xFF00ACC1), // Cyan/Teal
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, String label,
      IconData icon, VoidCallback onTap, bool isDark, Color baseColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E)
              : baseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? baseColor.withValues(alpha: 0.4)
                  : baseColor.withValues(alpha: 0.3)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: baseColor.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? baseColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isDark ? baseColor.withValues(alpha: 0.9) : baseColor,
                  size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87),
            )
          ],
        ),
      ),
    );
  }
}
