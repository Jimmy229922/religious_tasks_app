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
import 'package:religious_tasks_app/features/quran/theme/mushaf_reader_theme.dart';
import 'package:religious_tasks_app/features/quran/widgets/ayah_tafsir_sheet.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_scroll_physics.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_side_indicator.dart';
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
  final ValueNotifier<bool> _showControlsNotifier = ValueNotifier<bool>(false);
  int _selectedSectionId = 0; // 0 = Full Surah, 1..4 = Sections
  int _currentPageIndex = 0; // 0..11 for Surah Al-Kahf pages (293..304)
  final ValueNotifier<int> _currentPageIndexNotifier = ValueNotifier<int>(0);
  late PageController _pageController;
  int? _savedPageBookmark;
  int? _savedVerseBookmarkPage;
  String? _savedVerseBookmarkVerse;
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
    final arabicAyah = QuranTextFormatter.toArabicDigits(verseNum);
    final isAlreadySelected =
        _selectedPage == absolutePage && _selectedAyahNumber == ayahNumber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    setState(() {
      _inspectingVerse = verseNum;
      _inspectingPage = absolutePage;
    });

    final action = await showModalBottomSheet<String>(
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
                  "سورة الكهف • آية $arabicAyah",
                  style: GoogleFonts.cairo(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(
                    isAlreadySelected
                        ? Icons.bookmark_remove_rounded
                        : Icons.highlight_alt_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(
                    isAlreadySelected ? "إلغاء تحديد الآية" : "تحديد الآية",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.pop(ctx, 'select'),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: Colors.teal),
                  title: Text(
                    "تفسير الآية",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.pop(ctx, 'tafsir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'select') {
      setState(() {
        _inspectingVerse = null;
        _inspectingPage = null;
      });
      _toggleKahfVerseSelection(absolutePage, ayahNumber);
      return;
    }

    if (action == 'tafsir') {
      final fullVerseText =
          await QuranRepository.getVerseText(18, ayahNumber) ?? '';
      if (!mounted) return;
      await showAyahTafsirSheet(
        context: context,
        surahNumber: 18,
        surahName: 'الكهف',
        ayahNumber: ayahNumber,
        ayahText: fullVerseText,
      );
    }

    if (!mounted) return;
    setState(() {
      _inspectingVerse = null;
      _inspectingPage = null;
    });
  }

  @override
  void dispose() {
    _showControlsNotifier.dispose();
    _currentPageIndexNotifier.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    final next = !_showControls;
    _showControls = next;
    _showControlsNotifier.value = next;
    SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _initBookmarkAndController() {
    final prefs = StorageService.instance.prefs;
    int? pageBm = prefs.getInt('kahf_page_bookmark_number');
    int? verseBmPage = prefs.getInt('kahf_verse_bookmark_page');
    String? verseBmNum = prefs.getString('kahf_verse_bookmark_verse');

    final legacyPage = prefs.getInt('kahf_bookmark_page');
    final legacyVerse = prefs.getString('kahf_bookmark_verse');
    final legacyType = prefs.getString('kahf_bookmark_type') ??
        (legacyVerse != null && legacyVerse.isNotEmpty ? 'verse' : 'page');

    if (pageBm == null && legacyPage != null && legacyType == 'page') {
      pageBm = legacyPage;
    }
    if (verseBmNum == null && legacyVerse != null && legacyVerse.isNotEmpty) {
      verseBmPage = legacyPage;
      verseBmNum = legacyVerse;
    }

    int initialIdx = 0;
    final openPage = verseBmPage ?? pageBm;
    if (openPage != null) {
      initialIdx = (openPage - _kahfStartPage).clamp(0, 11);
    }
    _savedPageBookmark = pageBm;
    _savedVerseBookmarkPage = verseBmPage;
    _savedVerseBookmarkVerse = verseBmNum;
    _currentPageIndex = initialIdx;
    _currentPageIndexNotifier.value = initialIdx;

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

  Future<void> _toggleKahfVerseSelection(
    int absolutePage,
    int ayahNumber,
  ) async {
    final verseNum = ayahNumber.toString();
    final isAlreadySelected = (_selectedPage == absolutePage &&
            _selectedAyahNumber == ayahNumber) ||
        (_savedVerseBookmarkPage == absolutePage &&
            _savedVerseBookmarkVerse == verseNum);

    if (isAlreadySelected) {
      setState(() {
        _selectedPage = null;
        _selectedAyahNumber = null;
      });
      await _clearKahfVerseBookmark();
      final arabicAyah = QuranTextFormatter.toArabicDigits(verseNum);
      _showStatusToast(
        "تم إلغاء تحديد وحفظ الآية ($arabicAyah)",
        icon: Icons.bookmark_remove_rounded,
      );
    } else {
      setState(() {
        _selectedPage = absolutePage;
        _selectedAyahNumber = ayahNumber;
      });
      await _saveKahfVerseBookmark(absolutePage, ayahNumber);
    }
  }

  Future<void> _saveKahfPageBookmark(int absolutePage) async {
    setState(() {
      _savedPageBookmark = absolutePage;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.setInt('kahf_page_bookmark_number', absolutePage);
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
      _savedVerseBookmarkVerse = verseNum;
      _savedVerseBookmarkPage = absolutePage;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setInt('kahf_verse_bookmark_page', absolutePage);
    await prefs.setString('kahf_verse_bookmark_verse', verseNum);
    await prefs.setString('kahf_bookmark_verse', verseNum);
    await prefs.setInt('kahf_bookmark_page', absolutePage);
    await prefs.setString('kahf_bookmark_snippet', snippet);
    await prefs.setString('kahf_bookmark_type', 'verse');

    _showStatusToast(
      "تم حفظ الآية المحددة: ص (${QuranTextFormatter.toArabicDigits(absolutePage.toString())}) • آية ($arabicNum)",
    );
  }

  Future<void> _clearKahfPageBookmark() async {
    setState(() => _savedPageBookmark = null);
    final prefs = StorageService.instance.prefs;
    await prefs.remove('kahf_page_bookmark_number');
    if (_savedVerseBookmarkPage != null && _savedVerseBookmarkVerse != null) {
      await prefs.setInt('kahf_bookmark_page', _savedVerseBookmarkPage!);
      await prefs.setString('kahf_bookmark_verse', _savedVerseBookmarkVerse!);
      await prefs.setString('kahf_bookmark_type', 'verse');
    } else {
      await prefs.remove('kahf_bookmark_verse');
      await prefs.remove('kahf_bookmark_page');
      await prefs.remove('kahf_bookmark_snippet');
      await prefs.remove('kahf_bookmark_type');
    }
  }

  Future<void> _clearKahfVerseBookmark() async {
    setState(() {
      _savedVerseBookmarkPage = null;
      _savedVerseBookmarkVerse = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('kahf_verse_bookmark_page');
    await prefs.remove('kahf_verse_bookmark_verse');
    if (_savedPageBookmark != null) {
      await prefs.remove('kahf_bookmark_verse');
      await prefs.remove('kahf_bookmark_snippet');
      await prefs.setInt('kahf_bookmark_page', _savedPageBookmark!);
      await prefs.setString('kahf_bookmark_type', 'page');
    } else {
      await prefs.remove('kahf_bookmark_verse');
      await prefs.remove('kahf_bookmark_page');
      await prefs.remove('kahf_bookmark_snippet');
      await prefs.remove('kahf_bookmark_type');
    }
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
                        : "اضغط مطولاً على أي آية واختر تحديد الآية أولاً",
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
                        "اضغط مطولاً على الآية واختر تحديد الآية أولاً",
                        icon: Icons.touch_app_rounded,
                      );
                    }
                  },
                ),
                if (_savedPageBookmark != null ||
                    (_savedVerseBookmarkPage != null &&
                        _savedVerseBookmarkVerse != null)) ...[
                  const Divider(),
                  if (_savedPageBookmark != null)
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded,
                          color: Colors.teal),
                      title: Text(
                        "الانتقال للصفحة المحفوظة",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "صفحة ${QuranTextFormatter.toArabicDigits(_savedPageBookmark.toString())}",
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearKahfPageBookmark();
                        },
                      ),
                      onTap: () {
                        final pIdx =
                            (_savedPageBookmark! - _kahfStartPage).clamp(0, 11);
                        Navigator.pop(ctx);
                        _pageController.animateToPage(
                          pIdx,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    ),
                  if (_savedVerseBookmarkPage != null &&
                      _savedVerseBookmarkVerse != null)
                    ListTile(
                      leading: const Icon(Icons.my_location_rounded,
                          color: Colors.amber),
                      title: Text(
                        "الانتقال للآية المحفوظة",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "ص ${QuranTextFormatter.toArabicDigits(_savedVerseBookmarkPage.toString())} • آية ${QuranTextFormatter.toArabicDigits(_savedVerseBookmarkVerse!)}",
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearKahfVerseBookmark();
                        },
                      ),
                      onTap: () {
                        final pIdx = (_savedVerseBookmarkPage! - _kahfStartPage)
                            .clamp(0, 11);
                        Navigator.pop(ctx);
                        _pageController.animateToPage(
                          pIdx,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = context.primaryColor;
    final paperColor = isDark ? const Color(0xFF121820) : const Color(0xFFFBF7EE);
    final readerTheme = MushafReaderTheme.of(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: readerTheme.statusBarOverlayStyle,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        backgroundColor: paperColor,
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              child: SafeArea(
                top: false,
                child: PageView.builder(
                  controller: _pageController,
                  allowImplicitScrolling: true,
                  physics: const MushafPageScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  itemCount: _kahfTotalPages,
                  onPageChanged: (pageIndex) {
                    _currentPageIndex = pageIndex;
                    _currentPageIndexNotifier.value = pageIndex;
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
                        } else if (_savedVerseBookmarkPage == absolutePage &&
                            _savedVerseBookmarkVerse != null) {
                          final ayahInt = QuranTextFormatter.parseVerseNumber(
                            _savedVerseBookmarkVerse!,
                          );
                          if (ayahInt != null) {
                            highlightedKey = '18:$ayahInt';
                          }
                        }

                        return QcfMushafPageWidget(
                          pageData: pageData,
                          highlightedVerseKey: highlightedKey,
                          isPageBookmarked: _savedPageBookmark == absolutePage,
                          topInset: MediaQuery.paddingOf(context).top,
                          isDark: isDark,
                          accentColor: accent,
                          onTapVerse: null,
                          onLongPressVerse: (_, ayahNum) =>
                              _onVerseLongPressed(absolutePage, ayahNum),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showControlsNotifier,
              builder: (_, showControls, __) {
                if (!showControls) return const SizedBox.shrink();
                return ValueListenableBuilder<int>(
                  valueListenable: _currentPageIndexNotifier,
                  builder: (_, pageIndex, __) {
                    final absolutePageNumber = _kahfStartPage + pageIndex;
                    final arabicPageNum = QuranTextFormatter.toArabicDigits(
                      absolutePageNumber.toString(),
                    );
                    final arabicJuzNum =
                        absolutePageNumber >= 302 ? '١٦' : '١٥';
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: readerTheme.headerBackground,
                            elevation: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: readerTheme.divider,
                                    width: 1,
                                  ),
                                ),
                              ),
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
                                              color: readerTheme.actionIcon,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      AlignmentDirectional
                                                          .centerStart,
                                                  child: Text(
                                                    "سورة الكهف الشريفة",
                                                    maxLines: 1,
                                                    style: GoogleFonts.cairo(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.5,
                                                      color: readerTheme
                                                          .primaryText,
                                                    ),
                                                  ),
                                                ),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      AlignmentDirectional
                                                          .centerStart,
                                                  child: Text(
                                                    "الجزء $arabicJuzNum • الصفحة $arabicPageNum من ٣٠٤",
                                                    maxLines: 1,
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 11,
                                                      color: readerTheme
                                                          .secondaryText,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              (_savedPageBookmark != null ||
                                                      _savedVerseBookmarkPage !=
                                                          null)
                                                  ? Icons.bookmark_rounded
                                                  : Icons.bookmark_add_outlined,
                                              color: (_savedPageBookmark !=
                                                          null ||
                                                      _savedVerseBookmarkPage !=
                                                          null)
                                                  ? readerTheme.activeBookmark
                                                  : readerTheme.actionIcon,
                                            ),
                                            tooltip: "حفظ موضع القراءة",
                                            onPressed: () =>
                                                _showKahfBookmarkOptionsSheet(
                                              context,
                                              isDark,
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              Icons.menu_book_rounded,
                                              color: readerTheme.actionIcon,
                                            ),
                                            tooltip: "فضل سورة الكهف",
                                            onPressed: () => _showVirtueDialog(
                                                context, isDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: readerTheme.chipStripBackground,
                                        border: Border(
                                          top: BorderSide(
                                            color: readerTheme.divider
                                                .withValues(alpha: 0.65),
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6.0),
                                              child: ChoiceChip(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                avatar: Icon(
                                                  Icons.menu_book_rounded,
                                                  size: 14,
                                                  color: _selectedSectionId == 0
                                                      ? Colors.white
                                                      : readerTheme.actionIcon,
                                                ),
                                                label: Text(
                                                  "السورة كاملة (١٢ صفحة)",
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10.5,
                                                    color:
                                                        _selectedSectionId == 0
                                                            ? Colors.white
                                                            : readerTheme
                                                                .primaryText,
                                                  ),
                                                ),
                                                selected:
                                                    _selectedSectionId == 0,
                                                selectedColor: readerTheme
                                                    .chipSelectedBackground,
                                                backgroundColor: readerTheme
                                                    .chipUnselectedBackground,
                                                side: BorderSide(
                                                  color: readerTheme.divider,
                                                  width: 0.8,
                                                ),
                                                onSelected: (_) =>
                                                    _jumpToSection(0),
                                              ),
                                            ),
                                            ...SurahKahfData.sections
                                                .map((sec) {
                                              final isSelected =
                                                  _selectedSectionId == sec.id;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 6.0),
                                                child: ChoiceChip(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  label: Text(
                                                    sec.title,
                                                    style: GoogleFonts.cairo(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10.5,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : readerTheme
                                                              .primaryText,
                                                    ),
                                                  ),
                                                  selected: isSelected,
                                                  selectedColor: readerTheme
                                                      .chipSelectedBackground,
                                                  backgroundColor: readerTheme
                                                      .chipUnselectedBackground,
                                                  side: BorderSide(
                                                    color: readerTheme.divider,
                                                    width: 0.8,
                                                  ),
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
                          const SizedBox(height: 8),
                          MushafPageSideIndicator(
                            pageNumber: absolutePageNumber,
                            isDark: isDark,
                            pageController: _pageController,
                            pageIndexOffset: _kahfStartPage,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showControlsNotifier,
              builder: (_, showControls, child) =>
                  showControls ? child! : const SizedBox.shrink(),
              child: Positioned(
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
            ),
          ],
        ),
      ),
    ),
    );
  }
}
