import 'package:flutter/material.dart';

class TasbeehCounter extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final bool isCompleted;

  const TasbeehCounter({
    super.key,
    required this.count,
    required this.onIncrement,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isCompleted 
        ? Colors.grey 
        : (isDark ? const Color(0xFF7BE495) : const Color(0xFF1B5E20));
    final textMuted = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: isCompleted ? null : onIncrement,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: isDark ? 0.28 : 0.15),
              isDark ? const Color(0xFF0E1E18) : const Color(0xFFFDFEFD),
            ],
          ),
          border: Border.all(color: accent, width: 4),
          boxShadow: [
            if (!isCompleted)
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.35 : 0.2),
                blurRadius: 30,
                spreadRadius: 4,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isCompleted ? 'تم' : '$count',
              style: TextStyle(
                fontSize: isCompleted ? 60 : 80,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            Text(
              isCompleted ? 'الهدف المليون' : 'مرة',
              style: TextStyle(
                fontSize: 20,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
