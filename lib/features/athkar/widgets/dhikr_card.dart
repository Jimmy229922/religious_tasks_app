import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dhikr_item.dart';

class DhikrCard extends StatelessWidget {
  final DhikrItem item;
  final int index;
  final int totalCount;
  final bool isFocus;
  final bool isMorning;
  final bool trueBlackMode;
  final bool isPlaying;
  final double fontScale;
  final String fallbackReward;
  final Function(int) onIncrement;
  final Function(int) onSpeak;

  const DhikrCard({
    super.key,
    required this.item,
    required this.index,
    required this.totalCount,
    required this.isFocus,
    required this.isMorning,
    required this.trueBlackMode,
    required this.isPlaying,
    required this.fontScale,
    required this.fallbackReward,
    required this.onIncrement,
    required this.onSpeak,
  });

  double _scaled(double size) => size * fontScale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));

    // True Black Logic
    final surface = trueBlackMode
        ? Colors.black
        : (isDark ? const Color(0xFF141A1E) : Colors.white);

    final border = trueBlackMode
        ? Colors.white24
        : (isDark ? Colors.white10 : Colors.black12);

    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final rewardColor = isDark ? Colors.white60 : const Color(0xFF546E7A);

    final isDone = item.current >= item.count;
    final progress = item.count == 0 ? 0.0 : item.current / item.count;
    final rewardText =
        item.reward.trim().isEmpty ? fallbackReward : item.reward;
    final double textSize = _scaled(isFocus ? 22 : 18);
    final double rewardSize = _scaled(isFocus ? 13 : 12);

    return InkWell(
      onTap: () {
        if (!isDone) onIncrement(index);
      },
      onLongPress: () async {
        final shareText =
            '${item.text}\n\n${item.reward.isNotEmpty ? item.reward : ""}';
        SharePlus.instance.share(ShareParams(text: shareText.trim()));
        await Clipboard.setData(ClipboardData(text: item.text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نسخ الذكر وفتح المشاركة')),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDone
              ? accent.withValues(alpha: trueBlackMode ? 0.2 : 0.1)
              : surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? accent : border,
            width: isDone ? 2 : 1,
          ),
          boxShadow: trueBlackMode
              ? []
              : [
                  BoxShadow(
                    color: isDone
                        ? accent.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: isDone ? 12 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isFocus ? 20 : 16),
          child: Column(
            children: [
              // Header Row: Count Badge + Audio Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (!isDone) onIncrement(index);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 16, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            '${item.current} / ${item.count}',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isFocus)
                    InkWell(
                      onTap: () => onSpeak(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isPlaying
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_rounded,
                            key: ValueKey(isPlaying),
                            size: 24,
                            color: isPlaying ? accent : textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Dhikr Text
              _buildDhikrText(item.text, textPrimary, accent, textSize),
              const SizedBox(height: 16),

              // Reward Section
              if (rewardText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trueBlackMode
                        ? Colors.white10
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.amber, size: rewardSize + 4),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rewardText,
                          style: TextStyle(
                            color: rewardColor,
                            fontSize: rewardSize,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  // True Black mode background handling
                  backgroundColor: trueBlackMode
                      ? Colors.white24
                      : (isDark ? Colors.white12 : Colors.grey[200]),
                  color: accent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDhikrText(
    String text,
    Color textPrimary,
    Color accent,
    double fontSize,
  ) {
    final parts = text.split('\n');
    if (parts.length == 1) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      );
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final clean = parts[i].trim();
      if (clean.isEmpty) {
        spans.add(const TextSpan(text: '\n\n'));
        continue;
      }
      final isHeading = clean.startsWith('سورة') || clean.startsWith('آية');
      spans.add(
        TextSpan(
          text: clean,
          style: TextStyle(
            fontWeight: isHeading ? FontWeight.bold : FontWeight.w600,
            color: isHeading ? accent : textPrimary,
          ),
        ),
      );
      if (i != parts.length - 1) {
        spans.add(const TextSpan(text: '\n\n'));
      }
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: fontSize, height: 1.6),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }
}
