import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MotivationalStatsDialog extends StatelessWidget {
  final bool isDark;
  final int morningStreak;
  final int eveningStreak;
  final int sleepStreak;

  const MotivationalStatsDialog({
    super.key,
    required this.isDark,
    required this.morningStreak,
    required this.eveningStreak,
    required this.sleepStreak,
  });

  static void show(BuildContext context,
      {required bool isDark,
      required int morningStreak,
      required int eveningStreak,
      required int sleepStreak}) {
    showDialog(
      context: context,
      builder: (ctx) => MotivationalStatsDialog(
        isDark: isDark,
        morningStreak: morningStreak,
        eveningStreak: eveningStreak,
        sleepStreak: sleepStreak,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? Colors.amberAccent : Colors.amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 50),
            const SizedBox(height: 16),
            Text(
              "أبطال الاستمرار",
              style: GoogleFonts.arefRuqaa(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildStreakRow(
                "أذكار الصباح", morningStreak, Colors.orange, isDark),
            const SizedBox(height: 12),
            _buildStreakRow(
                "أذكار المساء", eveningStreak, Colors.purpleAccent, isDark),
            const SizedBox(height: 12),
            _buildStreakRow(
                "أذكار النوم", sleepStreak, Colors.indigoAccent, isDark),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("استمر يا بطل",
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStreakRow(String title, int streak, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text("$streak",
                  style: GoogleFonts.ibmPlexMono(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              const Icon(Icons.local_fire_department,
                  color: Colors.redAccent, size: 18),
            ],
          )
        ],
      ),
    );
  }
}
