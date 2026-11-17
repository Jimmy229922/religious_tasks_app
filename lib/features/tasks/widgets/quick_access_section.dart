import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/features/athkar/screens/duaa_safar_screen.dart';
import 'package:religious_tasks_app/features/names_of_allah/screens/names_of_allah_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_index_screen.dart';
import 'package:religious_tasks_app/features/radio/screens/radio_screen.dart';
import 'package:religious_tasks_app/features/ruqyah/screens/ruqyah_screen.dart';
import 'package:religious_tasks_app/features/tasbeeh/screens/custom_tasbeeh_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/features/tasks/screens/all_features_screen.dart';

class QuickAccessSection extends StatelessWidget {
  final TasksViewModel vm;
  final bool isDark;

  const QuickAccessSection({
    super.key,
    required this.vm,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final coords =
        vm.prayerTimes?.coordinates ?? Coordinates(21.4225, 39.8262);

    final List<Widget> itemsRow1 = [
      _buildQuickAccessItem(
        context,
        "القرآن الكريم",
        Icons.menu_book_rounded,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QuranIndexScreen())),
        isDark,
        const Color(0xFF6A1B9A),
      ),
      _buildQuickAccessItem(
        context,
        "الرقية الشرعية",
        Icons.record_voice_over_rounded,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RuqyahScreen())),
        isDark,
        const Color(0xFF0F766E),
      ),
      _buildQuickAccessItem(
        context,
        "أسماء الله",
        Icons.stars_rounded,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const NamesOfAllahScreen())),
        isDark,
        const Color(0xFFD97706),
      ),
      _buildQuickAccessItem(
        context,
        "التسبيح",
        Icons.fingerprint_rounded,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CustomTasbeehScreen())),
        isDark,
        const Color(0xFF1565C0),
      ),
    ];

    final List<Widget> itemsRow2 = [
      _buildQuickAccessItem(
        context,
        "القبلة",
        Icons.explore_rounded,
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => QiblaScreen(coordinates: coords))),
        isDark,
        const Color(0xFF00695C),
      ),
      _buildQuickAccessItem(
        context,
        "دعاء السفر",
        Icons.flight_takeoff_rounded,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DuaaSafarScreen())),
        isDark,
        const Color(0xFF0288D1),
      ),
      _buildQuickAccessItem(
        context,
        "راديو القرآن",
        Icons.radio_rounded,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RadioScreen())),
        isDark,
        const Color(0xFFE53935),
      ),
      _buildShowMoreItem(context),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: itemsRow1.map((w) => Expanded(child: w)).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: itemsRow2.map((w) => Expanded(child: w)).toList(),
        ),
      ],
    );
  }

  Widget _buildShowMoreItem(BuildContext context) {
    const baseColor = Color(0xFF0F766E); // Deep Emerald Teal Accent

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllFeaturesScreen(vm: vm),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0D2826)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? baseColor.withValues(alpha: 0.6)
                  : const Color(0xFF0D9488).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : baseColor.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark
                      ? baseColor.withValues(alpha: 0.28)
                      : const Color(0xFF0D9488).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                  size: 22,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "عرض المزيد",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
    Color baseColor, {
    bool isLocked = false,
  }) {
    final itemContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? baseColor.withValues(alpha: 0.4)
              : baseColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : baseColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: isDark ? 0.18 : 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? baseColor.withValues(alpha: 0.95) : baseColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: isLocked
            ? Stack(
                children: [
                  itemContent,
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.72)
                            : Colors.amber.shade50.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.amber.withValues(alpha: 0.4)
                              : Colors.amber.shade400.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                            size: 18,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "قريباً",
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.white : Colors.amber.shade900,
                              fontSize: 10,
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
      ),
    );
  }
}
