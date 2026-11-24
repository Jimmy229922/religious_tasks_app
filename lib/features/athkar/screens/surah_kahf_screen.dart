import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/athkar/data/surah_kahf_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/quran/widgets/ayah_tafsir_sheet.dart';

class SurahKahfScreen extends StatefulWidget {
  const SurahKahfScreen({super.key});

  static const String fridayDismissedDateKey = 'friday_kahf_dismissed_date_v1';

  static String todayDateKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  @override
  State<SurahKahfScreen> createState() => _SurahKahfScreenState();
}

class _SurahKahfScreenState extends State<SurahKahfScreen> {
  double _fontSize = 18.0;
  int _selectedSectionId = 0; // 0 = Full Surah, 1..4 = Sections
  int _currentPageIndex = 0; // 0..11 for Surah Al-Kahf pages (293..304)
  late PageController _pageController;
  String? _savedBookmarkedVerse;
  int? _savedBookmarkedPage;
  String? _savedBookmarkedSnippet;
  String? _inspectingVerse;
  int? _inspectingPage;
  final Map<int, ScrollController> _pageScrollControllers = {};
  bool _isCompletedToday = false;

  static const int _kahfStartPage = 293;
  static const int _kahfTotalPages = 12; // Pages 293 to 304 (All 110 Verses)

  @override
  void initState() {
    super.initState();
    _initBookmarkAndController();
    _loadCompletionState();
  }

