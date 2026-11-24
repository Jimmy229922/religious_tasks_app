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
  final int? displayNumber;
  final int totalCount;
  final bool isFocus;
  final bool isMorning;
  final bool isSleep;
  final bool trueBlackMode;
  final double fontScale;
  final String fallbackReward;
  final Function(int) onIncrement;
  final VoidCallback? onOpenAction;
  final String? actionLabel;

  const DhikrCard({
    super.key,
    required this.item,
    required this.index,
    this.displayNumber,
    required this.totalCount,
    required this.isFocus,
    required this.isMorning,
    this.isSleep = false,
    required this.trueBlackMode,
    required this.fontScale,
    required this.fallbackReward,
    required this.onIncrement,
    this.onOpenAction,
    this.actionLabel,
  });

  double _scaled(double size) => size * fontScale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isMorning
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF0F766E))
        : (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5));

    final isDone = item.current >= item.count;
    final progress = item.count == 0 ? 0.0 : item.current / item.count;

    final surface = isDone
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
        : (trueBlackMode
            ? Colors.black
            : (isDark ? const Color(0xFF141A1E) : Colors.white));

    final border = isDone
        ? (isDark ? Colors.teal.shade400 : Colors.teal.shade600)
        : (trueBlackMode
            ? Colors.white24
            : (isDark ? Colors.white10 : accent.withValues(alpha: 0.22)));

    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white70 : Colors.grey.shade700;
    final rewardColor = isDark ? Colors.white70 : const Color(0xFF334155);

    final rewardText =
        item.reward.trim().isEmpty ? fallbackReward : item.reward;
    final double textSize = _scaled(isFocus ? 22 : 18);
    final double rewardSize = _scaled(isFocus ? 13 : 12);

    return InkWell(
      onTap: () {
        if (onOpenAction != null) {
          HapticFeedback.selectionClick();
          onOpenAction!();
          return;
        }
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
            width: isDone ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDone ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isFocus ? 20 : 16),
          child: Column(
            children: [
              // Header Row: Category Badge + Status Badge + Card Generator Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSleep
                            ? Icons.bedtime_rounded
                            : (isMorning
                                ? Icons.wb_sunny_rounded
                                : Icons.nights_stay_rounded),
                        color: accent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      if (isDone) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.18),
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
                          "الذكر ${displayNumber ?? (index + 1)} من $totalCount",
                          style: GoogleFonts.cairo(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.isOptional) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              "إضافي",
                              style: GoogleFonts.cairo(
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (item.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "ذكري",
                              style: GoogleFonts.cairo(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.style_rounded, color: accent, size: 20),
                    tooltip: "صانع البطاقات الإيمانية",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => IslamicCardGeneratorDialog(
                          title: isSleep
                              ? "أذكار النوم 🌙"
                              : (isMorning
                                  ? "أذكار الصباح 🌅"
                                  : "أذكار المساء 🌌"),
                          content: item.text,
                          subtitle: item.reward,
                        ),
                      );
                    },
                  ),
                ],
              ),

              Divider(height: 20, color: accent.withValues(alpha: 0.15)),

              // Dhikr Main Text with Amiri font style
              _buildDhikrText(item.text, textPrimary, accent, textSize),

              const SizedBox(height: 16),

              // Reward / Virtue Section (matching Ruqyah & Qiyam Layl info cards)
              if (rewardText.isNotEmpty) ...[
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showVirtueDetailsDialog(
                      context,
                      rewardText: rewardText,
                      accent: accent,
                      isDark: isDark,
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: trueBlackMode
                          ? Colors.white10
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : accent.withValues(alpha: 0.07)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.amber, size: 18),
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
                        const SizedBox(width: 6),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 15,
                          color: isDark ? Colors.amber.shade200 : accent,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (onOpenAction != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenAction,
                    icon: const Icon(Icons.menu_book_rounded, size: 19),
                    label: Text(
                      actionLabel ?? 'فتح في المصحف 📖',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone
                          ? const Color(0xFF10B981)
                          : accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Interactive Circular Tap Counter Button Section
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isDone) {
                      HapticFeedback.lightImpact();
                      onIncrement(index);
                    } else {
                      HapticFeedback.mediumImpact();
                    }
                  },
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
                                color:
                                    isDone ? const Color(0xFF10B981) : accent,
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
    final baseStyle = GoogleFonts.amiri(
      fontSize: fontSize,
      height: 1.85,
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
        height: 1.85,
        forceStrutHeight: true,
      ),
    );
  }

  void _showVirtueDetailsDialog(
    BuildContext context, {
    required String rewardText,
    required Color accent,
    required bool isDark,
  }) {
    final details = item.virtueDetails.trim().isNotEmpty
        ? item.virtueDetails.trim()
        : rewardText;
    final source = item.source.trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? const Color(0xFF141A1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "فضل الذكر وتخريجه",
                        style: GoogleFonts.cairo(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    rewardText,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber.shade200 : accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    height: 1.7,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
                  ),
                ),
                if (source.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: isDark ? Colors.amber.shade200 : accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "المرجع: $source",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "إغلاق",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
