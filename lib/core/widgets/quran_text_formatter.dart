import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MushafTypographyResult {
  final double fontSize;
  final double lineHeight;

  const MushafTypographyResult({
    required this.fontSize,
    required this.lineHeight,
  });
}

class QuranTextFormatter {
  static const Color defaultGold = Color(0xFFD4AF37);

  static final RegExp _verseMarkerPattern = RegExp(
    r'﴿\s*([0-9\u0660-\u0669]+)\s*﴾|۝\s*([0-9\u0660-\u0669]+)|(?:^|\s)[(（]([0-9\u0660-\u0669]+)[)）]',
  );

  static final Map<String, MushafTypographyResult> _typographyCache = {};

  /// Converts English/ASCII digits to Eastern Arabic Indic digits (١, ٢, ٣...)
  static String toArabicDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  /// Converts Eastern Arabic Indic digits (٠..٩) to English/ASCII digits (0..9)
  static String toEnglishDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  /// Parses an ASCII or Arabic-Indic verse number string into an integer
  static int? parseVerseNumber(String input) {
    return int.tryParse(toEnglishDigits(input).trim());
  }

  /// Removes Arabic diacritics and normalizes letter forms for reliable comparison
  static String normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0671\u06D6-\u06ED]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .trim();
  }

  static bool shouldJustifyText(String text, {int? pageNumber}) {
    if (pageNumber == 1) return false;
    return text.trim().length >= 210;
  }

  static MushafTypographyResult computeMushafTypography({
    required String cacheKey,
    required List<String> sectionTexts,
    required double maxWidth,
    required double maxHeight,
    required double userScaleFactor,
    required double headerOverheadHeight,
    required TextStyle baseTextStyle,
  }) {
    final combinedRaw = sectionTexts
        .where((s) => s.trim().isNotEmpty)
        .join('\n');
    if (maxWidth <= 40 || maxHeight <= 40 || combinedRaw.isEmpty) {
      return MushafTypographyResult(
        fontSize: 20.0 * userScaleFactor,
        lineHeight: 2.0,
      );
    }

    final fullCacheKey =
        '$cacheKey|${maxWidth.round()}|${maxHeight.round()}|${userScaleFactor.toStringAsFixed(2)}|${headerOverheadHeight.round()}';
    final cached = _typographyCache[fullCacheKey];
    if (cached != null) return cached;

    if (_typographyCache.length > 120) {
      _typographyCache.clear();
    }

    final availableTextHeight =
        (maxHeight - headerOverheadHeight - 6.0).clamp(90.0, maxHeight);
    final measurementText =
        combinedRaw.replaceAll(_verseMarkerPattern, '  ۝٠٠  ');

    const double minLineHeight = 1.88;
    double low = 17.0;
    double high = 27.5;
    double bestFontSize = 18.5;

    for (int i = 0; i < 7; i++) {
      final mid = (low + high) / 2.0;
      final painter = TextPainter(
        text: TextSpan(
          text: measurementText,
          style: baseTextStyle.copyWith(fontSize: mid, height: minLineHeight),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        strutStyle: StrutStyle(
          fontSize: mid,
          height: minLineHeight,
          forceStrutHeight: true,
        ),
      )..layout(maxWidth: maxWidth);

      final measuredHeight = painter.height;
      painter.dispose();

      if (measuredHeight <= availableTextHeight * 0.95) {
        bestFontSize = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    final basePainter = TextPainter(
      text: TextSpan(
        text: measurementText,
        style: baseTextStyle.copyWith(
          fontSize: bestFontSize,
          height: minLineHeight,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      strutStyle: StrutStyle(
        fontSize: bestFontSize,
        height: minLineHeight,
        forceStrutHeight: true,
      ),
    )..layout(maxWidth: maxWidth);

    final baseMeasuredHeight = basePainter.height;
    basePainter.dispose();

    final lineCount =
        (baseMeasuredHeight / (bestFontSize * minLineHeight)).round().clamp(1, 45);
    final idealLineHeight =
        ((availableTextHeight * 0.96) / (lineCount * bestFontSize))
            .clamp(1.85, 2.55);

    final result = MushafTypographyResult(
      fontSize: bestFontSize * userScaleFactor,
      lineHeight: userScaleFactor > 1.0
          ? idealLineHeight.clamp(1.85, 2.25)
          : idealLineHeight,
    );

    _typographyCache[fullCacheKey] = result;
    return result;
  }

  /// Builds a [Text.rich] widget with custom golden Quranic verse badge ornaments and Ayah-level highlighting & tapping
  static Widget buildFormattedQuranText(
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.center,
    Color? badgeColor,
    String? bookmarkedVerse,
    bool? isDark,
    void Function(String verseNumber)? onTapVerse,
    void Function(String verseNumber)? onLongPressVerse,
  }) {
    final effectiveDark =
        isDark ?? ((baseStyle.color?.computeLuminance() ?? 0.0) > 0.5);
    final effectiveBadgeColor = badgeColor ?? baseStyle.color ?? defaultGold;

    if (onTapVerse != null || onLongPressVerse != null) {
      return _InteractiveQuranRichText(
        text: text,
        baseStyle: baseStyle,
        textAlign: textAlign,
        badgeColor: effectiveBadgeColor,
        bookmarkedVerse: bookmarkedVerse,
        isDark: effectiveDark,
        onTapVerse: onTapVerse,
        onLongPressVerse: onLongPressVerse,
      );
    }

    final spans = buildSpans(
      text,
      baseFontSize: baseStyle.fontSize ?? 18.0,
      badgeColor: effectiveBadgeColor,
      baseStyle: baseStyle,
      bookmarkedVerse: bookmarkedVerse,
      isDark: effectiveDark,
    );

    final fontSize = baseStyle.fontSize ?? 18.0;
    final lineHeight = baseStyle.height ?? 1.5;

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      textAlign: textAlign,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: lineHeight,
        forceStrutHeight: true,
      ),
    );
  }

  static String extractFullVerseText(
    String sectionText,
    String verseNumber,
  ) {
    final arabicTarget = toArabicDigits(verseNumber);
    int currentPos = 0;
    for (final match in _verseMarkerPattern.allMatches(sectionText)) {
      final rawNum = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      final arabicNum = toArabicDigits(rawNum);
      if (rawNum == verseNumber || arabicNum == arabicTarget) {
        return sectionText.substring(currentPos, match.start).trim();
      }
      currentPos = match.end;
    }
    return '';
  }

  static String extractVerseSnippet(
    String sectionText,
    String verseNumber, {
    int maxWords = 7,
  }) {
    final segment = extractFullVerseText(sectionText, verseNumber);
    if (segment.isEmpty) return '';
    final words = segment.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return segment;
    return '${words.take(maxWords).join(' ')} ...';
  }

  static double getVerseScrollRatio(String pageText, String verseNumber) {
    if (pageText.isEmpty) return 0.0;
    final arabicTarget = toArabicDigits(verseNumber);
    int currentPos = 0;
    for (final match in _verseMarkerPattern.allMatches(pageText)) {
      final rawNum = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      final arabicNum = toArabicDigits(rawNum);
      if (rawNum == verseNumber || arabicNum == arabicTarget) {
        return (currentPos / pageText.length).clamp(0.0, 1.0);
      }
      currentPos = match.end;
    }
    return 0.0;
  }

  /// Parses string and splits into TextSpan for verse numbers and Ayah-level tapping
  static List<InlineSpan> buildSpans(
    String text, {
    required double baseFontSize,
    required Color badgeColor,
    required TextStyle baseStyle,
    String? bookmarkedVerse,
    bool isDark = false,
    void Function(String verseNumber)? onTapVerse,
    void Function(String verseNumber)? onLongPressVerse,
    List<GestureRecognizer>? recognizerCollector,
  }) {
    final spans = <InlineSpan>[];

    int currentPosition = 0;
    final matches = _verseMarkerPattern.allMatches(text);

    final highlightTextColor =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final highlightBgColor =
        isDark ? const Color(0x38F59E0B) : const Color(0x55FDE68A);
    final activeBadgeColor =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

    final normalizedBookmark = bookmarkedVerse == null
        ? null
        : toEnglishDigits(bookmarkedVerse).trim();

    for (final match in matches) {
      final rawNum = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      final arabicNum = toArabicDigits(rawNum);
      final normalizedRaw = toEnglishDigits(rawNum).trim();

      final isBookmarked = normalizedBookmark != null &&
          normalizedBookmark.isNotEmpty &&
          normalizedBookmark == normalizedRaw;

      final ayahSegment = match.start > currentPosition
          ? text.substring(currentPosition, match.start).trimRight()
          : '';
      final markerText = '\u00A0﴿$arabicNum﴾ ';

      final ayahStyle = isBookmarked
          ? baseStyle.copyWith(
              color: highlightTextColor,
              backgroundColor: highlightBgColor,
              fontWeight: FontWeight.bold,
            )
          : baseStyle;

      final markerStyle = baseStyle.copyWith(
        color: isBookmarked ? activeBadgeColor : badgeColor,
        backgroundColor: isBookmarked ? highlightBgColor : null,
        fontWeight: FontWeight.bold,
        fontSize: baseFontSize * 0.96,
      );

      GestureRecognizer? recognizer;
      if (onTapVerse != null && onLongPressVerse != null) {
        recognizer = _TapAndLongPressGestureRecognizer(
          onTap: () => onTapVerse(rawNum),
          onLongPress: () => onLongPressVerse(rawNum),
        );
        recognizerCollector?.add(recognizer);
      } else if (onTapVerse != null) {
        recognizer = TapGestureRecognizer()..onTap = () => onTapVerse(rawNum);
        recognizerCollector?.add(recognizer);
      } else if (onLongPressVerse != null) {
        recognizer = LongPressGestureRecognizer()
          ..onLongPress = () => onLongPressVerse(rawNum);
        recognizerCollector?.add(recognizer);
      }

      if (ayahSegment.isNotEmpty) {
        spans.add(
          TextSpan(
            text: ayahSegment,
            style: ayahStyle,
            recognizer: recognizer,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: markerText,
          style: markerStyle,
          recognizer: recognizer,
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining text after last match
    if (currentPosition < text.length) {
      final remaining = text.substring(currentPosition);
      spans.add(TextSpan(text: remaining, style: baseStyle));
    }

    return spans;
  }
}

class _InteractiveQuranRichText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final TextAlign textAlign;
  final Color badgeColor;
  final String? bookmarkedVerse;
  final bool isDark;
  final void Function(String verseNumber)? onTapVerse;
  final void Function(String verseNumber)? onLongPressVerse;

  const _InteractiveQuranRichText({
    required this.text,
    required this.baseStyle,
    required this.textAlign,
    required this.badgeColor,
    required this.bookmarkedVerse,
    required this.isDark,
    this.onTapVerse,
    this.onLongPressVerse,
  });

  @override
  State<_InteractiveQuranRichText> createState() =>
      _InteractiveQuranRichTextState();
}

class _InteractiveQuranRichTextState extends State<_InteractiveQuranRichText> {
  final List<GestureRecognizer> _recognizers = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(covariant _InteractiveQuranRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.baseStyle != widget.baseStyle ||
        oldWidget.textAlign != widget.textAlign ||
        oldWidget.badgeColor != widget.badgeColor ||
        oldWidget.bookmarkedVerse != widget.bookmarkedVerse ||
        oldWidget.isDark != widget.isDark ||
        oldWidget.onTapVerse != widget.onTapVerse ||
        oldWidget.onLongPressVerse != widget.onLongPressVerse) {
      _disposeRecognizers();
      _rebuildSpans();
    }
  }

  void _rebuildSpans() {
    _spans = QuranTextFormatter.buildSpans(
      widget.text,
      baseFontSize: widget.baseStyle.fontSize ?? 18.0,
      badgeColor: widget.badgeColor,
      baseStyle: widget.baseStyle,
      bookmarkedVerse: widget.bookmarkedVerse,
      isDark: widget.isDark,
      onTapVerse: widget.onTapVerse,
      onLongPressVerse: widget.onLongPressVerse,
      recognizerCollector: _recognizers,
    );
  }

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
    final fontSize = widget.baseStyle.fontSize ?? 18.0;
    final lineHeight = widget.baseStyle.height ?? 1.5;

    return Text.rich(
      TextSpan(style: widget.baseStyle, children: _spans),
      textAlign: widget.textAlign,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: lineHeight,
        forceStrutHeight: true,
      ),
    );
  }
}

class _TapAndLongPressGestureRecognizer extends OneSequenceGestureRecognizer {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  _TapAndLongPressGestureRecognizer({
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
  String get debugDescription => 'tap and long press';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void dispose() {
    _reset();
    super.dispose();
  }
}

/// Custom Quran Ayah Symbol Widget that renders the exact Quran Ayah Symbol ۝ frame with the verse number inside
class QuranAyahSymbolWidget extends StatelessWidget {
  final String number;
  final double fontSize;
  final Color color;
  final bool isBookmarked;
  final bool isDark;
  final VoidCallback? onTap;

  const QuranAyahSymbolWidget({
    super.key,
    required this.number,
    required this.fontSize,
    required this.color,
    this.isBookmarked = false,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (fontSize * 1.35).clamp(24.0, 36.0);
    final height = (fontSize * 1.45).clamp(28.0, 40.0);
    final numFontSize = (fontSize * 0.58).clamp(11.0, 16.0);

    final activeBookmarkColor =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    final badgeColor = isBookmarked ? activeBookmarkColor : color;

    final childWidget = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: QuranAyahSymbolPainter(
          color: badgeColor,
          isBookmarked: isBookmarked,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 0.5),
            child: Text(
              number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: numFontSize,
                fontWeight: FontWeight.bold,
                color: badgeColor,
                height: 1.0,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: childWidget,
      );
    }

    return childWidget;
  }
}

/// CustomPainter drawing the exact Quran End-Of-Ayah ۝ frame (rounded frame with top and bottom decorative arches)
class QuranAyahSymbolPainter extends CustomPainter {
  final Color color;
  final bool isBookmarked;

  const QuranAyahSymbolPainter({
    required this.color,
    this.isBookmarked = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final strokeW = isBookmarked ? 2.0 : 1.4;

    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isBookmarked ? 0.25 : 0.08)
      ..style = PaintingStyle.fill;

    // 1. Main outer oval/rounded frame
    final rect = Rect.fromLTRB(2.5, 3.5, width - 2.5, height - 3.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width * 0.45));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, framePaint);

    // 2. Top decorative loop/arch (the ornament loop on ۝)
    final topArcCenter = Offset(width / 2, 2.2);
    canvas.drawCircle(topArcCenter, 1.6, framePaint);

    // 3. Bottom decorative loop/arch
    final bottomArcCenter = Offset(width / 2, height - 2.2);
    canvas.drawCircle(bottomArcCenter, 1.6, framePaint);

    // 4. Side accent dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(1.2, height / 2), 1.0, dotPaint);
    canvas.drawCircle(Offset(width - 1.2, height / 2), 1.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant QuranAyahSymbolPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isBookmarked != isBookmarked;
  }
}

class MushafSurahHeaderBanner extends StatelessWidget {
  final String surahName;
  final double fontSize;
  final Color accentColor;
  final bool isDark;

  const MushafSurahHeaderBanner({
    super.key,
    required this.surahName,
    required this.fontSize,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = QuranTextFormatter.defaultGold;
    final titleColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF13222E),
                  const Color(0xFF1B3139),
                  const Color(0xFF13222E),
                ]
              : [
                  const Color(0xFFFEF9E7),
                  const Color(0xFFFDF3D0),
                  const Color(0xFFFEF9E7),
                ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goldColor.withValues(alpha: isDark ? 0.65 : 0.8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: isDark ? 0.12 : 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MushafBannerOrnamentPainter(
          goldColor: goldColor,
          accentColor: accentColor,
          isDark: isDark,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
          child: Center(
            child: Text(
              "سُورَةُ $surahName",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.amiri(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: titleColor,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MushafBannerOrnamentPainter extends CustomPainter {
  final Color goldColor;
  final Color accentColor;
  final bool isDark;

  const _MushafBannerOrnamentPainter({
    required this.goldColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final innerPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.45 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(3.5, 3.5, size.width - 3.5, size.height - 3.5),
      const Radius.circular(9),
    );
    canvas.drawRRect(innerRect, innerPaint);

    final ornamentFill = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.fill;
    final ornamentStroke = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final centerY = size.height / 2;
    _drawSideMedallion(canvas, Offset(15, centerY), ornamentFill, ornamentStroke);
    _drawSideMedallion(
      canvas,
      Offset(size.width - 15, centerY),
      ornamentFill,
      ornamentStroke,
    );
  }

  void _drawSideMedallion(
    Canvas canvas,
    Offset center,
    Paint fill,
    Paint stroke,
  ) {
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 6.5)
      ..lineTo(center.dx + 6.5, center.dy)
      ..lineTo(center.dx, center.dy + 6.5)
      ..lineTo(center.dx - 6.5, center.dy)
      ..close();
    canvas.drawPath(diamond, fill);
    canvas.drawPath(diamond, stroke);
    canvas.drawCircle(center, 2.0, stroke);
  }

  @override
  bool shouldRepaint(covariant _MushafBannerOrnamentPainter oldDelegate) {
    return oldDelegate.goldColor != goldColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
