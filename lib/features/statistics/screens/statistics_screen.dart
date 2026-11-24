import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:religious_tasks_app/core/services/athkar_tracking_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../../tasbeeh/providers/tasbeeh_view_model.dart';
import 'achievements_screen.dart';

class StatisticsScreen extends StatelessWidget {
  final int morningStreak;
  final int eveningStreak;
  final int sleepStreak;

  const StatisticsScreen({
    super.key,
    required this.morningStreak,
    required this.eveningStreak,
    required this.sleepStreak,
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("إحصائيات الإيمان",
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTodayReadChartSection(todaySummary, isDark),
            const SizedBox(height: 20),
            _buildStreakChartSection(
              effectiveMorningStreak,
              effectiveEveningStreak,
              effectiveSleepStreak,
              isDark,
            ),
            const SizedBox(height: 24),
            _buildTotalTasbeehSection(tasbeehVM.totalCounter, isDark),
            const SizedBox(height: 24),
            _buildBadgesSection(
              context,
              tasbeehVM.totalCounter,
              effectiveMorningStreak,
              effectiveEveningStreak,
              effectiveSleepStreak,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayReadChartSection(
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "أذكار اليوم المقروءة (مباشر)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        final style = TextStyle(
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
                  _makeBarGroup(0, pct(m), Colors.teal, maxY),
                  _makeBarGroup(1, pct(e), Colors.indigo, maxY),
                  _makeBarGroup(2, pct(s), Colors.deepPurple, maxY),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakChartSection(
    int mStreak,
    int eStreak,
    int sStreak,
    bool isDark,
  ) {
    final maxVal = math.max(mStreak, math.max(eStreak, sStreak));
    final maxY = (maxVal + 5).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("نشاطك في الأذكار (أيام متتالية)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
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
                        final style = TextStyle(
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
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, mStreak.toDouble(), Colors.orange, maxY),
                  _makeBarGroup(1, eStreak.toDouble(), Colors.indigo, maxY),
                  _makeBarGroup(2, sStreak.toDouble(), Colors.deepPurple, maxY),
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
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTasbeehSection(int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFF1565C0), const Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40),
          const SizedBox(height: 12),
          const Text("إجمالي التسبيحات",
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text("$total",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexMono')),
          const SizedBox(height: 8),
          Text(
            _tasbeehMotivationMessage(total),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
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
    int totalTasbeeh,
    int effectiveMorningStreak,
    int effectiveEveningStreak,
    int effectiveSleepStreak,
    bool isDark,
  ) {
    final allBadges = buildAchievementBadges(
      totalTasbeeh: totalTasbeeh,
      morningStreak: effectiveMorningStreak,
      eveningStreak: effectiveEveningStreak,
      sleepStreak: effectiveSleepStreak,
    );
    final previewBadges = allBadges.take(6).toList();
    final accent = context.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "أوسمة الإنجاز",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton.icon(
                onPressed: () {
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
                icon: Icon(Icons.grid_view_rounded, size: 16, color: accent),
                label: Text(
                  "عرض المزيد (${allBadges.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
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
