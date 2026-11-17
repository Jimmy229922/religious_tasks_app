import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/athkar/data/surah_kahf_data.dart';

class SurahKahfScreen extends StatefulWidget {
  const SurahKahfScreen({super.key});

  @override
  State<SurahKahfScreen> createState() => _SurahKahfScreenState();
}

class _SurahKahfScreenState extends State<SurahKahfScreen> {
  double _fontSize = 20.0;
  int _selectedSectionId = 0; // 0 = Full Surah, 1..4 = Sections
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
    final savedVerse = prefs.getString('kahf_bookmark_verse');
    if (savedVerse != null) {
      setState(() {
        _savedBookmarkedVerse = savedVerse;
      });
    }
  }

  Future<void> _onVerseTapped(String verseNum) async {
    final arabicNum = QuranTextFormatter.toArabicDigits(verseNum);

    setState(() {
      _savedBookmarkedVerse = verseNum;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setString('kahf_bookmark_verse', verseNum);

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
    await prefs.remove('kahf_bookmark_verse');
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
    const totalAyahs = 110;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF0FDF4)];

    final List<SurahKahfSection> visibleSections = _selectedSectionId == 0
        ? SurahKahfData.sections
        : SurahKahfData.sections.where((s) => s.id == _selectedSectionId).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "سورة الكهف الشريفة 📖",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: "حجم الخط",
              onPressed: () {
                setState(() {
                  _fontSize = _fontSize == 20.0
                      ? 23.0
                      : _fontSize == 23.0
                          ? 26.0
                          : 20.0;
                });
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

              // Virtue Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.teal.withValues(alpha: 0.3)
                        : Colors.teal.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        SurahKahfData.virtueText,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.teal.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section Selector Filter Chips (Compact titles)
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Chip for "السورة كاملة"
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.menu_book_rounded,
                            size: 15,
                            color: _selectedSectionId == 0
                                ? Colors.white
                                : Colors.teal,
                          ),
                          label: Text(
                            "السورة كاملة",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              color: _selectedSectionId == 0
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.teal.shade900),
                            ),
                          ),
                          selected: _selectedSectionId == 0,
                          selectedColor: Colors.teal,
                          backgroundColor: isDark
                              ? Colors.teal.withValues(alpha: 0.15)
                              : Colors.teal.withValues(alpha: 0.08),
                          onSelected: (_) {
                            setState(() {
                              _selectedSectionId = 0;
                            });
                          },
                        ),
                      ),
                      // Chips for individual sections
                      ...SurahKahfData.sections.map((sec) {
                        final isSelected = _selectedSectionId == sec.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              sec.title,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.teal.shade900),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.teal,
                            backgroundColor: isDark
                                ? Colors.teal.withValues(alpha: 0.15)
                                : Colors.teal.withValues(alpha: 0.08),
                            onSelected: (_) {
                              setState(() {
                                _selectedSectionId = sec.id;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Verses Card List with ScrollController
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: visibleSections.length,
                  itemBuilder: (context, index) {
                    final section = visibleSections[index];
                    return RepaintBoundary(
                      child: _buildSectionCard(context, section, isDark),
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

  Widget _buildSectionCard(
    BuildContext context,
    SurahKahfSection section,
    bool isDark,
  ) {
    const accent = Color(0xFF0F766E);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white10 : accent.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_rounded,
                              color: accent, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              section.title,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.blueAccent, size: 18),
                      tooltip: "مشاركة النص",
                      onPressed: () async {
                        await SharePlus.instance
                            .share(ShareParams(text: section.text));
                        await Clipboard.setData(
                            ClipboardData(text: section.text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم نسخ النص وفتح المشاركة')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.style_rounded,
                          color: accent, size: 20),
                      tooltip: "صانع البطاقات الإيمانية",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => IslamicCardGeneratorDialog(
                            title: section.title,
                            content: section.text,
                            subtitle: section.subtitle,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            Divider(height: 18, color: accent.withValues(alpha: 0.15)),

            // Original Quran Verses Text Container using QuranTextFormatter
            _buildQuranVersesText(section.text, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranVersesText(String text, bool isDark) {
    final baseStyle = GoogleFonts.amiri(
      fontSize: _fontSize,
      height: 2.0,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    );

    return QuranTextFormatter.buildFormattedQuranText(
      text,
      baseStyle: baseStyle,
      badgeColor: const Color(0xFFD4AF37),
      bookmarkedVerse: _savedBookmarkedVerse,
      onTapVerse: _onVerseTapped,
    );
  }
}
