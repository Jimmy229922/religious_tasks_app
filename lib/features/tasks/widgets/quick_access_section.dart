import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import 'package:religious_tasks_app/features/athkar/screens/duaa_safar_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/halqat_dhikr_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/khatmah_screen.dart';
import 'package:religious_tasks_app/features/tasbeeh/screens/custom_tasbeeh_screen.dart';
import 'package:religious_tasks_app/features/radio/screens/radio_screen.dart';
import 'package:religious_tasks_app/features/names_of_allah/screens/names_of_allah_screen.dart';
import 'package:religious_tasks_app/features/ruqyah/screens/ruqyah_screen.dart';

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
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("قريباً إن شاء الله"),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isDark,
            const Color(0xFF6A1B9A), // Deep Purple
            isLocked: true,
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "الرقية الشرعية",
            Icons.record_voice_over_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RuqyahScreen())),
            isDark,
            const Color(0xFF0F766E), // Teal Ruqyah
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "أسماء الله",
            Icons.stars_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NamesOfAllahScreen())),
            isDark,
            const Color(0xFFD97706), // Amber Gold
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
            "دعاء السفر",
            Icons.flight_takeoff_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DuaaSafarScreen())),
            isDark,
            const Color(0xFF0288D1), // Azure Blue
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "راديو القرآن",
            Icons.radio,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RadioScreen())),
            isDark,
            const Color(0xFFE53935), // Red
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
      IconData icon, VoidCallback onTap, bool isDark, Color baseColor,
      {bool isLocked = false}) {
    final itemContent = Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? baseColor.withValues(alpha: 0.4)
              : baseColor.withValues(alpha: 0.22),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: isDark ? 0.15 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isDark ? baseColor.withValues(alpha: 0.9) : baseColor,
                size: 26),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
          )
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: isLocked
          ? Stack(
              children: [
                itemContent,
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.amberAccent,
                          size: 22,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "قريباً",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : itemContent,
    );
  }
}
