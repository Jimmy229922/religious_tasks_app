import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import '../theme/mushaf_reader_theme.dart';

class MushafSectionStartToast extends StatefulWidget {
  final ValueNotifier<int> pageNotifier;
  final bool isDark;
  final int pageIndexOffset;
  final String? Function(int page)? extraTitleForPage;

  const MushafSectionStartToast({
    super.key,
    required this.pageNotifier,
    required this.isDark,
    this.pageIndexOffset = 0,
    this.extraTitleForPage,
  });

  @override
  State<MushafSectionStartToast> createState() =>
      _MushafSectionStartToastState();
}

class _MushafSectionStartToastState extends State<MushafSectionStartToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeCurve;
  Timer? _hideTimer;
  String? _title;
  String? _subtitle;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeCurve = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    widget.pageNotifier.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(covariant MushafSectionStartToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNotifier != widget.pageNotifier) {
      oldWidget.pageNotifier.removeListener(_onPageChanged);
      widget.pageNotifier.addListener(_onPageChanged);
    }
  }

  void _onPageChanged() {
    final page =
        (widget.pageNotifier.value + widget.pageIndexOffset).clamp(1, 604);
    final juz = QuranPageMapping.getJuzForPage(page);
    final hizb = QuranPageMapping.getHizbForPage(page);
    final isJuzStart =
        page == 1 || juz != QuranPageMapping.getJuzForPage(page - 1);
    final isHizbStart =
        page == 1 || hizb != QuranPageMapping.getHizbForPage(page - 1);
    final extraTitle = widget.extraTitleForPage?.call(page);

    _hideTimer?.cancel();
    if (!isJuzStart && !isHizbStart && extraTitle == null) {
      if (_fadeController.value > 0) {
        _fadeController.reverse();
      }
      return;
    }

    final arabicJuz = QuranTextFormatter.toArabicDigits(juz.toString());
    final arabicHizb = QuranTextFormatter.toArabicDigits(hizb.toString());
    String? sectionTitle;
    String? sectionSubtitle;
    if (isJuzStart) {
      sectionTitle = 'بداية الجزء $arabicJuz';
      sectionSubtitle = 'الحزب $arabicHizb';
    } else if (isHizbStart) {
      sectionTitle = 'بداية الحزب $arabicHizb';
      sectionSubtitle = 'الجزء $arabicJuz';
    }
    setState(() {
      if (extraTitle != null) {
        _title = extraTitle;
        _subtitle = sectionTitle == null
            ? null
            : isJuzStart
                ? '$sectionTitle • $sectionSubtitle'
                : sectionTitle;
      } else {
        _title = sectionTitle;
        _subtitle = sectionSubtitle;
      }
    });
    _fadeController.forward();
    _hideTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) _fadeController.reverse();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.pageNotifier.removeListener(_onPageChanged);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_title == null) return const SizedBox.shrink();
    final theme = MushafReaderTheme.of(widget.isDark);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Center(
          child: FadeTransition(
            opacity: _fadeCurve,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              decoration: BoxDecoration(
                color: theme.indicatorBackground.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.indicatorBorder.withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: widget.isDark ? 0.30 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.indicatorPrimaryText,
                    ),
                  ),
                  if (_subtitle != null)
                    Text(
                      _subtitle!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.indicatorAccent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
