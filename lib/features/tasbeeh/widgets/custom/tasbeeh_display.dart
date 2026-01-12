import 'package:flutter/material.dart';

class TasbeehDisplay extends StatelessWidget {
  final String text;

  const TasbeehDisplay({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151E1C) : Colors.white;
    final surfaceBorder = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1D1B);
    final accentSoft =
        isDark ? const Color(0xFF4CAF50) : const Color(0xFF43A047);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.95 : 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: accentSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.isEmpty ? 'اختر ذكراً أو اكتب ذكراً مخصصاً' : text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
