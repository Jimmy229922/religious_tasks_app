import 'package:flutter/material.dart';
import 'package:religious_tasks_app/core/constants/app_constants.dart';
import '../../providers/athkar_view_model.dart';

class DailyAthkarCard extends StatelessWidget {
  final AthkarDataState data;
  final bool isMorning;
  final VoidCallback onTap;

  const DailyAthkarCard({
    super.key,
    required this.data,
    required this.isMorning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));
    final surface = isDark ? const Color(0xFF151B20) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final progress = isMorning ? data.morning : data.evening;
    final label = isMorning ? kAthkarMorning : kAthkarEvening;
    final statusLabel = progress.isComplete
        ? 'مكتملة'
        : (progress.current > 0 ? 'تابع' : 'ابدأ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.22 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'التقدم: ${progress.current} / ${progress.total}',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 8,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
