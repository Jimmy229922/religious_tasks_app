import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/qcf_mushaf_repository.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_opening_page_frame.dart';

class QcfMushafPageWidget extends StatefulWidget {
  final QcfMushafPageData pageData;
  final String? highlightedVerseKey;
  final bool isPageBookmarked;
  final double topInset;
  final bool isDark;
  final Color accentColor;
  final void Function(int surahNumber, int ayahNumber)? onTapVerse;
  final void Function(int surahNumber, int ayahNumber)? onLongPressVerse;

  const QcfMushafPageWidget({
    super.key,
    required this.pageData,
    required this.highlightedVerseKey,
    this.isPageBookmarked = false,
    this.topInset = 0.0,
    required this.isDark,
    required this.accentColor,
    this.onTapVerse,
    this.onLongPressVerse,
  });

  @override
  State<QcfMushafPageWidget> createState() => _QcfMushafPageWidgetState();
}

class _QcfMushafPageWidgetState extends State<QcfMushafPageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _highlightFadeController;
  List<_PreparedQcfLine>? _preparedLines;
  QcfMushafPageData? _preparedPageData;
  bool? _preparedIsDark;
  TextScaler? _preparedTextScaler;

  @override
  void initState() {
    super.initState();
    _highlightFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant QcfMushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedVerseKey != null &&
        widget.highlightedVerseKey != oldWidget.highlightedVerseKey) {
      _highlightFadeController.forward(from: 0.0);
    }
  }

  void _disposePreparedLines() {
    final existing = _preparedLines;
    if (existing != null) {
      for (final line in existing) {
        line.dispose();
      }
    }
    _preparedLines = null;
    _preparedPageData = null;
    _preparedIsDark = null;
    _preparedTextScaler = null;
  }

  List<_PreparedQcfLine> _ensureLinesPrepared({
    required List<QcfMushafLine> lines,
    required Color inkColor,
    required Color divineNameColor,
    required bool isDark,
    required TextScaler textScaler,
  }) {
    if (_preparedLines != null &&
        identical(_preparedPageData, widget.pageData) &&
        _preparedIsDark == isDark &&
        _preparedTextScaler == textScaler) {
      return _preparedLines!;
    }
    _disposePreparedLines();
    final sw = !kReleaseMode ? (Stopwatch()..start()) : null;
    if (!kReleaseMode) {
      developer.Timeline.startSync(
        'QCF.ensureLinesPrepared(p${widget.pageData.pageNumber})',
      );
    }
    int totalTextLayoutUs = 0;
    try {
      final built = List<_PreparedQcfLine>.generate(
        lines.length,
        (i) => _PreparedQcfLine.prepare(
          line: lines[i],
          fontFamily: widget.pageData.fontFamily,
          inkColor: inkColor,
          divineNameColor: divineNameColor,
          isDark: isDark,
          textScaler: textScaler,
          onLayoutUs: !kReleaseMode
              ? (layoutUs) {
                  totalTextLayoutUs += layoutUs;
                }
              : null,
        ),
        growable: false,
      );
      _preparedLines = built;
      _preparedPageData = widget.pageData;
      _preparedIsDark = isDark;
      _preparedTextScaler = textScaler;
      if (sw != null) {
        sw.stop();
        debugPrint(
          '[QCF_PERF] ensureLinesPrepared page=${widget.pageData.pageNumber} lines=${lines.length} total=${(sw.elapsedMicroseconds / 1000.0).toStringAsFixed(2)}ms (textLayout=${(totalTextLayoutUs / 1000.0).toStringAsFixed(2)}ms)',
        );
      }
      return built;
    } finally {
      if (!kReleaseMode) {
        developer.Timeline.finishSync();
      }
    }
  }

  @override
  void dispose() {
    _disposePreparedLines();
    _highlightFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final paperColor =
        isDark ? const Color(0xFF121820) : const Color(0xFFFBF7EE);
    final inkColor =
        isDark ? const Color(0xFFF3EFE4) : const Color(0xFF1A1610);
    final divineNameColor =
        isDark ? const Color(0xFFE05252) : const Color(0xFFA82020);
    final metaColor =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFF78552B);
    final dividerColor =
        (isDark ? const Color(0xFFD4AF37) : const Color(0xFFB5945B))
            .withValues(alpha: 0.32);
    final highlightBg =
        isDark ? const Color(0x4DF59E0B) : const Color(0x55FDE68A);
    final highlightBorderColor =
        isDark ? const Color(0x80F59E0B) : const Color(0x80C9A23A);
    final pageEdgeDividerColor =
        isDark ? const Color(0xFF2B3440) : const Color(0xFFA79B87);
    final pageEdgeShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : const Color(0x1E4A3B24);

    final pageNumber = widget.pageData.pageNumber;
    final arabicPage = QuranTextFormatter.toArabicDigits(pageNumber.toString());
    final arabicJuz = QuranTextFormatter.toArabicDigits(
      widget.pageData.juz.toString(),
    );
    final arabicHizb = QuranTextFormatter.toArabicDigits(
      QuranPageMapping.getHizbForPage(pageNumber).toString(),
    );

    final isOpeningPage = pageNumber == 1 || pageNumber == 2;
    final lines = isOpeningPage
        ? widget.pageData.lines
            .where((l) => l.type != 'surah-header')
            .toList(growable: false)
        : widget.pageData.lines;
    final isCompactPage = lines.length < 13;

    final textScaler = MediaQuery.textScalerOf(context);
    final preparedLines = _ensureLinesPrepared(
      lines: lines,
      inkColor: inkColor,
      divineNameColor: divineNameColor,
      isDark: isDark,
      textScaler: textScaler,
    );

    Widget buildCompactVerses() {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final prepared in preparedLines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: prepared.isHeader
                      ? SizedBox(
                          width: 340,
                          child: MushafSurahHeaderBanner(
                            surahName: prepared.cleanHeaderName,
                            fontSize: 18,
                            accentColor: widget.accentColor,
                            isDark: isDark,
                          ),
                        )
                      : _QcfCompactLineCanvas(
                          line: prepared,
                          isDark: isDark,
                          highlightedVerseKey: widget.highlightedVerseKey,
                          highlightColor: highlightBg,
                          highlightBorderColor: highlightBorderColor,
                          highlightFade: _highlightFadeController,
                          onTapVerse: widget.onTapVerse,
                          onLongPressVerse: widget.onLongPressVerse,
                        ),
                ),
            ],
          ),
        ),
      );
    }

    final surahMeta = isOpeningPage
        ? QuranData.surahs.firstWhere(
            (s) => s.number == widget.pageData.surahNumber,
            orElse: () => QuranData.surahs.first,
          )
        : null;

    return RepaintBoundary(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: widget.topInset),
            child: Container(
              decoration: BoxDecoration(
                color: paperColor,
                border: Border(
                  left: BorderSide(color: pageEdgeDividerColor, width: 1.2),
                  right: BorderSide(
                    color: pageEdgeDividerColor.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'سورة ${widget.pageData.surahName}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: metaColor,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'الجزء $arabicJuz | الحزب $arabicHizb',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: metaColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 8, thickness: 0.8, color: dividerColor),
                  Expanded(
                    child: isOpeningPage
                        ? QcfOpeningPageFrame(
                            pageNumber: pageNumber,
                            surahName: surahMeta!.name,
                            ayahCount: surahMeta.ayahCount,
                            isDark: isDark,
                            versesChild: buildCompactVerses(),
                          )
                        : (isCompactPage
                            ? buildCompactVerses()
                            : _QcfStandardVersesSheet(
                                lines: preparedLines,
                                isDark: isDark,
                                accentColor: widget.accentColor,
                                highlightedVerseKey: widget.highlightedVerseKey,
                                highlightColor: highlightBg,
                                highlightBorderColor: highlightBorderColor,
                                highlightFade: _highlightFadeController,
                                onTapVerse: widget.onTapVerse,
                                onLongPressVerse: widget.onLongPressVerse,
                              )),
                  ),
                  Divider(height: 8, thickness: 0.8, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      arabicPage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: metaColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isPageBookmarked)
            Positioned(
              top: 0,
              left: 38,
              child: MushafBookmarkRibbon(
                isDark: isDark,
                height: widget.topInset + 130,
              ),
            ),
          Positioned(
            top: widget.topInset,
            bottom: 0,
            left: 1.2,
            width: 6,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      pageEdgeShadowColor,
                      pageEdgeShadowColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahRef {
  final int surah;
  final int ayah;

  const _AyahRef(this.surah, this.ayah);
}

class _PreparedQcfLine {
  static final RegExp _surahPrefixRegex = RegExp(r'^سورة\s+');

  final QcfMushafLine rawLine;
  final TextPainter? textPainter;
  final List<Rect> ornamentRects;
  final Rect? sajdahRect;
  final Map<String, ({int start, int end})> verseCharRanges;
  final List<_AyahRef?> _charToAyah;
  final Map<String, RRect?> _highlightCache = <String, RRect?>{};

  _PreparedQcfLine._({
    required this.rawLine,
    required this.textPainter,
    required this.ornamentRects,
    required this.sajdahRect,
    required this.verseCharRanges,
    required List<_AyahRef?> charToAyah,
  }) : _charToAyah = charToAyah;

  bool get isHeader => rawLine.type == 'surah-header';

  String get cleanHeaderName {
    final cleaned = rawLine.text.replaceFirst(_surahPrefixRegex, '').trim();
    return cleaned.isNotEmpty ? cleaned : rawLine.text;
  }

  double get naturalWidth => textPainter?.width ?? 0.0;
  double get naturalHeight => textPainter?.height ?? 0.0;

  static _PreparedQcfLine prepare({
    required QcfMushafLine line,
    required String fontFamily,
    required Color inkColor,
    required Color divineNameColor,
    required bool isDark,
    required TextScaler textScaler,
    void Function(int layoutUs)? onLayoutUs,
  }) {
    if (line.type == 'surah-header') {
      return _PreparedQcfLine._(
        rawLine: line,
        textPainter: null,
        ornamentRects: const <Rect>[],
        sajdahRect: null,
        verseCharRanges: const <String, ({int start, int end})>{},
        charToAyah: const <_AyahRef?>[],
      );
    }

    if (line.type == 'basmala') {
      final bsmlGlyph = line.qpcV1;
      final hasQcfBasmala = bsmlGlyph != null && bsmlGlyph.isNotEmpty;
      final tp = TextPainter(
        text: TextSpan(
          text: hasQcfBasmala
              ? bsmlGlyph
              : 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: hasQcfBasmala
              ? TextStyle(
                  fontFamily: QcfMushafRepository.basmalaFontFamily,
                  fontSize: 24,
                  height: 1.25,
                  color: inkColor,
                )
              : GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: inkColor,
                ),
        ),
        textDirection: hasQcfBasmala ? TextDirection.ltr : TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 1,
        textScaler: textScaler,
      );
      if (!kReleaseMode && onLayoutUs != null) {
        final sw = Stopwatch()..start();
        tp.layout();
        sw.stop();
        onLayoutUs(sw.elapsedMicroseconds);
      } else {
        tp.layout();
      }

      return _PreparedQcfLine._(
        rawLine: line,
        textPainter: tp,
        ornamentRects: const <Rect>[],
        sajdahRect: null,
        verseCharRanges: const <String, ({int start, int end})>{},
        charToAyah: const <_AyahRef?>[],
      );
    }

    final baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      height: 1.35,
      color: inkColor,
    );
    final divineStyle = baseStyle.copyWith(color: divineNameColor);
    final ornamentColor =
        isDark ? const Color(0xFFE5C271) : const Color(0xFF6B4A20);
    final ornamentStyle = baseStyle.copyWith(
      color: ornamentColor,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    final ornamentRanges = <({int start, int end})>[];
    final verseCharRanges = <String, ({int start, int end})>{};
    final charToAyah = <_AyahRef?>[];
    int charOffset = 0;
    ({int start, int end})? sajdahRange;

    void appendChars(String text, TextStyle style, _AyahRef? ref) {
      spans.add(TextSpan(text: text, style: style));
      for (int c = 0; c < text.length; c++) {
        charToAyah.add(ref);
      }
      charOffset += text.length;
    }

    for (int i = 0; i < line.words.length; i++) {
      final word = line.words[i];
      final wordStart = charOffset;
      final ref = _AyahRef(word.surahNumber, word.ayahNumber);
      final wordStyle = word.isDivineReference ? divineStyle : baseStyle;

      if (word.isPureAyahOrnament) {
        final ornStart = charOffset;
        appendChars(word.glyph, ornamentStyle, ref);
        ornamentRanges.add((start: ornStart, end: charOffset));
      } else if (word.hasTrailingAyahOrnament) {
        final splitIdx = word.glyph.lastIndexOf(' ');
        final wordPart = word.glyph.substring(0, splitIdx);
        final ornamentPart = word.glyph.substring(splitIdx + 1);
        if (word.isSajdahWord) {
          sajdahRange = (start: charOffset, end: charOffset + wordPart.length);
        }
        appendChars(wordPart, wordStyle, ref);
        appendChars(' ', baseStyle, ref);
        final ornStart = charOffset;
        appendChars(ornamentPart, ornamentStyle, ref);
        ornamentRanges.add((start: ornStart, end: charOffset));
      } else {
        if (word.isSajdahWord) {
          sajdahRange =
              (start: charOffset, end: charOffset + word.glyph.length);
        }
        appendChars(word.glyph, wordStyle, ref);
      }

      final verseKey = word.verseKey;
      final existingRange = verseCharRanges[verseKey];
      verseCharRanges[verseKey] = (
        start: existingRange != null ? existingRange.start : wordStart,
        end: charOffset,
      );

      if (i < line.words.length - 1) {
        final nextWord = line.words[i + 1];
        final sameAyah = nextWord.surahNumber == word.surahNumber &&
            nextWord.ayahNumber == word.ayahNumber;
        appendChars(' ', baseStyle, sameAyah ? ref : null);
      }
    }

    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 1,
      textScaler: textScaler,
    );
    if (!kReleaseMode && onLayoutUs != null) {
      final sw = Stopwatch()..start();
      tp.layout();
      sw.stop();
      onLayoutUs(sw.elapsedMicroseconds);
    } else {
      tp.layout();
    }

    final lineHeight = tp.height;
    final ornamentRects = <Rect>[];
    for (final range in ornamentRanges) {
      final boxes = tp.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );
      if (boxes.isEmpty) continue;
      var left = boxes.first.left;
      var right = boxes.first.right;
      for (final b in boxes.skip(1)) {
        if (b.left < left) left = b.left;
        if (b.right > right) right = b.right;
      }
      ornamentRects.add(Rect.fromLTRB(left, 0.0, right, lineHeight));
    }

    Rect? sajdahRect;
    if (sajdahRange != null) {
      final boxes = tp.getBoxesForSelection(
        TextSelection(
          baseOffset: sajdahRange.start,
          extentOffset: sajdahRange.end,
        ),
      );
      if (boxes.isNotEmpty) {
        sajdahRect = boxes.first.toRect();
      }
    }

    return _PreparedQcfLine._(
      rawLine: line,
      textPainter: tp,
      ornamentRects: ornamentRects,
      sajdahRect: sajdahRect,
      verseCharRanges: verseCharRanges,
      charToAyah: charToAyah,
    );
  }

  RRect? highlightRRectFor(String? verseKey) {
    if (verseKey == null || textPainter == null) return null;
    final range = verseCharRanges[verseKey];
    if (range == null) return null;
    if (_highlightCache.containsKey(verseKey)) {
      return _highlightCache[verseKey];
    }
    final boxes = textPainter!.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    if (boxes.isEmpty) {
      _highlightCache[verseKey] = null;
      return null;
    }
    var bounds = boxes.first.toRect();
    for (final box in boxes.skip(1)) {
      bounds = bounds.expandToInclude(box.toRect());
    }
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        bounds.left - 4,
        bounds.top + 1,
        bounds.right + 4,
        bounds.bottom - 1,
      ),
      const Radius.circular(9),
    );
    _highlightCache[verseKey] = rrect;
    return rrect;
  }

  _AyahRef? hitTestUnscaled(Offset localPos) {
    final tp = textPainter;
    if (tp == null || _charToAyah.isEmpty) return null;
    if (localPos.dx < -6 ||
        localPos.dx > tp.width + 6 ||
        localPos.dy < -4 ||
        localPos.dy > tp.height + 4) {
      return null;
    }
    final clamped = Offset(
      localPos.dx.clamp(0.0, tp.width),
      localPos.dy.clamp(0.0, tp.height),
    );
    final rawOffset = tp.getPositionForOffset(clamped).offset;
    final idx = rawOffset.clamp(0, _charToAyah.length - 1);
    return _charToAyah[idx] ??
        (idx > 0 ? _charToAyah[idx - 1] : null) ??
        (idx + 1 < _charToAyah.length ? _charToAyah[idx + 1] : null);
  }

  void paintStaticContent(Canvas canvas, bool isDark) {
    final tp = textPainter;
    if (tp == null) return;

    for (final rect in ornamentRects) {
      if (isDark) {
        final diameter = math.min(rect.width - 6.0, rect.height - 12.0);
        final radius = diameter / 2.0;
        if (radius <= 0.5) continue;
        final paint = Paint()
          ..shader = ui.Gradient.radial(
            rect.center,
            radius,
            const <Color>[
              Color(0xFF1A222C),
              Color(0xFF1A222C),
              Color(0x33C9A354),
              Colors.transparent,
            ],
            const <double>[0.0, 0.46, 0.76, 1.0],
          );
        canvas.drawCircle(rect.center, radius, paint);
      } else {
        final diameter = math.min(rect.width - 8.0, rect.height - 18.0);
        final radius = diameter / 2.0;
        if (radius <= 0.5) continue;
        canvas.drawCircle(
          rect.center,
          radius,
          Paint()..color = const Color(0xFFFFFFFF),
        );
      }
    }

    tp.paint(canvas, Offset.zero);

    final sajdah = sajdahRect;
    if (sajdah != null) {
      _paintSajdahIndicator(canvas, sajdah, isDark);
    }
  }

  static void paintHighlightRRect(
    Canvas canvas,
    RRect rrect,
    Color fillColor,
    Color borderColor,
    double opacity,
  ) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    canvas.drawRRect(
      rrect,
      Paint()..color = fillColor.withValues(alpha: fillColor.a * clampedOpacity),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = borderColor.withValues(alpha: borderColor.a * clampedOpacity),
    );
  }

  static void _paintSajdahIndicator(
    Canvas canvas,
    Rect wordRect,
    bool isDark,
  ) {
    final left = wordRect.left;
    final right = wordRect.right;
    final width = wordRect.width;
    if (width <= 4) return;

    final centerX = wordRect.center.dx;
    final padding = (width * 0.08).clamp(2.0, 5.0);
    final lineStartX = left + padding;
    final lineEndX = right - padding;
    if (lineEndX <= lineStartX) return;

    final lineY = wordRect.bottom - 2.0;
    final lineColor =
        isDark ? const Color(0xFFD4A84B) : const Color(0xFF6B4A20);
    final ornamentColor =
        isDark ? const Color(0xFFE5C271) : const Color(0xFF4A2D0C);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;

    const centerGap = 3.2;
    if (centerX - centerGap > lineStartX) {
      canvas.drawLine(
        Offset(lineStartX, lineY),
        Offset(centerX - centerGap, lineY),
        linePaint,
      );
    }
    if (lineEndX > centerX + centerGap) {
      canvas.drawLine(
        Offset(centerX + centerGap, lineY),
        Offset(lineEndX, lineY),
        linePaint,
      );
    }

    const r = 2.4;
    final diamond = Path()
      ..moveTo(centerX, lineY - r)
      ..lineTo(centerX + r, lineY)
      ..lineTo(centerX, lineY + r)
      ..lineTo(centerX - r, lineY)
      ..close();

    canvas.drawPath(
      diamond,
      Paint()
        ..color = ornamentColor
        ..style = PaintingStyle.fill,
    );
  }

  void dispose() {
    textPainter?.dispose();
  }
}

