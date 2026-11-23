import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/features/athkar/screens/duaa_safar_screen.dart';
import 'package:religious_tasks_app/features/happiness_jar/screens/happiness_jar_screen.dart';
import 'package:religious_tasks_app/features/names_of_allah/screens/names_of_allah_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_index_screen.dart';
import 'package:religious_tasks_app/features/quran/services/khatmah_planner_service.dart';
import 'package:religious_tasks_app/features/radio/screens/radio_screen.dart';
import 'package:religious_tasks_app/features/ruqyah/screens/ruqyah_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/features/tasks/screens/all_features_screen.dart';

class QuickAccessSection extends StatefulWidget {
  final TasksViewModel vm;
  final bool isDark;

  const QuickAccessSection({
    super.key,
    required this.vm,
    required this.isDark,
  });

  @override
  State<QuickAccessSection> createState() => _QuickAccessSectionState();
}

class _QuickAccessSectionState extends State<QuickAccessSection> {
  KhatmahPlan? _khatmahPlan;

  @override
  void initState() {
    super.initState();
    _loadKhatmahPlan();
  }

  Future<void> _loadKhatmahPlan() async {
    try {
      final plan = await KhatmahPlannerService.loadPlan();
      if (!mounted) return;
      setState(() {
        _khatmahPlan = plan;
      });
    } catch (_) {}
  }

  String _quranSpotlightSubtitle() {
    final plan = _khatmahPlan;
    if (plan != null) {
      final range = plan.getTodayRange();
      if (!range.isCompleted) {
        return "ورد اليوم: ص ${range.firstPage} – ${range.lastPage}";
      }
    }
    if (widget.vm.hasQuranBookmark) {
      return "${widget.vm.lastSurah} • آية ${widget.vm.lastAyah}";
    }
    return "المصحف وخطط الختمة";
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final isDark = widget.isDark;
    final coords =
        vm.prayerTimes?.coordinates ?? Coordinates(21.4225, 39.8262);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    const emeraldPrimary = Color(0xFF0F766E);
    const goldPrimary = Color(0xFFB45309);
    const slateIndigo = Color(0xFF1E3A5F);

    final spotlightQuran = _buildSpotlightTile(
      context: context,
      title: "القرآن الكريم",
      subtitle: _quranSpotlightSubtitle(),
      icon: Icons.menu_book_rounded,
      gradientColors: isDark
          ? const [Color(0xFF0E2A27), Color(0xFF152231)]
          : const [Color(0xFFECFDF5), Color(0xFFFFFFFF)],
      borderColor: isDark
          ? const Color(0xFF2DD4BF).withValues(alpha: 0.50)
          : emeraldPrimary.withValues(alpha: 0.42),
      iconColor: isDark ? const Color(0xFF2DD4BF) : emeraldPrimary,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuranIndexScreen()),
      ).then((_) => _loadKhatmahPlan()),
    );

    final spotlightJar = _buildSpotlightTile(
      context: context,
      title: "برطمان السعادة",
      subtitle: "اسحب رسالة تسرّ قلبك",
      icon: Icons.card_giftcard_rounded,
      gradientColors: isDark
          ? const [Color(0xFF281E0E), Color(0xFF17202D)]
          : const [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
      borderColor: isDark
          ? const Color(0xFFD4AF37).withValues(alpha: 0.54)
          : const Color(0xFFD97706).withValues(alpha: 0.48),
      iconColor: isDark ? const Color(0xFFFBBF24) : goldPrimary,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HappinessJarScreen()),
      ),
    );

    final List<Widget> secondaryTools = [
      _buildToolTile(
        context: context,
        label: "القبلة",
        icon: Icons.explore_rounded,
        color: emeraldPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QiblaScreen(coordinates: coords),
          ),
        ),
      ),
      _buildToolTile(
        context: context,
        label: "راديو القرآن",
        icon: Icons.radio_rounded,
        color: slateIndigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RadioScreen()),
        ),
      ),
      _buildToolTile(
        context: context,
        label: "الرقية الشرعية",
        icon: Icons.record_voice_over_rounded,
        color: emeraldPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RuqyahScreen()),
        ),
      ),
      _buildToolTile(
        context: context,
        label: "أسماء الله",
        icon: Icons.stars_rounded,
        color: goldPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()),
        ),
      ),
      _buildToolTile(
        context: context,
        label: "دعاء السفر",
        icon: Icons.flight_takeoff_rounded,
        color: slateIndigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DuaaSafarScreen()),
        ),
      ),
      _buildShowMoreItem(context),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stackSpotlights =
            constraints.maxWidth < 310 || textScale >= 1.28;

        final int columns;
        if (constraints.maxWidth >= 720 && textScale < 1.2) {
          columns = 6;
        } else if (constraints.maxWidth < 310 ||
            (constraints.maxWidth < 355 && textScale >= 1.28)) {
          columns = 2;
        } else {
          columns = 3;
        }

        final rows = <Widget>[];
        for (int i = 0; i < secondaryTools.length; i += columns) {
          final slice = secondaryTools.sublist(
            i,
            (i + columns) > secondaryTools.length
                ? secondaryTools.length
                : i + columns,
          );
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int j = 0; j < columns; j++) ...[
                  Expanded(
                    child: j < slice.length
                        ? slice[j]
                        : const SizedBox.shrink(),
                  ),
                  if (j < columns - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          );
          if (i + columns < secondaryTools.length) {
            rows.add(const SizedBox(height: 10));
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stackSpotlights) ...[
              spotlightQuran,
              const SizedBox(height: 10),
              spotlightJar,
            ] else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: spotlightQuran),
                    const SizedBox(width: 10),
                    Expanded(child: spotlightJar),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            ...rows,
          ],
        );
      },
    );
  }

  Widget _buildSpotlightTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? Colors.white70 : const Color(0xFF475569);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.4),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7.5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: isDark ? 0.36 : 0.26),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDark;
    final iconFg = isDark
        ? (color == const Color(0xFF1E3A5F)
            ? const Color(0xFF93C5FD)
            : color == const Color(0xFFB45309)
                ? const Color(0xFFFBBF24)
                : const Color(0xFF2DD4BF))
        : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? iconFg.withValues(alpha: 0.34)
                  : const Color(0xFFCBD5E1),
              width: 1.25,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconFg.withValues(alpha: isDark ? 0.18 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconFg.withValues(alpha: isDark ? 0.32 : 0.24),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconFg,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowMoreItem(BuildContext context) {
    final isDark = widget.isDark;
    const baseColor = Color(0xFF0F766E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllFeaturesScreen(vm: widget.vm),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0D2826), Color(0xFF132433)]
                  : const [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2DD4BF).withValues(alpha: 0.52)
                  : baseColor.withValues(alpha: 0.40),
              width: 1.35,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? baseColor.withValues(alpha: 0.28)
                      : baseColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? const Color(0xFF2DD4BF) : baseColor)
                        .withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: isDark ? const Color(0xFF2DD4BF) : baseColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "عرض المزيد",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF2DD4BF) : baseColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
