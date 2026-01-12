import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tasks_view_model.dart';

class DailyInspirationCard extends StatelessWidget {
  final TasksViewModel vm;
  final bool isDark;

  const DailyInspirationCard(
      {super.key, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    bool isQuran = vm.isInspirationQuran;
    Color contentColor = isDark
        ? Colors.white
        : (isQuran ? const Color(0xFF004D40) : Colors.teal[900]!);
    Color iconColor =
        isQuran ? const Color(0xFFD4AF37) : Colors.orange; // Gold for Quran

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : (isQuran ? const Color(0xFFE0F2F1) : const Color(0xFFE0F2F1)),
        gradient: isQuran && !isDark
            ? const LinearGradient(colors: [Color(0xFFE0F2F1), Colors.white])
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : (isQuran ? const Color(0xFF80CBC4) : Colors.teal.shade100),
        ),
        boxShadow: isQuran && !isDark
            ? [
                BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isQuran ? Icons.auto_stories : Icons.lightbulb_outline,
                  color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                isQuran ? "آية اليوم" : "همسة اليوم",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.teal[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isQuran
                ? "﴿ ${vm.currentInspiration} ﴾"
                : "\"${vm.currentInspiration}\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              // Amiri is nice for Arabic quotes and Quran
              fontSize: 18,
              fontWeight: isQuran ? FontWeight.bold : FontWeight.normal,
              fontStyle: isQuran ? FontStyle.normal : FontStyle.italic,
              color: contentColor,
              height: 1.6,
            ),
          )
        ],
      ),
    );
  }
}
