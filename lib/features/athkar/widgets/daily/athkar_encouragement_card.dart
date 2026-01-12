import 'package:flutter/material.dart';
import '../../providers/athkar_view_model.dart';

class AthkarEncouragementCard extends StatelessWidget {
  final AthkarDataState data;

  const AthkarEncouragementCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151B20) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final iconColor =
        isDark ? const Color(0xFFFFCC80) : const Color(0xFFF57C00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.2 : 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_emotions, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.encouragement,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
