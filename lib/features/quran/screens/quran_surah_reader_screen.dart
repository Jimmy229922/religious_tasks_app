import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class QuranSurahReaderScreen extends StatefulWidget {
  final SurahInfo surah;
  final int? initialPage;
  final bool singleSurahOnly;
  final bool isCompleted;
  final VoidCallback? onMarkCompleted;

  const QuranSurahReaderScreen({
    super.key,
    required this.surah,
    this.initialPage,
    this.singleSurahOnly = false,
    this.isCompleted = false,
    this.onMarkCompleted,
  });

  @override
  State<QuranSurahReaderScreen> createState() => _QuranSurahReaderScreenState();
}

class _QuranSurahReaderScreenState extends State<QuranSurahReaderScreen> {
  double _fontSize = 18.0;
  late int _currentPage;
  late PageController _pageController;
  late List<int> _surahPages;
  late bool _isCompleted;

  String? _savedBookmarkedVerse;
  int? _savedBookmarkedPage;
  String? _savedBookmarkedSurahName;
  int? _savedBookmarkedSurahNumber;
  String? _savedBookmarkedSnippet;

  final Map<int, ScrollController> _pageScrollControllers = {};
  String _currentSurahName = "";

  int? get _onlySurahFilter =>
      widget.singleSurahOnly ? widget.surah.number : null;

  @override
  void initState() {
    super.initState();
    final prefs = StorageService.instance.prefs;
    final savedPage = prefs.getInt('quran_global_bookmark_page');
    final savedSurahNum = prefs.getInt('quran_global_bookmark_surah_number');
    _isCompleted = widget.isCompleted;

    if (widget.singleSurahOnly) {
      _currentPage = (widget.initialPage ??
              QuranPageMapping.surahStartPage[widget.surah.number] ??
              1)
          .clamp(1, 604);
      _surahPages = [_currentPage];
      _pageController = PageController(initialPage: 0);
      _loadSingleSurahPages();
    } else {
      if (widget.initialPage != null) {
        _currentPage = widget.initialPage!.clamp(1, 604);
      } else if (savedPage != null && savedSurahNum == widget.surah.number) {
        _currentPage = savedPage.clamp(1, 604);
      } else {
        _currentPage =
            QuranPageMapping.surahStartPage[widget.surah.number] ?? 1;
      }
      _surahPages = const [];
      _pageController = PageController(initialPage: _currentPage - 1);
      QuranRepository.prefetchAdjacentPages(_currentPage);
    }

    _currentSurahName = widget.surah.name;
    _loadGlobalBookmark();
    if (_savedBookmarkedPage == _currentPage && _savedBookmarkedVerse != null) {
      _scrollToBookmarkedVerse(_currentPage);
    }
  }