  Future<void> _loadCompletionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(SurahKahfScreen.fridayDismissedDateKey);
      if (!mounted) return;
      setState(() {
        _isCompletedToday = savedDate == SurahKahfScreen.todayDateKey();
      });
    } catch (_) {}
  }

  Future<void> _markSurahKahfCompleted() async {
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SurahKahfScreen.fridayDismissedDateKey,
        SurahKahfScreen.todayDateKey(),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isCompletedToday = true;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تقبل الله منك! تم تسجيل إتمام قراءة سورة الكهف اليوم 🌿",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onVerseLongPressed(
    int absolutePage,
    String verseNum,
    String pageText,
  ) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _inspectingVerse = verseNum;
      _inspectingPage = absolutePage;
    });

    final ayahInt = QuranTextFormatter.parseVerseNumber(verseNum) ?? 1;
    var fullVerseText = QuranTextFormatter.extractFullVerseText(
      pageText,
      verseNum,
    );
    if (fullVerseText.isEmpty) {
      fullVerseText = await QuranRepository.getVerseText(18, ayahInt) ?? '';
    }
    if (!mounted) return;

    await showAyahTafsirSheet(
      context: context,
      surahNumber: 18,
      surahName: 'الكهف',
      ayahNumber: ayahInt,
      ayahText: fullVerseText,
    );

    if (!mounted) return;
    setState(() {
      _inspectingVerse = null;
      _inspectingPage = null;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _pageScrollControllers.values) {
      controller.dispose();
    }
    _pageScrollControllers.clear();
    super.dispose();
  }

  ScrollController _getPageScrollController(int absolutePage) {
    return _pageScrollControllers.putIfAbsent(
      absolutePage,
      () => ScrollController(),
    );
  }

  void _scrollToBookmarkedVerse(int absolutePage) {
    if (_savedBookmarkedPage != absolutePage || _savedBookmarkedVerse == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      final controller = _pageScrollControllers[absolutePage];
      if (controller == null || !controller.hasClients) return;
      final maxExtent = controller.position.maxScrollExtent;
      if (maxExtent <= 0) return;

      final content = await QuranRepository.getPageContent(
        absolutePage,
        filterKahfOnly: true,
      );
      if (!mounted || !controller.hasClients) return;
      final ratio = QuranTextFormatter.getVerseScrollRatio(
        content.contentText,
        _savedBookmarkedVerse!,
      );
      final targetOffset = (maxExtent * ratio).clamp(0.0, maxExtent);
      controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _initBookmarkAndController() {
    final prefs = StorageService.instance.prefs;
    final savedPage = prefs.getInt('kahf_bookmark_page');
    final savedVerse = prefs.getString('kahf_bookmark_verse');
    final savedSnippet = prefs.getString('kahf_bookmark_snippet');
    int initialIdx = 0;
    if (savedPage != null || savedVerse != null) {
      initialIdx =
          (savedPage != null) ? (savedPage - _kahfStartPage).clamp(0, 11) : 0;
      _savedBookmarkedPage = savedPage ?? _kahfStartPage;
      _savedBookmarkedVerse = savedVerse;
      _savedBookmarkedSnippet = savedSnippet;
      _currentPageIndex = initialIdx;
    }
    _pageController = PageController(initialPage: initialIdx);
    QuranRepository.prefetchAdjacentPages(
      _kahfStartPage + initialIdx,
      filterKahfOnly: true,
    );
  }

  void _showStatusToast(
    String message, {
    IconData icon = Icons.bookmark_added_rounded,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        elevation: 4,
        backgroundColor: const Color(0xFF0F172A),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.amber.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onVerseTapped(String verseNum, String pageText) async {
    final absolutePage = _kahfStartPage + _currentPageIndex;
    final isSameBookmark = _savedBookmarkedPage == absolutePage &&
        _savedBookmarkedVerse == verseNum;

    if (isSameBookmark) {
      _clearBookmark();
      _showStatusToast(
        "تم إلغاء تحديد الآية (${QuranTextFormatter.toArabicDigits(verseNum)})",
        icon: Icons.bookmark_remove_rounded,
      );
      return;
    }

    final arabicNum = QuranTextFormatter.toArabicDigits(verseNum);
    final snippet = QuranTextFormatter.extractVerseSnippet(pageText, verseNum);

    setState(() {
      _savedBookmarkedVerse = verseNum;
      _savedBookmarkedPage = absolutePage;
      _savedBookmarkedSnippet = snippet;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setString('kahf_bookmark_verse', verseNum);
    await prefs.setInt('kahf_bookmark_page', absolutePage);
    await prefs.setString('kahf_bookmark_snippet', snippet);

    _showStatusToast(
      "تم حفظ موضع القراءة: ص (${QuranTextFormatter.toArabicDigits(absolutePage.toString())}) • آية ($arabicNum)",
    );
  }

  void _clearBookmark() async {
    setState(() {
      _savedBookmarkedVerse = null;
      _savedBookmarkedPage = null;
      _savedBookmarkedSnippet = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('kahf_bookmark_verse');
    await prefs.remove('kahf_bookmark_page');
    await prefs.remove('kahf_bookmark_snippet');
  }

  void _jumpToSection(int sectionId) {
    setState(() {
      _selectedSectionId = sectionId;
    });
    int targetPageIdx = 0;
    if (sectionId == 1) targetPageIdx = 0; // Verses 1..27 (Page 293)
    if (sectionId == 2) targetPageIdx = 3; // Verses 28..45 (Page 296)
    if (sectionId == 3) targetPageIdx = 6; // Verses 46..74 (Page 299)
    if (sectionId == 4) targetPageIdx = 9; // Verses 75..110 (Page 302)

    _pageController.animateToPage(
      targetPageIdx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showVirtueDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark
                  ? Colors.teal.withValues(alpha: 0.35)
                  : Colors.teal.withValues(alpha: 0.2),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                "فضل قراءة سورة الكهف",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            SurahKahfData.virtueText,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 19,
              height: 1.8,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.teal.shade900,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "حسناً",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.tealAccent : context.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarkDetailsDialog(BuildContext context, bool isDark) {
    if (_savedBookmarkedVerse == null || _savedBookmarkedPage == null) return;
    final arabicPage = QuranTextFormatter.toArabicDigits(
      _savedBookmarkedPage.toString(),
    );
    final arabicVerse = QuranTextFormatter.toArabicDigits(_savedBookmarkedVerse!);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark
                  ? Colors.amber.shade700.withValues(alpha: 0.45)
                  : Colors.amber.shade600.withValues(alpha: 0.5),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                "موقف قراءة سورة الكهف",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "سورة الكهف",
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "الصفحة ($arabicPage) • الآية ($arabicVerse)",
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              if (_savedBookmarkedSnippet != null &&
                  _savedBookmarkedSnippet!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.amber.withValues(alpha: 0.1)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    "«$_savedBookmarkedSnippet»",
                    style: GoogleFonts.amiri(
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.amber.shade100
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _clearBookmark();
              },
              child: Text(
                "إزالة العلامة",
                style: GoogleFonts.cairo(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
              ),
              onPressed: () {
                final targetAbsolutePage = _savedBookmarkedPage!;
                final pIdx = (targetAbsolutePage - _kahfStartPage).clamp(0, 11);
                Navigator.pop(ctx);
                _pageController.animateToPage(
                  pIdx,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
                _scrollToBookmarkedVerse(targetAbsolutePage);
              },
              child: Text(
                "انتقال 🎯",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF0FDF4)];

    final accent = context.primaryColor;
    final absolutePageNumber = _kahfStartPage + _currentPageIndex;
    final arabicPageNum = QuranTextFormatter.toArabicDigits(absolutePageNumber.toString());
    final arabicJuzNum = absolutePageNumber >= 302 ? '١٦' : '١٥';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  "سورة الكهف الشريفة",
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  "الجزء $arabicJuzNum • الصفحة $arabicPageNum من ٣٠٤",
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF0B131E) : accent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            if (_savedBookmarkedVerse != null && _savedBookmarkedPage != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.amberAccent,
                ),
                tooltip: "موقف القراءة الحالي",
                onPressed: () => _showBookmarkDetailsDialog(context, isDark),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.menu_book_rounded,
                  color: Colors.amberAccent),
              tooltip: "فضل سورة الكهف",
              onPressed: () => _showVirtueDialog(context, isDark),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.format_size_rounded),
              tooltip: "حجم الخط",
              onPressed: () {
                setState(() {
                  _fontSize = _fontSize == 18.0
                      ? 20.0
                      : _fontSize == 20.0
                          ? 22.0
                          : 18.0;
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
              // Section Selector Filter Chips (Story Jumps)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Chip for "السورة كاملة"
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          avatar: Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: _selectedSectionId == 0
                                ? Colors.white
                                : Colors.teal,
                          ),
                          label: Text(
                            "السورة كاملة (١٢ صفحة)",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
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
                          onSelected: (_) => _jumpToSection(0),
                        ),
                      ),
                      // Chips for individual story sections
                      ...SurahKahfData.sections.map((sec) {
                        final isSelected = _selectedSectionId == sec.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(
                              sec.title,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
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
                            onSelected: (_) => _jumpToSection(sec.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Surah Al-Kahf 12-Page Fullscreen Mushaf Viewer (Pages 293..304 COMPLETE)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _kahfTotalPages, // EXACTLY 12 pages (293..304)
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _currentPageIndex = pageIndex;
                    });
                    QuranRepository.prefetchAdjacentPages(
                      _kahfStartPage + pageIndex,
                      filterKahfOnly: true,
                    );
                  },
                  itemBuilder: (context, index) {
                    final absolutePage = _kahfStartPage + index;
                    final itemArabicPageNum =
                        QuranTextFormatter.toArabicDigits(
                      absolutePage.toString(),
                    );
                    final cachedPage = QuranRepository.getCachedPageContent(
                      absolutePage,
                      filterKahfOnly: true,
                    );

                    return FutureBuilder<MushafPageContent>(
                      initialData: cachedPage,
                      future: cachedPage != null
                          ? null
                          : QuranRepository.getPageContent(
                              absolutePage,
                              filterKahfOnly: true,
                            ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
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
                                  child: SizedBox(
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
                                  "جاري فتح الصفحة $itemArabicPageNum من سورة الكهف...",
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

                        final pageData = snapshot.data;
                        final pageText = pageData?.contentText ?? "";

                        return RepaintBoundary(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white10 : accent.withValues(alpha: 0.22),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Column(
                                children: [
                                  // Authentic Mushaf Top Header Row (Surah Name Right • Juz Left)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "سورة الكهف",
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.tealAccent : accent,
                                        ),
                                      ),
                                      Text(
                                        "الجزء ${QuranTextFormatter.toArabicDigits(pageData?.juz.toString() ?? '15')}",
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(height: 8, color: accent.withValues(alpha: 0.2)),

                                  // Page Body
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final headerOverhead =
                                            absolutePage == 293 ? 82.0 : 0.0;
                                        final typography = QuranTextFormatter
                                            .computeMushafTypography(
                                          cacheKey: 'kahf_$absolutePage',
                                          sectionTexts: [pageText],
                                          maxWidth: constraints.maxWidth,
                                          maxHeight: constraints.maxHeight,
                                          userScaleFactor: _fontSize / 18.0,
                                          headerOverheadHeight: headerOverhead,
                                          baseTextStyle: GoogleFonts.amiri(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );

                                        return SingleChildScrollView(
                                          controller: _getPageScrollController(
                                            absolutePage,
                                          ),
                                          physics: const BouncingScrollPhysics(),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: constraints.maxHeight,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // Iconic Opening Ornament Header on Page 293 (Surah Start)
                                                if (absolutePage == 293) ...[
                                                  MushafSurahHeaderBanner(
                                                    surahName: "الْكَهْفِ",
                                                    fontSize: (typography
                                                                .fontSize *
                                                            0.9)
                                                        .clamp(17.0, 22.0),
                                                    accentColor: accent,
                                                    isDark: isDark,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 6,
                                                    ),
                                                    child: Text(
                                                      "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts.amiri(
                                                        fontSize: (typography
                                                                    .fontSize *
                                                                0.95)
                                                            .clamp(17.0, 23.0),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isDark
                                                            ? Colors.tealAccent
                                                            : accent,
                                                      ),
                                                    ),
                                                  ),
                                                ],

                                                // Page Verses Text
                                                QuranTextFormatter
                                                    .buildFormattedQuranText(
                                                  pageText,
                                                  textAlign: QuranTextFormatter
                                                          .shouldJustifyText(
                                                    pageText,
                                                    pageNumber: absolutePage,
                                                  )
                                                      ? TextAlign.justify
                                                      : TextAlign.center,
                                                  baseStyle: GoogleFonts.amiri(
                                                    fontSize:
                                                        typography.fontSize,
                                                    height:
                                                        typography.lineHeight,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          ),
                                                  ),
                                                  badgeColor: const Color(
                                                    0xFFD4AF37,
                                                  ),
                                                  isDark: isDark,
                                                  bookmarkedVerse: (_inspectingPage ==
                                                              absolutePage &&
                                                          _inspectingVerse !=
                                                              null)
                                                      ? _inspectingVerse
                                                      : (_savedBookmarkedPage ==
                                                              absolutePage
                                                          ? _savedBookmarkedVerse
                                                          : null),
                                                  onTapVerse: (vNum) =>
                                                      _onVerseTapped(
                                                    vNum,
                                                    pageText,
                                                  ),
                                                  onLongPressVerse: (vNum) =>
                                                      _onVerseLongPressed(
                                                    absolutePage,
                                                    vNum,
                                                    pageText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Authentic Mushaf Bottom Footer Row (Centered Page Number)
                                  Divider(height: 8, color: accent.withValues(alpha: 0.2)),
                                  Text(
                                    "— $itemArabicPageNum —",
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.tealAccent : accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isCompletedToday ? null : _markSurahKahfCompleted,
                icon: Icon(
                  _isCompletedToday
                      ? Icons.verified_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                ),
                label: Text(
                  _isCompletedToday
                      ? "تم إتمام قراءة سورة الكهف اليوم ✓"
                      : "أتممت قراءة سورة الكهف",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCompletedToday ? const Color(0xFF10B981) : accent,
                  disabledBackgroundColor:
                      const Color(0xFF10B981).withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
