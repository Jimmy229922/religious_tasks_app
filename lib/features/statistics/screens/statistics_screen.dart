import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:religious_tasks_app/core/services/athkar_tracking_service.dart';
import '../../tasbeeh/providers/tasbeeh_view_model.dart';

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
    final todayCounts = AthkarTrackingService.loadTodayAthkarReadCounts();

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
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTodayReadChartSection(todayCounts, isDark),
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

  Widget _buildTodayReadChartSection(Map<String, int> counts, bool isDark) {
    final mCount = counts['morning'] ?? 0;
    final eCount = counts['evening'] ?? 0;
    final sCount = counts['sleep'] ?? 0;
    final maxVal = math.max(mCount, math.max(eCount, sCount));
    final maxY = (maxVal < 10 ? 10 : maxVal + (maxVal * 0.2).ceil()).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                        const style = TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11.5);
                        switch (value.toInt()) {
                          case 0:
                            return Text('صباح ($mCount)', style: style);
                          case 1:
                            return Text('مساء ($eCount)', style: style);
                          case 2:
                            return Text('نوم ($sCount)', style: style);
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
                  _makeBarGroup(0, mCount.toDouble(), Colors.teal, maxY),
                  _makeBarGroup(1, eCount.toDouble(), Colors.indigo, maxY),
                  _makeBarGroup(2, sCount.toDouble(), Colors.deepPurple, maxY),
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
                        const style = TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11.5);
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
          const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 40),
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
          const Text("ما شاء الله، استمر في ذكر الله",
              style: TextStyle(
                  color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(
    int totalTasbeeh,
    int effectiveMorningStreak,
    int effectiveEveningStreak,
    int effectiveSleepStreak,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8.0, bottom: 12),
          child: Text("أوسمة الإنجاز",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: [
            _buildBadge(
              "المحافظ",
              "7 أيام فجر",
              effectiveMorningStreak >= 7,
              Icons.wb_twilight_rounded,
              Colors.orange,
              isDark,
            ),
            _buildBadge(
              "الذاكر",
              "1000 تسبيحة",
              totalTasbeeh >= 1000,
              Icons.favorite_rounded,
              Colors.redAccent,
              isDark,
            ),
            _buildBadge(
              "المثابر",
              "3 أيام مساء",
              effectiveEveningStreak >= 3,
              Icons.nightlight_round,
              Colors.indigo,
              isDark,
            ),
            _buildBadge(
              "نور الليل",
              "10 أيام نوم",
              effectiveSleepStreak >= 10,
              Icons.bed_rounded,
              Colors.deepPurple,
              isDark,
            ),
            _buildBadge(
              "السبّاح",
              "5000 تسبيحة",
              totalTasbeeh >= 5000,
              Icons.stars_rounded,
              Colors.amber,
              isDark,
            ),
            _buildBadge(
              "المخلص",
              "30 يوم فجر",
              effectiveMorningStreak >= 30,
              Icons.mosque_rounded,
              Colors.teal,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String title, String subtitle, bool isUnlocked, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.2,
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
              )),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isUnlocked
                    ? (isDark ? Colors.white70 : Colors.black54)
                    : Colors.grey,
              )),
        ],
      ),
    );
  }
}
