import 'package:flutter/material.dart';

class AthkarEmptyState extends StatelessWidget {
  final bool isMorning;
  final bool isNightMode;
  final bool showCompleted;
  final VoidCallback onShowCompleted;

  const AthkarEmptyState({
    super.key,
    required this.isMorning,
    required this.isNightMode,
    required this.showCompleted,
    required this.onShowCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // isDark logic passed from parent or Theme check?
    // Using passed isNightMode for consistency with other widgets
    final isDark = isNightMode;
    final surface = isDark ? const Color(0xFF12181C) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final accent = isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, color: accent, size: 30),
          const SizedBox(height: 8),
          Text(
            'ممتاز! أتممت كل الأذكار.',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك مراجعة الأذكار أو إظهار المكتملة لاحقا.',
            style: TextStyle(color: textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (!showCompleted) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onShowCompleted,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('عرض الأذكار المكتملة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
