import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
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
            _buildChartSection(isDark),
            const SizedBox(height: 24),
            _buildTotalTasbeehSection(tasbeehVM.totalCounter, isDark),
            const SizedBox(height: 24),
            _buildBadgesSection(tasbeehVM.totalCounter, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
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
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (morningStreak > eveningStreak ? (morningStreak > sleepStreak ? morningStreak : sleepStreak) : (eveningStreak > sleepStreak ? eveningStreak : sleepStreak)).toDouble() + 5,
                barTouchData: const BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
                        switch (value.toInt()) {
                          case 0: return const Text('صباح', style: style);
                          case 1: return const Text('مساء', style: style);
                          case 2: return const Text('نوم', style: style);
                          default: return const Text('');
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
                  _makeBarGroup(0, morningStreak.toDouble(), Colors.orange),
                  _makeBarGroup(1, eveningStreak.toDouble(), Colors.indigo),
                  _makeBarGroup(2, sleepStreak.toDouble(), Colors.deepPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 25,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0,
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

  Widget _buildBadgesSection(int totalTasbeeh, bool isDark) {
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
              morningStreak >= 7,
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
              eveningStreak >= 3,
              Icons.nightlight_round,
              Colors.indigo,
              isDark,
            ),
            _buildBadge(
              "نور الليل",
              "10 أيام نوم",
              sleepStreak >= 10,
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
              morningStreak >= 30,
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
