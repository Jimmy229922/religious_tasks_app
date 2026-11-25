import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _QcfMushafPageWidgetState extends State<QcfMushafPageWidget> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

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
    final pageEdgeDividerColor =
        isDark ? const Color(0xFF2B3440) : const Color(0xFFA79B87);
    final pageEdgeShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : const Color(0x1E4A3B24);

    final arabicPage = QuranTextFormatter.toArabicDigits(
      widget.pageData.pageNumber.toString(),
    );
    final arabicJuz = QuranTextFormatter.toArabicDigits(
      widget.pageData.juz.toString(),
    );
    final arabicHizb = QuranTextFormatter.toArabicDigits(
      QuranPageMapping.getHizbForPage(widget.pageData.pageNumber).toString(),
    );
    final pageNumber = widget.pageData.pageNumber;
    final isOpeningPage = pageNumber == 1 || pageNumber == 2;
    final lines = isOpeningPage
        ? widget.pageData.lines
            .where((l) => l.type != 'surah-header')
            .toList(growable: false)
        : widget.pageData.lines;
    final isCompactPage = lines.length < 13;

    Widget buildCompactVerses() {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildLineWidget(
                    line: line,
                    inkColor: inkColor,
                    divineNameColor: divineNameColor,
                    highlightBg: highlightBg,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final surahMeta = QuranData.surahs.firstWhere(
      (s) => s.number == widget.pageData.surahNumber,
      orElse: () => QuranData.surahs.first,
    );

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
          boxShadow: [
            BoxShadow(
              color: pageEdgeShadowColor,
              blurRadius: 6,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${widget.pageData.surahName}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: metaColor,
                  ),
                ),
                Text(
                  'الجزء $arabicJuz | الحزب $arabicHizb',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: metaColor,
                  ),
                ),
              ],
            ),
            Divider(height: 8, thickness: 0.8, color: dividerColor),
            Expanded(
              child: isOpeningPage
                  ? QcfOpeningPageFrame(
                      pageNumber: pageNumber,
                      surahName: surahMeta.name,
                      ayahCount: surahMeta.ayahCount,
                      isDark: isDark,
                      versesChild: buildCompactVerses(),
                    )
                  : (isCompactPage
                      ? buildCompactVerses()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final line in lines)
                              Expanded(
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: _buildLineWidget(
                                      line: line,
                                      inkColor: inkColor,
                                      divineNameColor: divineNameColor,
                                      highlightBg: highlightBg,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
        ],
      ),
    );
  }

  Widget _buildLineWidget({
    required QcfMushafLine line,
    required Color inkColor,
    required Color divineNameColor,
    required Color highlightBg,
    required bool isDark,
  }) {
    if (line.type == 'surah-header') {
      final cleanName = line.text.replaceFirst(RegExp(r'^سورة\s+'), '').trim();
      return SizedBox(
        width: 340,
        child: MushafSurahHeaderBanner(
          surahName: cleanName.isNotEmpty ? cleanName : line.text,
          fontSize: 18,
          accentColor: widget.accentColor,
          isDark: isDark,
        ),
      );
    }

    if (line.type == 'basmala') {
      final bsmlGlyph = line.qpcV1;
      if (bsmlGlyph != null && bsmlGlyph.isNotEmpty) {
        return Text(
          bsmlGlyph,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontFamily: QcfMushafRepository.basmalaFontFamily,
            fontSize: 24,
            height: 1.25,
            color: inkColor,
          ),
        );
      }
      return Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: GoogleFonts.amiri(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: inkColor,
        ),
      );
    }

    return _buildLineRichText(
      line: line,
      inkColor: inkColor,
      divineNameColor: divineNameColor,
      highlightBg: highlightBg,
    );
  }

  GestureRecognizer? _createRecognizer(int surahNumber, int ayahNumber) {
    final onTap = widget.onTapVerse;
    final onLongPress = widget.onLongPressVerse;
    GestureRecognizer? recognizer;
    if (onTap != null && onLongPress != null) {
      recognizer = _QcfTapAndLongPressRecognizer(
        onTap: () => onTap(surahNumber, ayahNumber),
        onLongPress: () => onLongPress(surahNumber, ayahNumber),
      );
    } else if (onTap != null) {
      recognizer = TapGestureRecognizer()
        ..onTap = () => onTap(surahNumber, ayahNumber);
    } else if (onLongPress != null) {
      recognizer = LongPressGestureRecognizer()
        ..onLongPress = () => onLongPress(surahNumber, ayahNumber);
    }
    if (recognizer != null) {
      _recognizers.add(recognizer);
    }
    return recognizer;
  }

  Widget _buildLineRichText({
    required QcfMushafLine line,
    required Color inkColor,
    required Color divineNameColor,
    required Color highlightBg,
  }) {
    final baseStyle = TextStyle(
      fontFamily: widget.pageData.fontFamily,
      fontSize: 28,
      height: 1.35,
      color: inkColor,
    );

    final spans = <InlineSpan>[];
    int charOffset = 0;
    int? sajdahStart;
    int? sajdahEnd;

    for (int i = 0; i < line.words.length; i++) {
      final word = line.words[i];
      final isSelected = widget.highlightedVerseKey == word.verseKey;
      final recognizer = _createRecognizer(word.surahNumber, word.ayahNumber);
      final isDivine = QcfMushafWord.isWordDivineReference(
        word,
        prevWord: i > 0 ? line.words[i - 1] : null,
        nextWord: i + 1 < line.words.length ? line.words[i + 1] : null,
      );
      final wordTextColor = isDivine ? divineNameColor : inkColor;
      final bg = isSelected ? highlightBg : null;

      if (word.isPureAyahOrnament) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _QcfOrnamentBadge(
              glyph: word.glyph,
              baseStyle: baseStyle,
              isDark: widget.isDark,
              isSelected: isSelected,
              highlightBg: highlightBg,
              onTap: widget.onTapVerse == null
                  ? null
                  : () => widget.onTapVerse!(word.surahNumber, word.ayahNumber),
              onLongPress: widget.onLongPressVerse == null
                  ? null
                  : () =>
                      widget.onLongPressVerse!(word.surahNumber, word.ayahNumber),
            ),
          ),
        );
        charOffset += 1;
      } else if (word.hasTrailingAyahOrnament) {
        final splitIdx = word.glyph.lastIndexOf(' ');
        final wordPart = word.glyph.substring(0, splitIdx);
        final ornamentPart = word.glyph.substring(splitIdx + 1);
        if (word.isSajdahWord) {
          sajdahStart = charOffset;
          sajdahEnd = charOffset + wordPart.length;
        }
        spans.add(
          TextSpan(
            text: wordPart,
            recognizer: recognizer,
            style: baseStyle.copyWith(color: wordTextColor, backgroundColor: bg),
          ),
        );
        charOffset += wordPart.length;
        spans.add(
          TextSpan(
            text: ' ',
            recognizer: recognizer,
            style: baseStyle.copyWith(backgroundColor: bg),
          ),
        );
        charOffset += 1;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _QcfOrnamentBadge(
              glyph: ornamentPart,
              baseStyle: baseStyle,
              isDark: widget.isDark,
              isSelected: isSelected,
              highlightBg: highlightBg,
              onTap: widget.onTapVerse == null
                  ? null
                  : () => widget.onTapVerse!(word.surahNumber, word.ayahNumber),
              onLongPress: widget.onLongPressVerse == null
                  ? null
                  : () =>
                      widget.onLongPressVerse!(word.surahNumber, word.ayahNumber),
            ),
          ),
        );
        charOffset += 1;
      } else {
        if (word.isSajdahWord) {
          sajdahStart = charOffset;
          sajdahEnd = charOffset + word.glyph.length;
        }
        spans.add(
          TextSpan(
            text: word.glyph,
            recognizer: recognizer,
            style: baseStyle.copyWith(color: wordTextColor, backgroundColor: bg),
          ),
        );
        charOffset += word.glyph.length;
      }

      if (i < line.words.length - 1) {
        spans.add(
          TextSpan(
            text: ' ',
            style: baseStyle.copyWith(backgroundColor: bg),
          ),
        );
        charOffset += 1;
      }
    }

    if (sajdahStart != null && sajdahEnd != null) {
      return _SajdahLineOverlay(
        sajdahStart: sajdahStart,
        sajdahEnd: sajdahEnd,
        isDark: widget.isDark,
        spans: spans,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 1,
    );
  }
}

