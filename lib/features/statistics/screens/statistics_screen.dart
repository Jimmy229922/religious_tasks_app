import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:religious_tasks_app/core/services/athkar_tracking_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/features/settings/screens/settings_screen.dart';
import '../../tasbeeh/providers/tasbeeh_view_model.dart';
import 'achievements_screen.dart';

class StatisticsScreen extends StatelessWidget {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);

  final int morningStreak;
  final int eveningStreak;
  final int sleepStreak;
  final bool embedded;
  final ThemeProvider? themeProvider;

  const StatisticsScreen({
    super.key,
    required this.morningStreak,
    required this.eveningStreak,
    required this.sleepStreak,
    this.embedded = false,
    this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final tasbeehVM = Provider.of<TasbeehViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storedStreaks = AthkarTrackingService.loadStreaks();
    final effectiveMorningStreak =
        math.max(morningStreak, storedStreaks['morning'] ?? 0);
    final effectiveEveningStreak =
        math.max(eveningStreak, storedStreaks['evening'] ?? 0);
    final effectiveSleepStreak =
        math.max(sleepStreak, storedStreaks['sleep'] ?? 0);
    final todaySummary =
        AthkarTrackingService.loadTodayAthkarCompletionSummary();
    final allBadges = buildAchievementBadges(
      totalTasbeeh: tasbeehVM.totalCounter,
      morningStreak: effectiveMorningStreak,
      eveningStreak: effectiveEveningStreak,
      sleepStreak: effectiveSleepStreak,
    );

    final bodyContent = ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _buildStatsDomeHeader(
          context: context,
          isDark: isDark,
          badgesCount: allBadges.length,
        ),
        const SizedBox(height: 16),
        _buildTodayReadChartSection(context, todaySummary, isDark),
        const SizedBox(height: 16),
        _buildStreakChartSection(
          context,
          effectiveMorningStreak,
          effectiveEveningStreak,
          effectiveSleepStreak,
          isDark,
        ),
        const SizedBox(height: 16),
        _buildTotalTasbeehSection(context, tasbeehVM.totalCounter, isDark),
        const SizedBox(height: 20),
        _buildBadgesSection(
          context,
          allBadges,
          tasbeehVM.totalCounter,
          effectiveMorningStreak,
          effectiveEveningStreak,
          effectiveSleepStreak,
          isDark,
        ),
      ],
    );

    if (embedded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: bodyContent,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.appBgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(child: bodyContent),
        ),
      ),
    );
  }

  Widget _buildStatsDomeHeader({
    required BuildContext context,
    required bool isDark,
    required int badgesCount,
  }) {
    final accent = context.primaryColor;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A241D), Color(0xFF0F2D24)]
              : const [Color(0xFFFFFDF7), Color(0xFFF6EED9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(22),
        ),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _gold).withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StatsArchLatticePainter(
                color: _gold.withValues(alpha: isDark ? 0.12 : 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (embedded)
                  _buildCircleHeaderBtn(
                    icon: Icons.settings_outlined,
                    tooltip: 'الإعدادات',
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  )
                else
                  _buildCircleHeaderBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'رجوع',
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.pop(context),
                  ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إحصائيات الإيمان',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? _goldLight : context.primaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: isDark ? 0.16 : 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
                          ),
                        ),
                        child: Text(
                          '$badgesCount وسام إنجاز متاح',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? _goldLight : const Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (themeProvider != null)
                  _buildCircleHeaderBtn(
                    icon: isDark
                        ? Icons.wb_sunny_rounded
                        : Icons.nights_stay_rounded,
                    tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                    isDark: isDark,
                    accent: accent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider!.toggleTheme(!isDark);
                    },
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleHeaderBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? _goldLight : accent,
          ),
        ),
      ),
    );
  }

  BoxDecoration _goldCardDecoration(BuildContext context, bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: context.appCardGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
        width: 1.25,
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : _gold).withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildCardTitleRow(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _gold.withValues(alpha: isDark ? 0.16 : 0.14),
            border: Border.all(color: _gold.withValues(alpha: 0.45)),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isDark ? _goldLight : context.primaryColor,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayReadChartSection(
    BuildContext context,
    Map<String, ({int completed, int total})> summary,
    bool isDark,
  ) {
    final m = summary['morning'] ?? (completed: 0, total: 0);
    final e = summary['evening'] ?? (completed: 0, total: 0);
    final s = summary['sleep'] ?? (completed: 0, total: 0);
    double pct(({int completed, int total}) item) =>
        item.total == 0 ? 0.0 : (item.completed / item.total) * 100.0;
    const maxY = 100.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _goldCardDecoration(context, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitleRow(
            context,
            "أذكار اليوم المقروءة (مباشر)",
            Icons.bar_chart_rounded,
            isDark,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: const BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final style = GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        );
                        switch (value.toInt()) {
                          case 0:
                            return Text('صباح (${m.completed}/${m.total})',
                                style: style);
                          case 1:
                            return Text('مساء (${e.completed}/${e.total})',
                                style: style);
                          case 2:
                            return Text('نوم (${s.completed}/${s.total})',
                                style: style);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, pct(m), const Color(0xFF10B981), maxY),
                  _makeBarGroup(1, pct(e), _gold, maxY),
                  _makeBarGroup(2, pct(s), const Color(0xFF2DD4BF), maxY),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakChartSection(
    BuildContext context,
    int mStreak,
    int eStreak,
    int sStreak,
    bool isDark,
  ) {
    final maxVal = math.max(mStreak, math.max(eStreak, sStreak));
    final maxY = (maxVal + 5).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _goldCardDecoration(context, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitleRow(
            context,
            "نشاطك في الأذكار (أيام متتالية)",
            Icons.local_fire_department_rounded,
            isDark,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: const BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final style = GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        );
                        switch (value.toInt()) {
                          case 0:
                            return Text('صباح ($mStreak)', style: style);
                          case 1:
                            return Text('مساء ($eStreak)', style: style);
                          case 2:
                            return Text('نوم ($sStreak)', style: style);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(
                      0, mStreak.toDouble(), const Color(0xFFF59E0B), maxY),
                  _makeBarGroup(
                      1, eStreak.toDouble(), const Color(0xFF10B981), maxY),
                  _makeBarGroup(2, sStreak.toDouble(), _gold, maxY),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(
    int x,
    double y,
    Color color,
    double maxY,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 26,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: color.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTasbeehSection(
      BuildContext context, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A241D), Color(0xFF0F2D24)]
              : const [Color(0xFFFFFDF7), Color(0xFFF6EED9)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.65 : 0.8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: isDark ? 0.14 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: isDark ? 0.18 : 0.16),
              border: Border.all(
                color: _gold.withValues(alpha: 0.65),
                width: 1.4,
              ),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: isDark ? _goldLight : const Color(0xFFB45309),
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "إجمالي التسبيحات",
            style: GoogleFonts.cairo(
              color: isDark ? _goldLight : const Color(0xFF78350F),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$total",
            style: GoogleFonts.ibmPlexMono(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tasbeehMotivationMessage(total),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _tasbeehMotivationMessage(int total) {
    if (total <= 0) {
      return "ابدأ الآن بتسبيحة واحدة، فبها يُفتح باب الخير والأجر 🌿";
    }
    if (total < 100) {
      return "بداية مباركة! واصل الذكر لتبلغ أول ١٠٠ تسبيحة ✨";
    }
    if (total < 1000) {
      return "جميل جداً! كل تسبيحة غرسٌ لك في الجنة، اقتربت من ١٠٠٠ تسبيحة 💛";
    }
    if (total < 5000) {
      return "ما شاء الله، لسانٌ رطبٌ بذكر الله — استمر نحو وسام السبّاح 🌟";
    }
    if (total < 10000) {
      return "همّة عالية مباركة! اقتربت من أعلى أوسمة التسبيح 🏆";
    }
    return "ما شاء الله تبارك الله، من الذاكرين الله كثيراً — ثبّتك الله ✨";
  }

  Widget _buildBadgesSection(
    BuildContext context,
    List<AchievementBadge> allBadges,
    int totalTasbeeh,
    int effectiveMorningStreak,
    int effectiveEveningStreak,
    int effectiveSleepStreak,
    bool isDark,
  ) {
    final previewBadges = allBadges.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: _gold.withValues(alpha: 0.45),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 18,
                    color: isDark ? _goldLight : context.primaryDarkColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "أوسمة الإنجاز",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? _goldLight : context.primaryDarkColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Divider(
                color: _gold.withValues(alpha: 0.45),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AchievementsScreen(
                    totalTasbeeh: totalTasbeeh,
                    morningStreak: effectiveMorningStreak,
                    eveningStreak: effectiveEveningStreak,
                    sleepStreak: effectiveSleepStreak,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: isDark ? 0.16 : 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 14,
                    color: isDark ? _goldLight : const Color(0xFF78350F),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "عرض المزيد (${allBadges.length})",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? _goldLight : const Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: previewBadges
              .map((badge) => buildAchievementBadgeCard(context, badge, isDark))
              .toList(),
        ),
      ],
    );
  }
}

class _StatsArchLatticePainter extends CustomPainter {
  final Color color;
  const _StatsArchLatticePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x <= size.width + step; x += step) {
      for (double y = 0; y <= size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - 9)
          ..lineTo(x + 9, y)
          ..lineTo(x, y + 9)
          ..lineTo(x - 9, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StatsArchLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}
