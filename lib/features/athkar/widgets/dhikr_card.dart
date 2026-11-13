import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';

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
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
        : (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5));

    final isDone = item.current >= item.count;
    final progress = item.count == 0 ? 0.0 : item.current / item.count;

    final surface = isDone
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
        : (trueBlackMode
            ? Colors.black
            : (isDark ? const Color(0xFF141A1E) : Colors.white));

    final border = isDone
        ? (isDark ? Colors.teal.shade400 : Colors.teal.shade600)
        : (trueBlackMode
            ? Colors.white24
            : (isDark ? Colors.white10 : Colors.black12));

    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final rewardColor = isDark ? Colors.white70 : const Color(0xFF475569);

    final rewardText =
        item.reward.trim().isEmpty ? fallbackReward : item.reward;
    final double textSize = _scaled(isFocus ? 22 : 18);
    final double rewardSize = _scaled(isFocus ? 13 : 12);

    return InkWell(
      onTap: () {
        if (!isDone) {
          HapticFeedback.lightImpact();
          onIncrement(index);
        } else {
          HapticFeedback.mediumImpact();
        }
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: border,
            width: isDone ? 2 : 1,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(isFocus ? 20 : 16),
          child: Column(
            children: [
              // Header Row: Audio Button + Card Generator Button + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isDone) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "تم بحمد الله",
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          "الذكر ${index + 1} من $totalCount",
                          style: GoogleFonts.cairo(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.style_rounded,
                            color: Colors.teal, size: 20),
                        tooltip: "صانع البطاقات الإيمانية",
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => IslamicCardGeneratorDialog(
                              title: isMorning ? "أذكار الصباح 🌅" : "أذكار المساء 🌌",
                              content: item.text,
                              subtitle: item.reward,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      if (!isFocus)
                        GestureDetector(
                          onTap: () => onSpeak(index),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isPlaying
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_rounded,
                              key: ValueKey(isPlaying),
                              size: 22,
                              color: isPlaying ? accent : textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dhikr Main Text
              _buildDhikrText(item.text, textPrimary, accent, textSize),

              const SizedBox(height: 16),

              // Reward / Virtue Section
              if (rewardText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trueBlackMode
                        ? Colors.white10
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.amber, size: rewardSize + 4),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rewardText,
                          style: GoogleFonts.cairo(
                            color: rewardColor,
                            fontSize: rewardSize,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Interactive Circular Tap Counter Button Section
              Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Smooth Circular Progress Indicator
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 250),
                        builder: (context, val, child) {
                          return SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: val,
                              strokeWidth: 4.5,
                              backgroundColor: trueBlackMode
                                  ? Colors.white24
                                  : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                              color: isDone ? const Color(0xFF10B981) : accent,
                            ),
                          );
                        },
                      ),

                      // Center Counter Text / Done Checkmark
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF10B981)
                              : accent.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item.count - item.current}',
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'متبقي',
                                      style: TextStyle(
                                        color: accent.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
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
    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.8,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );

    final unifiedText = text
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'[\v\f\t\u2028\u2029\u0085]+'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceAll(RegExp(r' *\n *'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (unifiedText.contains('﴿') ||
        unifiedText.contains('۝') ||
        unifiedText.contains('«')) {
      return QuranTextFormatter.buildFormattedQuranText(
        unifiedText,
        baseStyle: baseStyle,
        badgeColor: const Color(0xFFD4AF37),
      );
    }

    return Text(
      unifiedText,
      textAlign: TextAlign.center,
      style: baseStyle,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: 1.8,
        forceStrutHeight: true,
      ),
    );
  }
}
