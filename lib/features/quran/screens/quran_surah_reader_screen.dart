import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';

class QuranSurahReaderScreen extends StatefulWidget {
  final SurahInfo surah;

  const QuranSurahReaderScreen({super.key, required this.surah});

  @override
  State<QuranSurahReaderScreen> createState() => _QuranSurahReaderScreenState();
}

class _QuranSurahReaderScreenState extends State<QuranSurahReaderScreen> {
  double _fontSize = 21.0;
  String? _savedBookmarkedVerse;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadBookmark() {
    final prefs = StorageService.instance.prefs;
    final savedVerse = prefs.getString('quran_bookmark_verse_${widget.surah.number}');
    if (savedVerse != null) {
      setState(() {
        _savedBookmarkedVerse = savedVerse;
      });
    }
    // Save last read surah for index screen highlight
    prefs.setInt('last_read_surah_number', widget.surah.number);
    prefs.setString('last_read_surah_name', widget.surah.name);
  }

  Future<void> _onVerseTapped(String verseNum) async {
    final arabicNum = QuranTextFormatter.toArabicDigits(verseNum);

    setState(() {
      _savedBookmarkedVerse = verseNum;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setString('quran_bookmark_verse_${widget.surah.number}', verseNum);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم حفظ موضع القراءة عند الآية ($arabicNum) 📌"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "تم",
            textColor: Colors.amberAccent,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _clearBookmark() async {
    setState(() {
      _savedBookmarkedVerse = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('quran_bookmark_verse_${widget.surah.number}');
  }

  Future<void> _scrollToBookmarkedVerse() async {
    if (_savedBookmarkedVerse == null || !_scrollController.hasClients) return;

    final rawVerse = _savedBookmarkedVerse!;
    final asciiVerse = rawVerse
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    final verseInt = int.tryParse(asciiVerse) ?? 1;
    final totalAyahs = widget.surah.ayahCount > 0 ? widget.surah.ayahCount : 1;
    final ratio = ((verseInt - 1) / totalAyahs).clamp(0.0, 1.0);

    final viewport = _scrollController.position.viewportDimension;
    double maxScroll = _scrollController.position.maxScrollExtent;
    double targetOffset = (ratio * maxScroll - (ratio > 0.05 ? viewport * 0.12 : 0.0)).clamp(0.0, maxScroll);

    // Phase 1: Smooth bidirectional scroll (handles both scrolling UP and DOWN)
    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );

    // Phase 2: Precision final alignment centered at eye level
    if (_scrollController.hasClients) {
      final updatedMaxScroll = _scrollController.position.maxScrollExtent;
      final finalTargetOffset = (ratio * updatedMaxScroll - (ratio > 0.05 ? viewport * 0.12 : 0.0)).clamp(0.0, updatedMaxScroll);

      if ((finalTargetOffset - _scrollController.offset).abs() > 10) {
        await _scrollController.animateTo(
          finalTargetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }

    if (mounted) {
      final arabicNum = QuranTextFormatter.toArabicDigits(rawVerse);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم الانتقال إلى الآية ($arabicNum) 🎯"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<String> _chunkAyahs(String fullText, {int ayahsPerChunk = 8}) {
    final pattern = RegExp(
      r'﴿\s*[0-9\u0660-\u0669]+\s*﴾|۝\s*[0-9\u0660-\u0669]+|(?:^|\s)[(（][0-9\u0660-\u0669]+[)）]',
    );
    final matches = pattern.allMatches(fullText).toList();
    final List<String> chunks = [];

    int currentStart = 0;
    int count = 0;

    for (final m in matches) {
      count++;
      if (count % ayahsPerChunk == 0) {
        final block = fullText.substring(currentStart, m.end).trim();
        if (block.isNotEmpty) {
          chunks.add(block);
        }
        currentStart = m.end;
      }
    }

    if (currentStart < fullText.length) {
      final tail = fullText.substring(currentStart).trim();
      if (tail.isNotEmpty) {
        chunks.add(tail);
      }
    }

    if (chunks.isEmpty && fullText.trim().isNotEmpty) {
      chunks.add(fullText.trim());
    }

    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final solidBgColor = isDark ? const Color(0xFF0B131E) : const Color(0xFFF0FDF4);
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF0FDF4)];

    const accent = Color(0xFF0F766E);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: solidBgColor, // Opaque Solid Background Prevents Screen Bleed-Through
        appBar: AppBar(
          title: Text(
            "سورة ${widget.surah.name}",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF0B131E) : const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: "حجم الخط",
              onPressed: () {
                setState(() {
                  _fontSize = _fontSize == 21.0
                      ? 24.0
                      : _fontSize == 24.0
                          ? 27.0
                          : 21.0;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.style_rounded),
              tooltip: "صانع البطاقات الإيمانية",
              onPressed: () async {
                final fullText = await QuranRepository.getSurahFullText(widget.surah.number);
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => IslamicCardGeneratorDialog(
                    title: "سورة ${widget.surah.name}",
                    content: fullText,
                    subtitle: "${widget.surah.type} • ${widget.surah.ayahCount} آية",
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Saved Bookmark Notice Bar with Tap-To-Auto-Scroll
              if (_savedBookmarkedVerse != null)
                GestureDetector(
                  onTap: _scrollToBookmarkedVerse,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.amber.shade700.withValues(alpha: 0.5)
                            : Colors.amber.shade600.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                Text(
                                  "موقف القراءة عند الآية (${QuranTextFormatter.toArabicDigits(_savedBookmarkedVerse!)})",
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.amber.shade200
                                        : Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "انتقال 🎯",
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.grey),
                          tooltip: "إزالة العلامة",
                          onPressed: _clearBookmark,
                        ),
                      ],
                    ),
                  ),
                ),

              // Surah Header Banner (Loads Instantly 0ms)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${widget.surah.number}",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "سورة ${widget.surah.name}",
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            Text(
                              "${widget.surah.type} • ${widget.surah.ayahCount} آية",
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.blueAccent, size: 20),
                      tooltip: "مشاركة السورة",
                      onPressed: () async {
                        final text = await QuranRepository.getSurahFullText(widget.surah.number);
                        await SharePlus.instance.share(ShareParams(
                            text: 'سورة ${widget.surah.name}\n\n$text'));
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ النص وفتح المشاركة')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Surah Continuous Mushaf Page Card with Lazy Block Chunking
              Expanded(
                child: FutureBuilder<String>(
                  future: QuranRepository.getSurahFullText(widget.surah.number),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: accent,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "جاري قراءة وتجهيز سورة ${widget.surah.name} المباركة...",
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.tealAccent : accent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final surahText =
                        snapshot.data ?? QuranData.getSurahText(widget.surah);
                    final chunks = _chunkAyahs(surahText, ayahsPerChunk: 8);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white10 : accent.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20.0),
                          itemCount: chunks.length + (widget.surah.number != 9 && widget.surah.number != 1 ? 1 : 0),
                          itemBuilder: (context, index) {
                            final hasBismillahHeader = widget.surah.number != 9 && widget.surah.number != 1;

                            if (hasBismillahHeader && index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.amiri(
                                        fontSize: _fontSize * 1.1,
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                      ),
                                    ),
                                    Divider(height: 24, color: accent.withValues(alpha: 0.2)),
                                  ],
                                ),
                              );
                            }

                            final chunkIndex = hasBismillahHeader ? index - 1 : index;
                            final chunkText = chunks[chunkIndex];

                            return RepaintBoundary(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: QuranTextFormatter.buildFormattedQuranText(
                                  chunkText,
                                  baseStyle: GoogleFonts.amiri(
                                    fontSize: _fontSize,
                                    height: 2.1,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  badgeColor: const Color(0xFFD4AF37),
                                  bookmarkedVerse: _savedBookmarkedVerse,
                                  onTapVerse: _onVerseTapped,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
