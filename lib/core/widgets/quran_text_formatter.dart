import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class QuranTextFormatter {
  static const Color defaultGold = Color(0xFFD4AF37);

  /// Converts English/ASCII digits to Eastern Arabic Indic digits (١, ٢, ٣...)
  static String toArabicDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
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

  /// Builds a [Text.rich] widget with custom golden Quranic verse badge ornaments and Ayah-level highlighting & tapping
  static Widget buildFormattedQuranText(
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.center,
    Color? badgeColor,
    String? bookmarkedVerse,
    void Function(String verseNumber)? onTapVerse,
  }) {
    final spans = buildSpans(
      text,
      baseFontSize: baseStyle.fontSize ?? 18.0,
      badgeColor: badgeColor ?? baseStyle.color ?? defaultGold,
      baseStyle: baseStyle,
      bookmarkedVerse: bookmarkedVerse,
      onTapVerse: onTapVerse,
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

  /// Parses string and splits into TextSpan and WidgetSpan for verse numbers and Ayah-level tapping
  static List<InlineSpan> buildSpans(
    String text, {
    required double baseFontSize,
    required Color badgeColor,
    required TextStyle baseStyle,
    String? bookmarkedVerse,
    void Function(String verseNumber)? onTapVerse,
  }) {
    final spans = <InlineSpan>[];

    // RegExp to match verse markers: ﴿١﴾, ﴿1﴾, ۝١, (١), etc.
    final pattern = RegExp(
      r'﴿\s*([0-9\u0660-\u0669]+)\s*﴾|۝\s*([0-9\u0660-\u0669]+)|(?:^|\s)[(（]([0-9\u0660-\u0669]+)[)）]',
    );

    int currentPosition = 0;
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final rawNum = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      final arabicNum = toArabicDigits(rawNum);

      final isBookmarked = bookmarkedVerse != null &&
          (bookmarkedVerse == rawNum || bookmarkedVerse == arabicNum);

      // Add text preceding the match (the Ayah text)
      if (match.start > currentPosition) {
        final ayahSegment = text.substring(currentPosition, match.start);
        final ayahStyle = isBookmarked
            ? baseStyle.copyWith(
                color: const Color(0xFFD97706),
                backgroundColor: const Color(0x44FDE68A),
                fontWeight: FontWeight.bold,
              )
            : baseStyle;

        if (onTapVerse != null) {
          spans.add(
            TextSpan(
              text: ayahSegment,
              style: ayahStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => onTapVerse(rawNum),
            ),
          );
        } else {
          spans.add(TextSpan(text: ayahSegment, style: ayahStyle));
        }
      }

      // Create the custom Quran Ayah symbol badge widget
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: QuranAyahSymbolWidget(
              number: arabicNum,
              fontSize: baseFontSize,
              color: badgeColor,
              isBookmarked: isBookmarked,
              onTap: onTapVerse != null ? () => onTapVerse(rawNum) : null,
            ),
          ),
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining text after last match
    if (currentPosition < text.length) {
      final remaining = text.substring(currentPosition);
      if (onTapVerse != null) {
        spans.add(
          TextSpan(
            text: remaining,
            style: baseStyle,
          ),
        );
      } else {
        spans.add(TextSpan(text: remaining, style: baseStyle));
      }
    }

    return spans;
  }
}

/// Custom Quran Ayah Symbol Widget that renders the exact Quran Ayah Symbol ۝ frame with the verse number inside
class QuranAyahSymbolWidget extends StatelessWidget {
  final String number;
  final double fontSize;
  final Color color;
  final bool isBookmarked;
  final VoidCallback? onTap;

  const QuranAyahSymbolWidget({
    super.key,
    required this.number,
    required this.fontSize,
    required this.color,
    this.isBookmarked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (fontSize * 1.35).clamp(24.0, 36.0);
    final height = (fontSize * 1.45).clamp(28.0, 40.0);
    final numFontSize = (fontSize * 0.58).clamp(11.0, 16.0);

    final badgeColor = isBookmarked ? const Color(0xFFD97706) : color;

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
                color: isBookmarked ? const Color(0xFFD97706) : color,
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
