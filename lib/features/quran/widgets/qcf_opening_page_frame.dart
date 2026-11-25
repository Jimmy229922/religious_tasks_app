import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';

class QcfOpeningPageFrame extends StatelessWidget {
  final int pageNumber;
  final String surahName;
  final int ayahCount;
  final bool isDark;
  final Widget versesChild;

  const QcfOpeningPageFrame({
    super.key,
    required this.pageNumber,
    required this.surahName,
    required this.ayahCount,
    required this.isDark,
    required this.versesChild,
  });

  @override
  Widget build(BuildContext context) {
    final goldBright =
        isDark ? const Color(0xFFD9B664) : const Color(0xFFD4AC50);
    final goldDark =
        isDark ? const Color(0xFF8C6924) : const Color(0xFF7D5813);
    final emerald =
        isDark ? const Color(0xFF134E4A) : const Color(0xFF0F5132);
    final sapphire =
        isDark ? const Color(0xFF1E3A5F) : const Color(0xFF1B4965);
    final cartoucheBg =
        isDark ? const Color(0xFF17212B) : const Color(0xFFFDF8EB);
    final textColor =
        isDark ? const Color(0xFFF5E5B8) : const Color(0xFF2B1B08);

    final arabicAyahCount =
        QuranTextFormatter.toArabicDigits(ayahCount.toString());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _IlluminatedBorderPainter(
          goldBright: goldBright,
          goldDark: goldDark,
          emerald: emerald,
          sapphire: sapphire,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IlluminatedBanner(
                title: 'سورة $surahName',
                fontSize: 21,
                goldBright: goldBright,
                goldDark: goldDark,
                emerald: emerald,
                sapphire: sapphire,
                cartoucheBg: cartoucheBg,
                textColor: textColor,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: versesChild,
                ),
              ),
              const SizedBox(height: 8),
              _IlluminatedBanner(
                title: 'عدد آياتها: $arabicAyahCount',
                fontSize: 16,
                goldBright: goldBright,
                goldDark: goldDark,
                emerald: emerald,
                sapphire: sapphire,
                cartoucheBg: cartoucheBg,
                textColor: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IlluminatedBanner extends StatelessWidget {
  final String title;
  final double fontSize;
  final Color goldBright;
  final Color goldDark;
  final Color emerald;
  final Color sapphire;
  final Color cartoucheBg;
  final Color textColor;

  const _IlluminatedBanner({
    required this.title,
    required this.fontSize,
    required this.goldBright,
    required this.goldDark,
    required this.emerald,
    required this.sapphire,
    required this.cartoucheBg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IlluminatedBannerPainter(
        goldBright: goldBright,
        goldDark: goldDark,
        emerald: emerald,
        sapphire: sapphire,
        cartoucheBg: cartoucheBg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 7),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.amiri(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IlluminatedBorderPainter extends CustomPainter {
  final Color goldBright;
  final Color goldDark;
  final Color emerald;
  final Color sapphire;

  const _IlluminatedBorderPainter({
    required this.goldBright,
    required this.goldDark,
    required this.emerald,
    required this.sapphire,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(14),
    );
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      const Radius.circular(11),
    );
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(9.5, 9.5, size.width - 19, size.height - 19),
      const Radius.circular(8),
    );

    final outerStroke = Paint()
      ..color = goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final bandStroke = Paint()
      ..color = sapphire.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final midGoldStroke = Paint()
      ..color = goldBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final innerStroke = Paint()
      ..color = emerald.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(outerRect, outerStroke);
    canvas.drawRRect(bandRect, bandStroke);
    canvas.drawRRect(bandRect, midGoldStroke);
    canvas.drawRRect(innerRect, innerStroke);

    final corners = <Offset>[
      const Offset(11, 11),
      Offset(size.width - 11, 11),
      Offset(11, size.height - 11),
      Offset(size.width - 11, size.height - 11),
    ];
    for (final c in corners) {
      _drawCornerRosette(canvas, c);
    }
  }

  void _drawCornerRosette(Canvas canvas, Offset center) {
    const rOuter = 6.5;
    const rInner = 3.2;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final r = i.isEven ? rOuter : rInner;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = emerald
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = goldBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(
      center,
      1.7,
      Paint()
        ..color = goldBright
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _IlluminatedBorderPainter oldDelegate) {
    return oldDelegate.goldBright != goldBright ||
        oldDelegate.goldDark != goldDark ||
        oldDelegate.emerald != emerald ||
        oldDelegate.sapphire != sapphire;
  }
}

class _IlluminatedBannerPainter extends CustomPainter {
  final Color goldBright;
  final Color goldDark;
  final Color emerald;
  final Color sapphire;
  final Color cartoucheBg;

  const _IlluminatedBannerPainter({
    required this.goldBright,
    required this.goldDark,
    required this.emerald,
    required this.sapphire,
    required this.cartoucheBg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final bgShader = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          emerald.withValues(alpha: 0.16),
          sapphire.withValues(alpha: 0.14),
          goldBright.withValues(alpha: 0.22),
          sapphire.withValues(alpha: 0.14),
          emerald.withValues(alpha: 0.16),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(outerRect, bgShader);

    canvas.drawRRect(
      outerRect,
      Paint()
        ..color = goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final centerCartouche = RRect.fromRectAndRadius(
      Rect.fromLTWH(34, 3.5, size.width - 68, size.height - 7),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      centerCartouche,
      Paint()
        ..color = cartoucheBg
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      centerCartouche,
      Paint()
        ..color = goldBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );

    final cy = size.height / 2;
    _drawSideMedallion(canvas, Offset(17, cy));
    _drawSideMedallion(canvas, Offset(size.width - 17, cy));
  }

  void _drawSideMedallion(Canvas canvas, Offset center) {
    const r = 8.0;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();

    canvas.drawPath(
      diamond,
      Paint()
        ..color = sapphire
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..color = goldBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center,
      3.5,
      Paint()
        ..color = emerald
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      1.6,
      Paint()
        ..color = goldBright
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _IlluminatedBannerPainter oldDelegate) {
    return oldDelegate.goldBright != goldBright ||
        oldDelegate.goldDark != goldDark ||
        oldDelegate.emerald != emerald ||
        oldDelegate.sapphire != sapphire ||
        oldDelegate.cartoucheBg != cartoucheBg;
  }
}
