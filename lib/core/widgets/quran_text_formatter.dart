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

  /// Builds a [Text.rich] widget with custom golden Quranic verse badge ornaments
  static Widget buildFormattedQuranText(
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.center,
    Color? badgeColor,
  }) {
    final spans = buildSpans(
      text,
      baseFontSize: baseStyle.fontSize ?? 18.0,
      badgeColor: badgeColor ?? baseStyle.color ?? defaultGold,
      baseStyle: baseStyle,
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

  /// Parses string and splits into TextSpan and WidgetSpan for verse numbers
  static List<InlineSpan> buildSpans(
    String text, {
    required double baseFontSize,
    required Color badgeColor,
    required TextStyle baseStyle,
  }) {
    final spans = <InlineSpan>[];

    // RegExp to match verse markers: ﴿١﴾, ﴿1﴾, ۝١, (١), etc.
    final pattern = RegExp(
      r'﴿\s*([0-9\u0660-\u0669]+)\s*﴾|۝\s*([0-9\u0660-\u0669]+)|(?:^|\s)[(（]([0-9\u0660-\u0669]+)[)）]',
    );

    int currentPosition = 0;
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      // Add text preceding the match
      if (match.start > currentPosition) {
        _addTextSpansWithOrnaments(
          spans,
          text.substring(currentPosition, match.start),
          baseStyle: baseStyle,
          badgeColor: badgeColor,
        );
      }

      // Extract the verse number string (from group 1, 2, or 3)
      final rawNum = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      final arabicNum = toArabicDigits(rawNum);

      // Create the custom Quran Ayah symbol badge widget
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
            child: QuranAyahSymbolWidget(
              number: arabicNum,
              fontSize: baseFontSize,
              color: badgeColor,
            ),
          ),
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining text after last match
    if (currentPosition < text.length) {
      _addTextSpansWithOrnaments(
        spans,
        text.substring(currentPosition),
        baseStyle: baseStyle,
        badgeColor: badgeColor,
      );
    }

    return spans;
  }

  static void _addTextSpansWithOrnaments(
    List<InlineSpan> spans,
    String segment, {
    required TextStyle baseStyle,
    required Color badgeColor,
  }) {
    // Replace any raw Unicode ornate parentheses \uFD3F (﴿) and \uFD3E (﴾) that don't enclose numbers
    // with clean Arabic guillemet quotes « and » so fallback fonts are never invoked.
    final sanitizedSegment = segment
        .replaceAll('﴿', '«')
        .replaceAll('﴾', '»');

    // Split text segments around « and » to highlight Quranic quotes in golden color
    final quotePattern = RegExp(r'«([^»]+)»');
    int pos = 0;
    final matches = quotePattern.allMatches(sanitizedSegment);

    for (final m in matches) {
      if (m.start > pos) {
        spans.add(TextSpan(text: sanitizedSegment.substring(pos, m.start), style: baseStyle));
      }

      // Opening quote
      spans.add(TextSpan(
        text: '«',
        style: baseStyle.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
      ));

      // Quoted verse content
      spans.add(TextSpan(
        text: m.group(1),
        style: baseStyle.copyWith(
          color: baseStyle.color,
          fontWeight: FontWeight.w600,
        ),
      ));

      // Closing quote
      spans.add(TextSpan(
        text: '»',
        style: baseStyle.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
      ));

      pos = m.end;
    }

    if (pos < sanitizedSegment.length) {
      spans.add(TextSpan(text: sanitizedSegment.substring(pos), style: baseStyle));
    }
  }
}

/// Custom Quran Ayah Symbol Widget that renders the exact Quran Ayah Symbol ۝ frame with the verse number inside
class QuranAyahSymbolWidget extends StatelessWidget {
  final String number;
  final double fontSize;
  final Color color;

  const QuranAyahSymbolWidget({
    super.key,
    required this.number,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = (fontSize * 1.35).clamp(24.0, 36.0);
    final height = (fontSize * 1.45).clamp(28.0, 40.0);
    final numFontSize = (fontSize * 0.58).clamp(11.0, 16.0);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: QuranAyahSymbolPainter(color: color),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 0.5),
            child: Text(
              number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: numFontSize,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter drawing the exact Quran End-Of-Ayah ۝ frame (rounded frame with top and bottom decorative arches)
class QuranAyahSymbolPainter extends CustomPainter {
  final Color color;

  const QuranAyahSymbolPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
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
    return oldDelegate.color != color;
  }
}