  Future<void> _loadSingleSurahPages() async {
    final pages = await QuranRepository.getSurahPages(widget.surah.number);
    if (!mounted || pages.isEmpty) return;
    final initialIndex = pages.indexOf(_currentPage);
    setState(() {
      _surahPages = pages;
      if (initialIndex == -1) {
        _currentPage = pages.first;
      }
    });
    if (initialIndex > 0 && _pageController.hasClients) {
      _pageController.jumpToPage(initialIndex);
    }
    QuranRepository.prefetchAdjacentPages(
      _currentPage,
      onlySurahNumber: widget.surah.number,
      allowedPages: _surahPages,
    );
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

  ScrollController _getPageScrollController(int pageNumber) {
    return _pageScrollControllers.putIfAbsent(
      pageNumber,
      () => ScrollController(),
    );
  }

  void _scrollToBookmarkedVerse(int pageNumber) {
    if (_savedBookmarkedPage != pageNumber || _savedBookmarkedVerse == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      final controller = _pageScrollControllers[pageNumber];
      if (controller == null || !controller.hasClients) return;
      final maxExtent = controller.position.maxScrollExtent;
      if (maxExtent <= 0) return;

      final content = await QuranRepository.getPageContent(
        pageNumber,
        onlySurahNumber: _onlySurahFilter,
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

  void _loadGlobalBookmark() {
    final prefs = StorageService.instance.prefs;
    final savedPage = prefs.getInt('quran_global_bookmark_page');
    final savedVerse = prefs.getString('quran_global_bookmark_verse');
    final savedSurahName = prefs.getString('quran_global_bookmark_surah_name');
    final savedSurahNum = prefs.getInt('quran_global_bookmark_surah_number');
    final savedSnippet = prefs.getString('quran_global_bookmark_snippet');

    if (savedPage != null || savedVerse != null) {
      setState(() {
        _savedBookmarkedPage = savedPage;
        _savedBookmarkedVerse = savedVerse;
        _savedBookmarkedSurahName = savedSurahName;
        _savedBookmarkedSurahNumber = savedSurahNum;
        _savedBookmarkedSnippet = savedSnippet;
      });
    }

    // Save current surah as last opened for index highlight
    prefs.setInt('last_read_surah_number', widget.surah.number);
    prefs.setString('last_read_surah_name', widget.surah.name);
  }

  void _showStatusToast(String message, {IconData icon = Icons.bookmark_added_rounded}) {
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

  Future<void> _onVerseTapped(
    int surahNumber,
    String surahName,
    String verseNum,
    String sectionText,
  ) async {
    final isSameBookmark = _savedBookmarkedPage == _currentPage &&
        _savedBookmarkedSurahNumber == surahNumber &&
        _savedBookmarkedVerse == verseNum;

    if (isSameBookmark) {
      _clearGlobalBookmark();
      _showStatusToast(
        "تم إلغاء تحديد الآية (${QuranTextFormatter.toArabicDigits(verseNum)})",
        icon: Icons.bookmark_remove_rounded,
      );
      return;
    }

    final arabicNum = QuranTextFormatter.toArabicDigits(verseNum);
    final ayahInt = QuranTextFormatter.parseVerseNumber(verseNum) ?? 1;
    final snippet = QuranTextFormatter.extractVerseSnippet(
      sectionText,
      verseNum,
    );
    var fullVerseText = QuranTextFormatter.extractFullVerseText(
      sectionText,
      verseNum,
    );
    if (fullVerseText.isEmpty) {
      fullVerseText =
          await QuranRepository.getVerseText(surahNumber, ayahInt) ?? snippet;
    }

    if (!mounted) return;
    final tasksVm = Provider.of<TasksViewModel>(context, listen: false);

    setState(() {
      _savedBookmarkedVerse = verseNum;
      _savedBookmarkedPage = _currentPage;
      _savedBookmarkedSurahName = surahName;
      _savedBookmarkedSurahNumber = surahNumber;
      _savedBookmarkedSnippet = snippet;
      _currentSurahName = surahName;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setString('quran_global_bookmark_verse', verseNum);
    await prefs.setInt('quran_global_bookmark_page', _currentPage);
    await prefs.setString('quran_global_bookmark_surah_name', surahName);
    await prefs.setInt('quran_global_bookmark_surah_number', surahNumber);
    await prefs.setString('quran_global_bookmark_snippet', snippet);
    await prefs.setString('quran_global_bookmark_full_text', fullVerseText);

    // Also sync last read surah for index
    await prefs.setInt('last_read_surah_number', surahNumber);
    await prefs.setString('last_read_surah_name', surahName);

    // Sync directly with Khatmah Tracker (TasksViewModel)
    await tasksVm.updateQuranProgress(
      surahName,
      ayahInt,
      surahNumber: surahNumber,
      page: _currentPage,
      verseText: fullVerseText,
      hasBookmark: true,
    );

    _showStatusToast(
      "تم حفظ الموقف وتحديث الختمة: سورة $surahName • ص (${QuranTextFormatter.toArabicDigits(_currentPage.toString())}) • آية ($arabicNum)",
    );
  }

  void _clearGlobalBookmark() async {
    final tasksVm = Provider.of<TasksViewModel>(context, listen: false);
    setState(() {
      _savedBookmarkedVerse = null;
      _savedBookmarkedPage = null;
      _savedBookmarkedSurahName = null;
      _savedBookmarkedSurahNumber = null;
      _savedBookmarkedSnippet = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('quran_global_bookmark_verse');
    await prefs.remove('quran_global_bookmark_page');
    await prefs.remove('quran_global_bookmark_surah_name');
    await prefs.remove('quran_global_bookmark_surah_number');
    await prefs.remove('quran_global_bookmark_snippet');
    await prefs.remove('quran_global_bookmark_full_text');
    await prefs.remove('last_read_surah_number');
    await prefs.remove('last_read_surah_name');
    await tasksVm.clearQuranBookmark();
  }

  void _jumpToPage(int page, {bool scrollToBookmark = false}) {
    final targetPage = page.clamp(1, 604);
    if (widget.singleSurahOnly) {
      final idx = _surahPages.indexOf(targetPage);
      if (idx == -1) return;
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _pageController.animateToPage(
        targetPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
    if (scrollToBookmark) {
      _scrollToBookmarkedVerse(targetPage);
    }
  }

  void _showJumpToPageDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            "الانتقال إلى صفحة 📖",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "أدخل رقم الصفحة (من 1 إلى 604):",
                style: GoogleFonts.cairo(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "مثال: 293",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              onPressed: () {
                final p = int.tryParse(controller.text.trim());
                if (p != null && p >= 1 && p <= 604) {
                  Navigator.pop(ctx);
                  _jumpToPage(p);
                }
              },
              child: const Text("انتقال 🎯", style: TextStyle(color: Colors.white)),
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
    final surahName = _savedBookmarkedSurahName ?? _currentSurahName;

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
                "موقف القراءة الحالي",
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
                "سورة $surahName",
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
                _clearGlobalBookmark();
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
                backgroundColor: const Color(0xFF0F766E),
              ),
              onPressed: () {
                final targetPage = _savedBookmarkedPage!;
                Navigator.pop(ctx);
                _jumpToPage(targetPage, scrollToBookmark: true);
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
    final solidBgColor = isDark ? const Color(0xFF0B131E) : const Color(0xFFF0FDF4);
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF0FDF4)];

    const accent = Color(0xFF0F766E);
    final currentJuz = QuranPageMapping.getJuzForPage(_currentPage);
    final arabicPageNum = QuranTextFormatter.toArabicDigits(_currentPage.toString());
    final arabicJuzNum = QuranTextFormatter.toArabicDigits(currentJuz.toString());
    final singleSurahIdx = _surahPages.indexOf(_currentPage);
    final subtitleText = widget.singleSurahOnly
        ? "الجزء $arabicJuzNum • صفحة $arabicPageNum (${QuranTextFormatter.toArabicDigits(((singleSurahIdx == -1 ? 0 : singleSurahIdx) + 1).toString())} من ${QuranTextFormatter.toArabicDigits(_surahPages.length.toString())})"
        : "الجزء $arabicJuzNum • الصفحة $arabicPageNum من ٦٠٤";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: solidBgColor,
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
                  "سورة ${_currentSurahName.isNotEmpty ? _currentSurahName : widget.surah.name}",
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
                  subtitleText,
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
          backgroundColor: isDark ? const Color(0xFF0B131E) : const Color(0xFF0F766E),
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
            if (!widget.singleSurahOnly)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.menu_book_rounded),
                tooltip: "الانتقال لصفحة",
                onPressed: () => _showJumpToPageDialog(context),
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
            IconButton(
              visualDensity: VisualDensity.compact,
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
              // Fullscreen 604 Madani Mushaf Page Viewer (PageView)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.singleSurahOnly ? _surahPages.length : 604,
                  onPageChanged: (pageIndex) {
                    final newPage = widget.singleSurahOnly
                        ? _surahPages[pageIndex]
                        : pageIndex + 1;
                    final cached = QuranRepository.getCachedPageContent(
                      newPage,
                      onlySurahNumber: _onlySurahFilter,
                    );
                    final range = QuranPageMapping.getPageRange(newPage);
                    final meta = QuranData.surahs.firstWhere(
                      (s) => s.number == range.startSurah,
                      orElse: () => QuranData.surahs.first,
                    );
                    setState(() {
                      _currentPage = newPage;
                      _currentSurahName = widget.singleSurahOnly
                          ? widget.surah.name
                          : (cached?.surahName ?? meta.name);
                    });
                    QuranRepository.prefetchAdjacentPages(
                      newPage,
                      onlySurahNumber: _onlySurahFilter,
                      allowedPages:
                          widget.singleSurahOnly ? _surahPages : null,
                    );
                    if (cached == null) {
                      QuranRepository.getPageContent(
                        newPage,
                        onlySurahNumber: _onlySurahFilter,
                      ).then((content) {
                        if (mounted &&
                            _currentPage == newPage &&
                            !widget.singleSurahOnly &&
                            _currentSurahName != content.surahName) {
                          setState(() {
                            _currentSurahName = content.surahName;
                          });
                        }
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final pageNumber = widget.singleSurahOnly
                        ? _surahPages[index]
                        : index + 1;
                    final cachedPage = QuranRepository.getCachedPageContent(
                      pageNumber,
                      onlySurahNumber: _onlySurahFilter,
                    );

                    return FutureBuilder<MushafPageContent>(
                      initialData: cachedPage,
                      future: cachedPage != null
                          ? null
                          : QuranRepository.getPageContent(
                              pageNumber,
                              onlySurahNumber: _onlySurahFilter,
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
                                  "جاري فتح الصفحة ${QuranTextFormatter.toArabicDigits(pageNumber.toString())} من المصحف...",
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
                        final pageJuz = pageData?.juz ??
                            QuranPageMapping.getJuzForPage(pageNumber);
                        final itemArabicPageNum = QuranTextFormatter.toArabicDigits(
                          pageNumber.toString(),
                        );
                        final sections = (pageData != null &&
                                pageData.sections.isNotEmpty)
                            ? pageData.sections
                            : [
                                MushafPageSection(
                                  surahNumber:
                                      pageData?.surahNumber ?? widget.surah.number,
                                  surahName:
                                      pageData?.surahName ?? _currentSurahName,
                                  verseStart: 1,
                                  verseEnd: 999,
                                  text: pageText,
                                ),
                              ];

                        return RepaintBoundary(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(8, 4, 8, 6),
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
                                        "سورة ${pageData?.surahName ?? _currentSurahName}",
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.tealAccent : accent,
                                        ),
                                      ),
                                      Text(
                                        "الجزء ${QuranTextFormatter.toArabicDigits(pageJuz.toString())}",
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(height: 8, color: accent.withValues(alpha: 0.2)),

                                  // Center Page Content (Authentic Mushaf Page Body)
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        double headerOverhead = 0.0;
                                        for (int i = 0; i < sections.length; i++) {
                                          if (sections[i].startsSurah) {
                                            headerOverhead += 38.0;
                                          }
                                          if (sections[i].showBismillah) {
                                            headerOverhead += 34.0;
                                          }
                                          if (i > 0) headerOverhead += 10.0;
                                        }

                                        final cachePrefix = widget.singleSurahOnly
                                            ? 'surah_${widget.surah.number}'
                                            : 'mushaf';
                                        final typography =
                                            QuranTextFormatter.computeMushafTypography(
                                          cacheKey: '${cachePrefix}_$pageNumber',
                                          sectionTexts: sections
                                              .map((s) => s.text)
                                              .toList(),
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
                                            pageNumber,
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
                                                for (int i = 0;
                                                    i < sections.length;
                                                    i++) ...[
                                                  if (i > 0)
                                                    const SizedBox(height: 10),
                                                  if (sections[i].startsSurah)
                                                    MushafSurahHeaderBanner(
                                                      surahName:
                                                          sections[i].surahName,
                                                      fontSize: (typography
                                                                  .fontSize *
                                                              0.9)
                                                          .clamp(16.0, 21.0),
                                                      accentColor: accent,
                                                      isDark: isDark,
                                                    ),
                                                  if (sections[i].showBismillah)
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
                                                              .clamp(16.0, 22.0),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? Colors.tealAccent
                                                              : accent,
                                                        ),
                                                      ),
                                                    ),
                                                  QuranTextFormatter
                                                      .buildFormattedQuranText(
                                                    sections[i].text,
                                                    textAlign: QuranTextFormatter
                                                            .shouldJustifyText(
                                                      sections[i].text,
                                                      pageNumber: pageNumber,
                                                    )
                                                        ? TextAlign.justify
                                                        : TextAlign.center,
                                                    baseStyle: GoogleFonts.amiri(
                                                      fontSize:
                                                          typography.fontSize,
                                                      height:
                                                          typography.lineHeight,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                    bookmarkedVerse: (_savedBookmarkedPage ==
                                                                pageNumber &&
                                                            (_savedBookmarkedSurahNumber ==
                                                                    null ||
                                                                _savedBookmarkedSurahNumber ==
                                                                    sections[i]
                                                                        .surahNumber))
                                                        ? _savedBookmarkedVerse
                                                        : null,
                                                    onTapVerse: (vNum) =>
                                                        _onVerseTapped(
                                                      sections[i].surahNumber,
                                                      sections[i].surahName,
                                                      vNum,
                                                      sections[i].text,
                                                    ),
                                                  ),
                                                ],
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
              if (widget.singleSurahOnly && widget.onMarkCompleted != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white12
                            : accent.withValues(alpha: 0.2),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (!_isCompleted) {
                            widget.onMarkCompleted?.call();
                            setState(() {
                              _isCompleted = true;
                            });
                          }
                          Navigator.pop(context, true);
                        },
                        icon: Icon(
                          _isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.task_alt_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _isCompleted
                              ? "تمت قراءة سورة ${widget.surah.name} بحمد الله ✓"
                              : "أتممت قراءة سورة ${widget.surah.name} ✓",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted
                              ? const Color(0xFF10B981)
                              : accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