class _QcfStandardVersesSheet extends StatelessWidget {
  final List<_PreparedQcfLine> lines;
  final bool isDark;
  final Color accentColor;
  final String? highlightedVerseKey;
  final Color highlightColor;
  final Color highlightBorderColor;
  final Animation<double> highlightFade;
  final void Function(int surahNumber, int ayahNumber)? onTapVerse;
  final void Function(int surahNumber, int ayahNumber)? onLongPressVerse;

  const _QcfStandardVersesSheet({
    required this.lines,
    required this.isDark,
    required this.accentColor,
    required this.highlightedVerseKey,
    required this.highlightColor,
    required this.highlightBorderColor,
    required this.highlightFade,
    required this.onTapVerse,
    required this.onLongPressVerse,
  });

  _AyahRef? _hitTest(Offset localPos, Size areaSize) {
    if (lines.isEmpty || areaSize.width <= 0 || areaSize.height <= 0) {
      return null;
    }
    final slotH = areaSize.height / lines.length;
    if (slotH <= 0) return null;
    final slotIndex = (localPos.dy / slotH).floor();
    if (slotIndex < 0 || slotIndex >= lines.length) return null;

    final line = lines[slotIndex];
    if (line.isHeader || line.naturalWidth <= 0 || line.naturalHeight <= 0) {
      return null;
    }

    final scale = math.min(
      1.0,
      math.min(areaSize.width / line.naturalWidth, slotH / line.naturalHeight),
    );
    final dx = (areaSize.width - line.naturalWidth * scale) / 2.0;
    final dy =
        (slotIndex * slotH) + (slotH - line.naturalHeight * scale) / 2.0;

    return line.hitTestUnscaled(
      Offset((localPos.dx - dx) / scale, (localPos.dy - dy) / scale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeKey = highlightedVerseKey;
    final hasHighlight = activeKey != null &&
        lines.any((l) => l.verseCharRanges.containsKey(activeKey));

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = Size(constraints.maxWidth, constraints.maxHeight);
        final slotH =
            lines.isEmpty ? 0.0 : constraints.maxHeight / lines.length;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: onTapVerse == null
              ? null
              : (details) {
                  final hit = _hitTest(details.localPosition, areaSize);
                  if (hit != null) {
                    onTapVerse!(hit.surah, hit.ayah);
                  }
                },
          onLongPressStart: onLongPressVerse == null
              ? null
              : (details) {
                  final hit = _hitTest(details.localPosition, areaSize);
                  if (hit != null) {
                    onLongPressVerse!(hit.surah, hit.ayah);
                  }
                },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasHighlight)
                IgnorePointer(
                  child: CustomPaint(
                    size: areaSize,
                    painter: _QcfPageHighlightPainter(
                      lines: lines,
                      verseKey: activeKey,
                      fillColor: highlightColor,
                      borderColor: highlightBorderColor,
                      fade: highlightFade,
                    ),
                  ),
                ),
              IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: areaSize,
                    isComplex: true,
                    willChange: false,
                    painter: _QcfStaticLinesPainter(
                      lines: lines,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              for (int i = 0; i < lines.length; i++)
                if (lines[i].isHeader)
                  Positioned(
                    top: i * slotH,
                    left: 0,
                    right: 0,
                    height: slotH,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 340,
                          child: MushafSurahHeaderBanner(
                            surahName: lines[i].cleanHeaderName,
                            fontSize: 18,
                            accentColor: accentColor,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _QcfStaticLinesPainter extends CustomPainter {
  final List<_PreparedQcfLine> lines;
  final bool isDark;

  const _QcfStaticLinesPainter({
    required this.lines,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty || size.width <= 0 || size.height <= 0) return;
    final slotH = size.height / lines.length;
    if (slotH <= 0) return;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isHeader || line.naturalWidth <= 0 || line.naturalHeight <= 0) {
        continue;
      }
      final scale = math.min(
        1.0,
        math.min(size.width / line.naturalWidth, slotH / line.naturalHeight),
      );
      final dx = (size.width - line.naturalWidth * scale) / 2.0;
      final dy = (i * slotH) + (slotH - line.naturalHeight * scale) / 2.0;

      canvas.save();
      canvas.translate(dx, dy);
      if (scale != 1.0) {
        canvas.scale(scale);
      }
      line.paintStaticContent(canvas, isDark);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _QcfStaticLinesPainter oldDelegate) {
    return !identical(oldDelegate.lines, lines) ||
        oldDelegate.isDark != isDark;
  }
}

class _QcfPageHighlightPainter extends CustomPainter {
  final List<_PreparedQcfLine> lines;
  final String verseKey;
  final Color fillColor;
  final Color borderColor;
  final Animation<double> fade;

  _QcfPageHighlightPainter({
    required this.lines,
    required this.verseKey,
    required this.fillColor,
    required this.borderColor,
    required this.fade,
  }) : super(repaint: fade);

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty || size.width <= 0 || size.height <= 0) return;
    final slotH = size.height / lines.length;
    if (slotH <= 0) return;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final rrect = line.highlightRRectFor(verseKey);
      if (rrect == null || line.naturalWidth <= 0 || line.naturalHeight <= 0) {
        continue;
      }
      final scale = math.min(
        1.0,
        math.min(size.width / line.naturalWidth, slotH / line.naturalHeight),
      );
      final dx = (size.width - line.naturalWidth * scale) / 2.0;
      final dy = (i * slotH) + (slotH - line.naturalHeight * scale) / 2.0;

      canvas.save();
      canvas.translate(dx, dy);
      if (scale != 1.0) {
        canvas.scale(scale);
      }
      _PreparedQcfLine.paintHighlightRRect(
        canvas,
        rrect,
        fillColor,
        borderColor,
        fade.value,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _QcfPageHighlightPainter oldDelegate) {
    return !identical(oldDelegate.lines, lines) ||
        oldDelegate.verseKey != verseKey ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fade != fade;
  }
}

class _QcfCompactLineCanvas extends StatelessWidget {
  final _PreparedQcfLine line;
  final bool isDark;
  final String? highlightedVerseKey;
  final Color highlightColor;
  final Color highlightBorderColor;
  final Animation<double> highlightFade;
  final void Function(int surahNumber, int ayahNumber)? onTapVerse;
  final void Function(int surahNumber, int ayahNumber)? onLongPressVerse;

  const _QcfCompactLineCanvas({
    required this.line,
    required this.isDark,
    required this.highlightedVerseKey,
    required this.highlightColor,
    required this.highlightBorderColor,
    required this.highlightFade,
    required this.onTapVerse,
    required this.onLongPressVerse,
  });

  @override
  Widget build(BuildContext context) {
    final hasLineHighlight = highlightedVerseKey != null &&
        line.verseCharRanges.containsKey(highlightedVerseKey);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: onTapVerse == null
          ? null
          : (details) {
              final hit = line.hitTestUnscaled(details.localPosition);
              if (hit != null) {
                onTapVerse!(hit.surah, hit.ayah);
              }
            },
      onLongPressStart: onLongPressVerse == null
          ? null
          : (details) {
              final hit = line.hitTestUnscaled(details.localPosition);
              if (hit != null) {
                onLongPressVerse!(hit.surah, hit.ayah);
              }
            },
      child: CustomPaint(
        size: Size(line.naturalWidth, line.naturalHeight),
        painter: _QcfCompactLinePainter(
          line: line,
          isDark: isDark,
          verseKey: hasLineHighlight ? highlightedVerseKey : null,
          fillColor: highlightColor,
          borderColor: highlightBorderColor,
          fade: hasLineHighlight ? highlightFade : null,
        ),
      ),
    );
  }
}

class _QcfCompactLinePainter extends CustomPainter {
  final _PreparedQcfLine line;
  final bool isDark;
  final String? verseKey;
  final Color fillColor;
  final Color borderColor;
  final Animation<double>? fade;

  _QcfCompactLinePainter({
    required this.line,
    required this.isDark,
    required this.verseKey,
    required this.fillColor,
    required this.borderColor,
    required this.fade,
  }) : super(repaint: fade);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = line.highlightRRectFor(verseKey);
    if (rrect != null) {
      _PreparedQcfLine.paintHighlightRRect(
        canvas,
        rrect,
        fillColor,
        borderColor,
        fade?.value ?? 1.0,
      );
    }
    line.paintStaticContent(canvas, isDark);
  }

  @override
  bool shouldRepaint(covariant _QcfCompactLinePainter oldDelegate) {
    return !identical(oldDelegate.line, line) ||
        oldDelegate.isDark != isDark ||
        oldDelegate.verseKey != verseKey ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fade != fade;
  }
}

class MushafBookmarkRibbon extends StatelessWidget {
  final bool isDark;
  final double height;

  const MushafBookmarkRibbon({
    super.key,
    required this.isDark,
    this.height = 155,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(26, height),
          painter: _MushafBookmarkRibbonPainter(isDark: isDark),
        ),
      ),
    );
  }
}

class _MushafBookmarkRibbonPainter extends CustomPainter {
  final bool isDark;

  const _MushafBookmarkRibbonPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ribbonPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - 12)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..color = isDark
          ? const Color(0xFFE57373).withValues(alpha: 0.38)
          : const Color(0xFFD9534F).withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;

    canvas.drawPath(ribbonPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MushafBookmarkRibbonPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
