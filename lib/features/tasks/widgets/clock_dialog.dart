import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/tasks_view_model.dart';

class ProfessionalClockDialog extends StatelessWidget {
  final TasksViewModel vm;
  final bool isDark;

  const ProfessionalClockDialog(
      {super.key, required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, snapshot) {
          final now = DateTime.now();
          final hour = intl.DateFormat('hh', 'ar').format(now);
          final minute = intl.DateFormat('mm', 'ar').format(now);
          final second = intl.DateFormat('ss', 'ar').format(now);
          final amPm = intl.DateFormat('a', 'ar').format(now);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? Colors.tealAccent.withValues(alpha: 0.3)
                      : Colors.teal.shade200,
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "الوقت الآن",
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white70 : Colors.teal[800],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                // Digital Clock Row
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDigitBox(hour, isDark),
                      _buildColon(isDark),
                      _buildDigitBox(minute, isDark),
                      _buildColon(isDark),
                      _buildDigitBox(second, isDark, isSeconds: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  amPm,
                  style: GoogleFonts.ibmPlexMono(
                    color: isDark ? Colors.tealAccent : Colors.teal[900],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: Text("إغلاق",
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDigitBox(String val, bool isDark, {bool isSeconds = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.teal.shade100, width: 1),
      ),
      child: Text(
        val,
        style: GoogleFonts.ibmPlexMono(
            color: isDark ? Colors.white : Colors.teal[900],
            fontSize: isSeconds ? 20 : 28,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildColon(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(":",
          style: GoogleFonts.ibmPlexMono(
              color: isDark ? Colors.white70 : Colors.teal[800],
              fontSize: 28,
              fontWeight: FontWeight.bold)),
    );
  }
}
