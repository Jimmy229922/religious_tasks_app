import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/services/quran_tafsir_service.dart';

Future<void> showAyahTafsirSheet({
  required BuildContext context,
  required int surahNumber,
  required String surahName,
  required int ayahNumber,
  required String ayahText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AyahTafsirBottomSheet(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
      ayahText: ayahText,
    ),
  );
}

class _AyahTafsirBottomSheet extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;

  const _AyahTafsirBottomSheet({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  State<_AyahTafsirBottomSheet> createState() => _AyahTafsirBottomSheetState();
}

class _AyahTafsirBottomSheetState extends State<_AyahTafsirBottomSheet> {
  QuranTafsirSource _selectedSource = QuranTafsirSource.muyassar;
  QuranTafsirResult? _result;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await QuranTafsirService.fetchAyahTafsir(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      source: _selectedSource,
    );
    if (!mounted) return;
    setState(() {
      _result = res;
      _isLoading = false;
      _hasError = res == null;
    });
  }

  void _copyContent() {
    final arabicAyah =
        QuranTextFormatter.toArabicDigits(widget.ayahNumber.toString());
    final tafsirPart = _result != null
        ? '\n\n${_selectedSource.label}:\n${_result!.text}'
        : '';
    final full =
        '﴿${widget.ayahText}﴾\n[سورة ${widget.surahName} - آية $arabicAyah]$tafsirPart';
    Clipboard.setData(ClipboardData(text: full));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الآية والتفسير ✓',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareContent() {
    final arabicAyah =
        QuranTextFormatter.toArabicDigits(widget.ayahNumber.toString());
    final tafsirPart = _result != null
        ? '\n\n${_selectedSource.label}:\n${_result!.text}'
        : '';
    final full =
        '﴿${widget.ayahText}﴾\n[سورة ${widget.surahName} - آية $arabicAyah]$tafsirPart';
    SharePlus.instance.share(ShareParams(text: full));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    const gold = Color(0xFFD4AF37);
    final arabicAyah =
        QuranTextFormatter.toArabicDigits(widget.ayahNumber.toString());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121A24) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: gold.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سورة ${widget.surahName} • آية $arabicAyah',
                              style: GoogleFonts.cairo(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'التفسير وبيان معاني الآية',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'نسخ',
                        icon: Icon(Icons.copy_rounded, size: 20, color: accent),
                        onPressed: _copyContent,
                      ),
                      IconButton(
                        tooltip: 'مشاركة',
                        icon: Icon(Icons.share_rounded, size: 20, color: accent),
                        onPressed: _shareContent,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: QuranTafsirSource.values.map((src) {
                      final selected = _selectedSource == src;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: src == QuranTafsirSource.muyassar ? 6 : 0,
                          ),
                          child: InkWell(
                            onTap: () {
                              if (_selectedSource == src) return;
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSource = src);
                              _loadTafsir();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: selected
                                    ? accent
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                src.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.amber.withValues(alpha: 0.09)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          '${widget.ayahText} ﴿$arabicAyah﴾',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            height: 1.85,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: accent),
                                const SizedBox(height: 12),
                                Text(
                                  'جاري جلب ${_selectedSource.label}...',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_hasError || _result == null)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 32,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تعذر جلب التفسير حالياً. تأكد من اتصالك بالإنترنت للمرة الأولى لهذه الآية ثم حاول مجدداً.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadTafsir,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(
                                  'إعادة المحاولة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    size: 17,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedSource.label,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                _result!.text,
                                style: GoogleFonts.cairo(
                                  fontSize: 14.5,
                                  height: 1.85,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'المصدر: ${_result!.sourceName}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
