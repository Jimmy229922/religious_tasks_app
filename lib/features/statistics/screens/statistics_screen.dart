import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsScreen extends StatelessWidget {
  final int morningStreak;
  final int eveningStreak;
  final int sleepStreak;

  const StatisticsScreen({
    super.key,
    required this.morningStreak,
    required this.eveningStreak,
    this.sleepStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("حماس الأذكار"),
          centerTitle: true,
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "استمرارك في الأذكار",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "\"أحب الأعمال إلى الله أدومها وإن قل\"",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Streaks Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildStreakCard(
                    title: "أذكار الصباح",
                    count: morningStreak,
                    color: Colors.amber,
                    icon: Icons.wb_sunny_rounded,
                    width: (MediaQuery.of(context).size.width - 60) /
                        2, // Half width approx
                  ),
                  _buildStreakCard(
                    title: "أذكار المساء",
                    count: eveningStreak,
                    color: Colors.indigo,
                    icon: Icons.nights_stay_rounded,
                    width: (MediaQuery.of(context).size.width - 60) / 2,
                  ),
                  _buildStreakCard(
                    title: "أذكار النوم",
                    count: sleepStreak, // Add this param to constructor
                    color: Colors.deepPurple,
                    icon: Icons.bed_rounded,
                    width: double.infinity, // Full width for the 3rd one
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$count",
                style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "يوم",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(FontAwesomeIcons.fire, color: Colors.orange, size: 18),
        ],
      ),
    );
  }
}
