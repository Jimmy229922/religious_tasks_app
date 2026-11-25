import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/athkar/data/surah_kahf_data.dart';
import 'package:religious_tasks_app/features/quran/data/qcf_mushaf_repository.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/quran/widgets/ayah_tafsir_sheet.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_mushaf_page_widget.dart';

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
  bool _showControls = false;
  int _selectedSectionId = 0; // 0 = Full Surah, 1..4 = Sections
  int _currentPageIndex = 0; // 0..11 for Surah Al-Kahf pages (293..304)
  late PageController _pageController;
  String? _savedBookmarkedVerse;
  int? _savedBookmarkedPage;
  String _savedBookmarkType = 'verse';
  int? _selectedPage;
  int? _selectedAyahNumber;
  String? _inspectingVerse;
  int? _inspectingPage;
  bool _isCompletedToday = false;

  static const int _kahfStartPage = 293;
  static const int _kahfTotalPages = 12; // Pages 293 to 304 (All 110 Verses)

  @override
  void initState() {
    super.initState();
    _initBookmarkAndController();
    _loadCompletionState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    int ayahNumber,
  ) async {
    HapticFeedback.mediumImpact();
    final verseNum = ayahNumber.toString();
    setState(() {
      _inspectingVerse = verseNum;
      _inspectingPage = absolutePage;
    });

    final fullVerseText = await QuranRepository.getVerseText(18, ayahNumber) ?? '';
    if (!mounted) return;

    await showAyahTafsirSheet(
      context: context,
      surahNumber: 18,
      surahName: 'الكهف',
      ayahNumber: ayahNumber,
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    final next = !_showControls;
    setState(() {
      _showControls = next;
    });
    SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _initBookmarkAndController() {
    final prefs = StorageService.instance.prefs;
    final savedPage = prefs.getInt('kahf_bookmark_page');
    final savedVerse = prefs.getString('kahf_bookmark_verse');
    final savedType = prefs.getString('kahf_bookmark_type') ??
        (savedVerse != null && savedVerse.isNotEmpty ? 'verse' : 'page');
    int initialIdx = 0;
    if (savedPage != null || savedVerse != null) {
      initialIdx =
          (savedPage != null) ? (savedPage - _kahfStartPage).clamp(0, 11) : 0;
      _savedBookmarkedPage = savedPage ?? _kahfStartPage;
      _savedBookmarkedVerse = savedVerse;
      _savedBookmarkType = savedType;
      _currentPageIndex = initialIdx;
    }
    _pageController = PageController(initialPage: initialIdx);
    QcfMushafRepository.prefetchAdjacentPages(
      _kahfStartPage + initialIdx,
      onlySurahNumber: 18,
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

  Future<void> _onVerseTapped(int ayahNumber) async {
    HapticFeedback.selectionClick();
    final absolutePage = _kahfStartPage + _currentPageIndex;
    final isAlreadySelected =
        _selectedPage == absolutePage && _selectedAyahNumber == ayahNumber;

    setState(() {
      if (isAlreadySelected) {
        _selectedPage = null;
        _selectedAyahNumber = null;
      } else {
        _selectedPage = absolutePage;
        _selectedAyahNumber = ayahNumber;
      }
    });
  }

  Future<void> _saveKahfPageBookmark(int absolutePage) async {
    setState(() {
      _savedBookmarkedPage = absolutePage;
      _savedBookmarkedVerse = null;
      _savedBookmarkType = 'page';
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('kahf_bookmark_verse');
    await prefs.remove('kahf_bookmark_snippet');
    await prefs.setInt('kahf_bookmark_page', absolutePage);
    await prefs.setString('kahf_bookmark_type', 'page');

    _showStatusToast(
      "تم حفظ الصفحة الحالية: ص (${QuranTextFormatter.toArabicDigits(absolutePage.toString())})",
    );
  }

  Future<void> _saveKahfVerseBookmark(int absolutePage, int ayahNumber) async {
    final verseNum = ayahNumber.toString();
    final arabicNum = QuranTextFormatter.toArabicDigits(verseNum);
    final fullText = await QuranRepository.getVerseText(18, ayahNumber) ?? '';
    final words = fullText.split(RegExp(r'\s+'));
    final snippet =
        words.length <= 7 ? fullText : '${words.take(7).join(' ')} ...';

    if (!mounted) return;
    setState(() {
      _savedBookmarkedVerse = verseNum;
      _savedBookmarkedPage = absolutePage;
      _savedBookmarkType = 'verse';
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setString('kahf_bookmark_verse', verseNum);
    await prefs.setInt('kahf_bookmark_page', absolutePage);
    await prefs.setString('kahf_bookmark_snippet', snippet);
    await prefs.setString('kahf_bookmark_type', 'verse');

    _showStatusToast(
      "تم حفظ الآية المحددة: ص (${QuranTextFormatter.toArabicDigits(absolutePage.toString())}) • آية ($arabicNum)",
    );
  }

  void _showKahfBookmarkOptionsSheet(BuildContext context, bool isDark) {
    final currentAbsPage = _kahfStartPage + _currentPageIndex;
    final hasSelectedVerse =
        _selectedPage == currentAbsPage && _selectedAyahNumber != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF15202B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "حفظ موضع القراءة — سورة الكهف",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading:
                      const Icon(Icons.bookmark_add_rounded, color: Colors.amber),
                  title: Text(
                    "حفظ الصفحة الحالية",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "صفحة ${QuranTextFormatter.toArabicDigits(currentAbsPage.toString())}",
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _saveKahfPageBookmark(currentAbsPage);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.format_quote_rounded,
                    color: hasSelectedVerse ? Colors.amber : Colors.grey,
                  ),
                  title: Text(
                    "حفظ الآية المحددة",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: hasSelectedVerse
                          ? null
                          : (isDark ? Colors.white54 : Colors.grey),
                    ),
                  ),
                  subtitle: Text(
                    hasSelectedVerse
                        ? "آية ${QuranTextFormatter.toArabicDigits(_selectedAyahNumber.toString())}"
                        : "اضغط على أي آية في الصفحة لتحديدها أولاً",
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (hasSelectedVerse) {
                      _saveKahfVerseBookmark(
                        _selectedPage!,
                        _selectedAyahNumber!,
                      );
                    } else {
                      _showStatusToast(
                        "اضغط على الآية لتحديدها ثم اختر حفظ الآية المحددة",
                        icon: Icons.touch_app_rounded,
                      );
                    }
                  },
                ),
                if (_savedBookmarkedPage != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.my_location_rounded,
                        color: Colors.teal),
                    title: Text(
                      "الانتقال للموضع المحفوظ",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _savedBookmarkType == 'verse' &&
                              _savedBookmarkedVerse != null
                          ? "ص ${QuranTextFormatter.toArabicDigits(_savedBookmarkedPage.toString())} • آية ${QuranTextFormatter.toArabicDigits(_savedBookmarkedVerse!)}"
                          : "صفحة ${QuranTextFormatter.toArabicDigits(_savedBookmarkedPage.toString())}",
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                    onTap: () {
                      final pIdx =
                          (_savedBookmarkedPage! - _kahfStartPage).clamp(0, 11);
                      Navigator.pop(ctx);
                      _pageController.animateToPage(
                        pIdx,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    title: Text(
                      "إزالة العلامة",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _clearBookmark();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearBookmark() async {
    setState(() {
      _savedBookmarkedVerse = null;
      _savedBookmarkedPage = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('kahf_bookmark_verse');
    await prefs.remove('kahf_bookmark_page');
    await prefs.remove('kahf_bookmark_snippet');
    await prefs.remove('kahf_bookmark_type');
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

  @override
  Widget build(BuildContext context) {
    const goldLight = Color(0xFFFDE68A);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = context.primaryColor;
    final absolutePageNumber = _kahfStartPage + _currentPageIndex;
    final arabicPageNum = QuranTextFormatter.toArabicDigits(absolutePageNumber.toString());
    final arabicJuzNum = absolutePageNumber >= 302 ? '١٦' : '١٥';

    final paperColor = isDark ? const Color(0xFF121820) : const Color(0xFFFBF7EE);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: paperColor,
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              child: SafeArea(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _kahfTotalPages,
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _currentPageIndex = pageIndex;
                    });
                    QcfMushafRepository.prefetchAdjacentPages(
                      _kahfStartPage + pageIndex,
                      onlySurahNumber: 18,
                    );
                  },
                  itemBuilder: (context, index) {
                    final absolutePage = _kahfStartPage + index;
                    final itemArabicPageNum =
                        QuranTextFormatter.toArabicDigits(
                      absolutePage.toString(),
                    );
                    final cachedPage = QcfMushafRepository.getCachedPage(
                      absolutePage,
                      onlySurahNumber: 18,
                    );

                    return FutureBuilder<QcfMushafPageData>(
                      initialData: cachedPage,
                      future: cachedPage != null
                          ? null
                          : QcfMushafRepository.loadPage(
                              absolutePage,
                              onlySurahNumber: 18,
                            ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: accent,
                                    strokeWidth: 3,
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

                        final pageData = snapshot.data!;
                        String? highlightedKey;
                        if (_inspectingPage == absolutePage &&
                            _inspectingVerse != null) {
                          highlightedKey = '18:$_inspectingVerse';
                        } else if (_selectedPage == absolutePage &&
                            _selectedAyahNumber != null) {
                          highlightedKey = '18:$_selectedAyahNumber';
                        } else if (_savedBookmarkType == 'verse' &&
                            _savedBookmarkedPage == absolutePage &&
                            _savedBookmarkedVerse != null) {
                          final ayahInt = QuranTextFormatter.parseVerseNumber(
                            _savedBookmarkedVerse!,
                          );
                          if (ayahInt != null) {
                            highlightedKey = '18:$ayahInt';
                          }
                        }

                        return QcfMushafPageWidget(
                          pageData: pageData,
                          highlightedVerseKey: highlightedKey,
                          isPageBookmarked:
                              _savedBookmarkedPage == absolutePage,
                          isDark: isDark,
                          accentColor: accent,
                          onTapVerse: (_, ayahNum) => _onVerseTapped(ayahNum),
                          onLongPressVerse: (_, ayahNum) =>
                              _onVerseLongPressed(absolutePage, ayahNum),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: isDark ? const Color(0xFF0A241D) : accent,
                  elevation: 3,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: kToolbarHeight,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark ? goldLight : Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        "سورة الكهف الشريفة",
                                        maxLines: 1,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.5,
                                          color:
                                              isDark ? goldLight : Colors.white,
                                        ),
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        "الجزء $arabicJuzNum • الصفحة $arabicPageNum من ٣٠٤",
                                        maxLines: 1,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _savedBookmarkedPage != null
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_add_outlined,
                                  color: _savedBookmarkedPage != null
                                      ? Colors.amberAccent
                                      : (isDark ? goldLight : Colors.white),
                                ),
                                tooltip: "حفظ موضع القراءة",
                                onPressed: () =>
                                    _showKahfBookmarkOptionsSheet(
                                  context,
                                  isDark,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.amberAccent,
                                ),
                                tooltip: "فضل سورة الكهف",
                                onPressed: () =>
                                    _showVirtueDialog(context, isDark),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: isDark
                              ? const Color(0xFF0E2B22)
                              : Colors.black.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
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
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.teal.shade900),
                                      ),
                                    ),
                                    selected: _selectedSectionId == 0,
                                    selectedColor: Colors.teal,
                                    backgroundColor: Colors.white,
                                    onSelected: (_) => _jumpToSection(0),
                                  ),
                                ),
                                ...SurahKahfData.sections.map((sec) {
                                  final isSelected =
                                      _selectedSectionId == sec.id;
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
                                              : (isDark
                                                  ? Colors.white70
                                                  : Colors.teal.shade900),
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: Colors.teal,
                                      backgroundColor: Colors.white,
                                      onSelected: (_) =>
                                          _jumpToSection(sec.id),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
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
                        onPressed:
                            _isCompletedToday ? null : _markSurahKahfCompleted,
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
                          backgroundColor: _isCompletedToday
                              ? const Color(0xFF10B981)
                              : accent,
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
          ],
        ),
      ),
    );
  }
}