class _SajdahLineOverlay extends StatefulWidget {
  final int sajdahStart;
  final int sajdahEnd;
  final bool isDark;
  final List<InlineSpan> spans;

  const _SajdahLineOverlay({
    required this.sajdahStart,
    required this.sajdahEnd,
    required this.isDark,
    required this.spans,
  });

  @override
  State<_SajdahLineOverlay> createState() => _SajdahLineOverlayState();
}

class _SajdahLineOverlayState extends State<_SajdahLineOverlay> {
  final GlobalKey _textKey = GlobalKey();
  Rect? _wordRect;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant _SajdahLineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObj = _textKey.currentContext?.findRenderObject();
      if (renderObj is! RenderParagraph) return;
      final boxes = renderObj.getBoxesForSelection(
        TextSelection(
          baseOffset: widget.sajdahStart,
          extentOffset: widget.sajdahEnd,
        ),
      );
      if (boxes.isEmpty) return;
      final rect = boxes.first.toRect();
      if (_wordRect != rect) {
        setState(() {
          _wordRect = rect;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _wordRect == null
          ? null
          : _SajdahIndicatorPainter(
              wordRect: _wordRect!,
              isDark: widget.isDark,
            ),
      child: Text.rich(
        TextSpan(children: widget.spans),
        key: _textKey,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}

class _SajdahIndicatorPainter extends CustomPainter {
  final Rect wordRect;
  final bool isDark;

  const _SajdahIndicatorPainter({
    required this.wordRect,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant _SajdahIndicatorPainter oldDelegate) {
    return oldDelegate.wordRect != wordRect || oldDelegate.isDark != isDark;
  }
}

class _QcfOrnamentBadge extends StatelessWidget {
  final String glyph;
  final TextStyle baseStyle;
  final bool isDark;
  final bool isSelected;
  final Color highlightBg;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _QcfOrnamentBadge({
    required this.glyph,
    required this.baseStyle,
    required this.isDark,
    required this.isSelected,
    required this.highlightBg,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      const ornamentColor = Color(0xFFE5C271);
      const radialColors = <Color>[
        Color(0xFF1A222C),
        Color(0xFF1A222C),
        Color(0x33C9A354),
        Colors.transparent,
      ];

      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: highlightBg,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: radialColors,
                        stops: [0.0, 0.46, 0.76, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                glyph,
                textDirection: TextDirection.rtl,
                style: baseStyle.copyWith(
                  color: ornamentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: highlightBg,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const RadialGradient(
                  center: Alignment.center,
                  radius: 0.50,
                  colors: <Color>[
                    Color(0xFF000000),
                    Color(0xFF000000),
                    Color(0xFF6B4A20),
                    Color(0xFF6B4A20),
                  ],
                  stops: <double>[0.0, 0.36, 0.42, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                glyph,
                textDirection: TextDirection.rtl,
                style: baseStyle.copyWith(
                  color: const Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QcfTapAndLongPressRecognizer extends OneSequenceGestureRecognizer {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  _QcfTapAndLongPressRecognizer({
    required this.onTap,
    required this.onLongPress,
  });

  Timer? _longPressTimer;
  Offset? _initialPosition;
  bool _longPressTriggered = false;
  int? _activePointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_activePointer != null) return;
    startTrackingPointer(event.pointer, event.transform);
    _activePointer = event.pointer;
    _initialPosition = event.position;
    _longPressTriggered = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(kLongPressTimeout, () {
      _longPressTriggered = true;
      resolve(GestureDisposition.accepted);
      onLongPress();
    });
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    if (event is PointerMoveEvent) {
      final start = _initialPosition;
      if (start != null && (event.position - start).distance > kTouchSlop) {
        _reset();
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerUpEvent) {
      final wasLongPress = _longPressTriggered;
      _reset();
      if (!wasLongPress) {
        resolve(GestureDisposition.accepted);
        onTap();
      }
    } else if (event is PointerCancelEvent) {
      _reset();
      resolve(GestureDisposition.rejected);
    }
  }

  void _reset() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    if (_activePointer != null) {
      stopTrackingPointer(_activePointer!);
      _activePointer = null;
    }
    _initialPosition = null;
  }

  @override
  String get debugDescription => 'qcf tap and long press';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void dispose() {
    _reset();
    super.dispose();
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
