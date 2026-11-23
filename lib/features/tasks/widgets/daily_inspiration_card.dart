import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import '../providers/tasks_view_model.dart';

class DailyInspirationCard extends StatelessWidget {
  final TasksViewModel vm;
  final bool isDark;

  const DailyInspirationCard({
    super.key,
    required this.vm,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isQuran = vm.isInspirationQuran;
    final String source = vm.currentInspirationSource.trim();
    final Color accent = isQuran
        ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));
    final Color contentColor =
        isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? (isQuran
                  ? const [Color(0xFF0F292E), Color(0xFF15202E)]
                  : const [Color(0xFF251F14), Color(0xFF181B24)])
              : (isQuran
                  ? const [Color(0xFFF0FDFA), Color(0xFFFFFFFF)]
                  : const [Color(0xFFFFFBEB), Color(0xFFFFFFFF)]),
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.52 : 0.38),
          width: 1.45,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final badge = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.38 : 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isQuran
                          ? Icons.menu_book_rounded
                          : Icons.format_quote_rounded,
                      color: accent,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isQuran ? "آية اليوم" : "همسة اليوم",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "تغيير الآية أو الهمسة",
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      vm.refreshRandomContent();
                    },
                    icon: Icon(Icons.refresh_rounded, color: accent, size: 20),
                  ),
                  IconButton(
                    tooltip: "نسخ",
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final textToCopy = isQuran
                          ? '﴿ ${vm.currentInspiration} ﴾${source.isNotEmpty ? ' — $source' : ''}'
                          : '«${vm.currentInspiration}»';
                      await Clipboard.setData(ClipboardData(text: textToCopy));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "تم النسخ بنجاح",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: const Color(0xFF0F766E),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      size: 18,
                    ),
                  ),
                  IconButton(
                    tooltip: "تصميم بطاقة",
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => IslamicCardGeneratorDialog(
                          title: isQuran ? "آية اليوم 📖" : "همسة اليوم 💛",
                          content: vm.currentInspiration,
                          subtitle: source.isNotEmpty ? source : null,
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.style_rounded,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      size: 19,
                    ),
                  ),
                ],
              );

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.6,
                    ),
                    child: badge,
                  ),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Column(
              key: ValueKey('${vm.currentInspiration}_$source'),
              children: [
                Text(
                  isQuran
                      ? "﴿ ${vm.currentInspiration} ﴾"
                      : "« ${vm.currentInspiration} »",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                    height: 1.7,
                  ),
                ),
                if (source.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.18)
                            : accent.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      source,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
