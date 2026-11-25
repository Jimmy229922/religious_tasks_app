import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/quran/data/qcf_mushaf_repository.dart';
import 'package:religious_tasks_app/features/quran/theme/mushaf_reader_theme.dart';
import 'package:religious_tasks_app/features/quran/widgets/ayah_tafsir_sheet.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_scroll_physics.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_side_indicator.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_mushaf_page_widget.dart';
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
  late int _currentPage;
  late PageController _pageController;
  late List<int> _surahPages;
  late bool _isCompleted;

  bool _showControls = false;
  final ValueNotifier<bool> _showControlsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(1);
  final ValueNotifier<String> _currentSurahNameNotifier =
      ValueNotifier<String>("");
  Timer? _saveLastReadDebounce;
  int? _pendingLastReadPage;
  int? _pendingLastReadSurahNum;
  String? _pendingLastReadSurahName;

  int? _savedPageBookmark;
  String? _savedPageSurahName;
  int? _savedPageSurahNumber;

  int? _savedVerseBookmarkPage;
  String? _savedVerseBookmarkVerse;
  String? _savedVerseBookmarkSurahName;
  int? _savedVerseBookmarkSurahNumber;

  int? _selectedPage;
  int? _selectedSurahNumber;
  int? _selectedAyahNumber;

  String? _inspectingVerse;
  int? _inspectingPage;
  int? _inspectingSurahNumber;

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
      QcfMushafRepository.prefetchAdjacentPages(_currentPage);
    }

    _currentSurahName = widget.surah.name;
    if (!widget.singleSurahOnly) {
      final prefs = StorageService.instance.prefs;
      final range = QuranPageMapping.getPageRange(_currentPage);
      final meta = QuranData.surahs.firstWhere(
        (s) => s.number == range.startSurah,
        orElse: () => widget.surah,
      );
      _currentSurahName = meta.name;
      prefs.setInt('last_read_page_number', _currentPage);
      prefs.setInt('last_read_surah_number', meta.number);
      prefs.setString('last_read_surah_name', meta.name);
    }
    _currentPageNotifier.value = _currentPage;
    _currentSurahNameNotifier.value = _currentSurahName;
    _loadGlobalBookmark();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    _currentPageNotifier.value = _currentPage;
    if (initialIndex > 0 && _pageController.hasClients) {
      _pageController.jumpToPage(initialIndex);
    }
    QcfMushafRepository.prefetchAdjacentPages(
      _currentPage,
      onlySurahNumber: widget.surah.number,
      allowedPages: _surahPages,
    );
  }

  @override
  void dispose() {
    _saveLastReadDebounce?.cancel();
    if (_pendingLastReadPage != null && !widget.singleSurahOnly) {
      final prefs = StorageService.instance.prefs;
      prefs.setInt('last_read_page_number', _pendingLastReadPage!);
      if (_pendingLastReadSurahNum != null) {
        prefs.setInt('last_read_surah_number', _pendingLastReadSurahNum!);
      }
      if (_pendingLastReadSurahName != null) {
        prefs.setString('last_read_surah_name', _pendingLastReadSurahName!);
      }
    }
    _showControlsNotifier.dispose();
    _currentPageNotifier.dispose();
    _currentSurahNameNotifier.dispose();
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

  void _loadGlobalBookmark() {
    final prefs = StorageService.instance.prefs;
    int? pageBm = prefs.getInt('quran_page_bookmark_number');
    String? pageSurahName = prefs.getString('quran_page_bookmark_surah_name');
    int? pageSurahNum = prefs.getInt('quran_page_bookmark_surah_number');

    int? verseBmPage = prefs.getInt('quran_verse_bookmark_page');
    String? verseBmNum = prefs.getString('quran_verse_bookmark_verse');
    String? verseBmSurahName =
        prefs.getString('quran_verse_bookmark_surah_name');
    int? verseBmSurahNum = prefs.getInt('quran_verse_bookmark_surah_number');

    final legacyPage = prefs.getInt('quran_global_bookmark_page');
    final legacyVerse = prefs.getString('quran_global_bookmark_verse');
    final legacySurahName = prefs.getString('quran_global_bookmark_surah_name');
    final legacySurahNum = prefs.getInt('quran_global_bookmark_surah_number');
    final legacyType = prefs.getString('quran_global_bookmark_type') ??
        (legacyVerse != null && legacyVerse.isNotEmpty ? 'verse' : 'page');

    if (pageBm == null && legacyPage != null && legacyType == 'page') {
      pageBm = legacyPage;
      pageSurahName = legacySurahName;
      pageSurahNum = legacySurahNum;
    }
    if (verseBmNum == null && legacyVerse != null && legacyVerse.isNotEmpty) {
      verseBmPage = legacyPage;
      verseBmNum = legacyVerse;
      verseBmSurahName = legacySurahName;
      verseBmSurahNum = legacySurahNum;
    }

    setState(() {
      _savedPageBookmark = pageBm;
      _savedPageSurahName = pageSurahName;
      _savedPageSurahNumber = pageSurahNum;
      _savedVerseBookmarkPage = verseBmPage;
      _savedVerseBookmarkVerse = verseBmNum;
      _savedVerseBookmarkSurahName = verseBmSurahName;
      _savedVerseBookmarkSurahNumber = verseBmSurahNum;
    });
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

  Future<void> _toggleVerseSelection(
    int tappedPage,
    int surahNumber,
    int ayahNumber,
  ) async {
    final verseNum = ayahNumber.toString();
    final isAlreadySelected = (_selectedPage == tappedPage &&
            _selectedSurahNumber == surahNumber &&
            _selectedAyahNumber == ayahNumber) ||
        (_savedVerseBookmarkPage == tappedPage &&
            _savedVerseBookmarkVerse == verseNum);

    if (isAlreadySelected) {
      setState(() {
        _selectedPage = null;
        _selectedSurahNumber = null;
        _selectedAyahNumber = null;
      });
      await _clearVerseBookmark();
      final arabicAyah = QuranTextFormatter.toArabicDigits(verseNum);
      _showStatusToast(
        "تم إلغاء تحديد وحفظ الآية ($arabicAyah)",
        icon: Icons.bookmark_remove_rounded,
      );
    } else {
      setState(() {
        _selectedPage = tappedPage;
        _selectedSurahNumber = surahNumber;
        _selectedAyahNumber = ayahNumber;
      });
      await _saveVerseBookmark(tappedPage, surahNumber, ayahNumber);
    }
  }

  Future<void> _savePageBookmark(int pageNumber) async {
    final cached = QcfMushafRepository.getCachedPage(
      pageNumber,
      onlySurahNumber: _onlySurahFilter,
    );
    final surahNum = cached?.surahNumber ??
        QuranPageMapping.getPageRange(pageNumber).startSurah;
    final surahName = cached?.surahName ??
        QuranData.surahs
            .firstWhere(
              (s) => s.number == surahNum,
              orElse: () => QuranData.surahs.first,
            )
            .name;

    final tasksVm = Provider.of<TasksViewModel>(context, listen: false);
    setState(() {
      _savedPageBookmark = pageNumber;
      _savedPageSurahName = surahName;
      _savedPageSurahNumber = surahNum;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setInt('quran_page_bookmark_number', pageNumber);
    await prefs.setString('quran_page_bookmark_surah_name', surahName);
    await prefs.setInt('quran_page_bookmark_surah_number', surahNum);

    await prefs.remove('quran_global_bookmark_verse');
    await prefs.remove('quran_global_bookmark_snippet');
    await prefs.remove('quran_global_bookmark_full_text');
    await prefs.setInt('quran_global_bookmark_page', pageNumber);
    await prefs.setString('quran_global_bookmark_surah_name', surahName);
    await prefs.setInt('quran_global_bookmark_surah_number', surahNum);
    await prefs.setString('quran_global_bookmark_type', 'page');

    await tasksVm.updateQuranProgress(
      surahName,
      1,
      surahNumber: surahNum,
      page: pageNumber,
      verseText: '',
      hasBookmark: true,
    );

    _showStatusToast(
      "تم حفظ الصفحة الحالية: ص (${QuranTextFormatter.toArabicDigits(pageNumber.toString())}) • سورة $surahName",
    );
  }

  Future<void> _saveVerseBookmark(
    int tappedPage,
    int surahNumber,
    int ayahNumber,
  ) async {
    final verseNum = ayahNumber.toString();
    final surahName = QuranData.surahs
        .firstWhere(
          (s) => s.number == surahNumber,
          orElse: () => QuranData.surahs.first,
        )
        .name;

    final arabicNum = QuranTextFormatter.toArabicDigits(verseNum);
    final fullVerseText =
        await QuranRepository.getVerseText(surahNumber, ayahNumber) ?? '';
    final words = fullVerseText.split(RegExp(r'\s+'));
    final snippet = words.length <= 7
        ? fullVerseText
        : '${words.take(7).join(' ')} ...';

    if (!mounted) return;
    final tasksVm = Provider.of<TasksViewModel>(context, listen: false);

    setState(() {
      _savedVerseBookmarkVerse = verseNum;
      _savedVerseBookmarkPage = tappedPage;
      _savedVerseBookmarkSurahName = surahName;
      _savedVerseBookmarkSurahNumber = surahNumber;
      _currentSurahName = surahName;
    });

    final prefs = StorageService.instance.prefs;
    await prefs.setInt('quran_verse_bookmark_page', tappedPage);
    await prefs.setString('quran_verse_bookmark_verse', verseNum);
    await prefs.setString('quran_verse_bookmark_surah_name', surahName);
    await prefs.setInt('quran_verse_bookmark_surah_number', surahNumber);

    await prefs.setString('quran_global_bookmark_verse', verseNum);
    await prefs.setInt('quran_global_bookmark_page', tappedPage);
    await prefs.setString('quran_global_bookmark_surah_name', surahName);
    await prefs.setInt('quran_global_bookmark_surah_number', surahNumber);
    await prefs.setString('quran_global_bookmark_snippet', snippet);
    await prefs.setString('quran_global_bookmark_full_text', fullVerseText);
    await prefs.setString('quran_global_bookmark_type', 'verse');

    await tasksVm.updateQuranProgress(
      surahName,
      ayahNumber,
      surahNumber: surahNumber,
      page: tappedPage,
      verseText: fullVerseText,
      hasBookmark: true,
    );

    _showStatusToast(
      "تم حفظ الآية المحددة: سورة $surahName • ص (${QuranTextFormatter.toArabicDigits(tappedPage.toString())}) • آية ($arabicNum)",
    );
  }

  Future<void> _clearPageBookmark() async {
    final tasksVm = Provider.of<TasksViewModel>(context, listen: false);
    setState(() {
      _savedPageBookmark = null;
      _savedPageSurahName = null;
      _savedPageSurahNumber = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('quran_page_bookmark_number');
    await prefs.remove('quran_page_bookmark_surah_name');
    await prefs.remove('quran_page_bookmark_surah_number');
    if (_savedVerseBookmarkPage != null && _savedVerseBookmarkVerse != null) {
      await prefs.setInt('quran_global_bookmark_page', _savedVerseBookmarkPage!);
      await prefs.setString('quran_global_bookmark_verse', _savedVerseBookmarkVerse!);
      if (_savedVerseBookmarkSurahName != null) {
        await prefs.setString('quran_global_bookmark_surah_name', _savedVerseBookmarkSurahName!);
      }
      if (_savedVerseBookmarkSurahNumber != null) {
        await prefs.setInt('quran_global_bookmark_surah_number', _savedVerseBookmarkSurahNumber!);
      }
      await prefs.setString('quran_global_bookmark_type', 'verse');
    } else {
      await _clearLegacyGlobalBookmark(prefs, tasksVm);
    }
  }

  Future<void> _clearVerseBookmark() async {
    final tasksVm = Provider.of<TasksViewModel>(context, listen: false);
    setState(() {
      _savedVerseBookmarkPage = null;
      _savedVerseBookmarkVerse = null;
      _savedVerseBookmarkSurahName = null;
      _savedVerseBookmarkSurahNumber = null;
    });
    final prefs = StorageService.instance.prefs;
    await prefs.remove('quran_verse_bookmark_page');
    await prefs.remove('quran_verse_bookmark_verse');
    await prefs.remove('quran_verse_bookmark_surah_name');
    await prefs.remove('quran_verse_bookmark_surah_number');
    if (_savedPageBookmark != null) {
      await prefs.remove('quran_global_bookmark_verse');
      await prefs.remove('quran_global_bookmark_snippet');
      await prefs.remove('quran_global_bookmark_full_text');
      await prefs.setInt('quran_global_bookmark_page', _savedPageBookmark!);
      if (_savedPageSurahName != null) {
        await prefs.setString('quran_global_bookmark_surah_name', _savedPageSurahName!);
      }
      if (_savedPageSurahNumber != null) {
        await prefs.setInt('quran_global_bookmark_surah_number', _savedPageSurahNumber!);
      }
      await prefs.setString('quran_global_bookmark_type', 'page');
    } else {
      await _clearLegacyGlobalBookmark(prefs, tasksVm);
    }
  }

  Future<void> _clearLegacyGlobalBookmark(
    dynamic prefs,
    TasksViewModel tasksVm,
  ) async {
    await prefs.remove('quran_global_bookmark_verse');
    await prefs.remove('quran_global_bookmark_page');
    await prefs.remove('quran_global_bookmark_surah_name');
    await prefs.remove('quran_global_bookmark_surah_number');
    await prefs.remove('quran_global_bookmark_snippet');
    await prefs.remove('quran_global_bookmark_full_text');
    await prefs.remove('quran_global_bookmark_type');
    await tasksVm.clearQuranBookmark();
  }

  void _showBookmarkOptionsSheet(BuildContext context, bool isDark) {
    final hasSelectedVerse = _selectedPage == _currentPage &&
        _selectedSurahNumber != null &&
        _selectedAyahNumber != null;

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
                  "حفظ موضع القراءة",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.bookmark_add_rounded, color: Colors.amber),
                  title: Text(
                    "حفظ الصفحة الحالية",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "صفحة ${QuranTextFormatter.toArabicDigits(_currentPage.toString())}",
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _savePageBookmark(_currentPage);
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
                      _saveVerseBookmark(
                        _selectedPage!,
                        _selectedSurahNumber!,
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
                      leading: const Icon(Icons.menu_book_rounded, color: Colors.teal),
                      title: Text(
                        "الانتقال للصفحة المحفوظة",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "صفحة ${QuranTextFormatter.toArabicDigits(_savedPageBookmark.toString())} • سورة ${_savedPageSurahName ?? ''}",
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearPageBookmark();
                        },
                      ),
                      onTap: () {
                        final target = _savedPageBookmark!;
                        Navigator.pop(ctx);
                        _jumpToPage(target);
                      },
                    ),
                  if (_savedVerseBookmarkPage != null &&
                      _savedVerseBookmarkVerse != null)
                    ListTile(
                      leading: const Icon(Icons.my_location_rounded, color: Colors.amber),
                      title: Text(
                        "الانتقال للآية المحفوظة",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "سورة ${_savedVerseBookmarkSurahName ?? ''} • ص ${QuranTextFormatter.toArabicDigits(_savedVerseBookmarkPage.toString())} • آية ${QuranTextFormatter.toArabicDigits(_savedVerseBookmarkVerse!)}",
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearVerseBookmark();
                        },
                      ),
                      onTap: () {
                        final target = _savedVerseBookmarkPage!;
                        Navigator.pop(ctx);
                        _jumpToPage(target);
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

  Future<void> _onVerseLongPressed(
    int tappedPage,
    int surahNumber,
    int ayahNumber,
  ) async {
    HapticFeedback.mediumImpact();
    final verseNum = ayahNumber.toString();
    final surahName = QuranData.surahs
        .firstWhere(
          (s) => s.number == surahNumber,
          orElse: () => QuranData.surahs.first,
        )
        .name;
    final arabicAyah = QuranTextFormatter.toArabicDigits(verseNum);
    final isAlreadySelected = (_selectedPage == tappedPage &&
            _selectedSurahNumber == surahNumber &&
            _selectedAyahNumber == ayahNumber) ||
        (_savedVerseBookmarkPage == tappedPage &&
            _savedVerseBookmarkVerse == verseNum);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    setState(() {
      _inspectingVerse = verseNum;
      _inspectingPage = tappedPage;
      _inspectingSurahNumber = surahNumber;
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
                  "سورة $surahName • آية $arabicAyah",
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
        _inspectingSurahNumber = null;
      });
      _toggleVerseSelection(tappedPage, surahNumber, ayahNumber);
      return;
    }

    if (action == 'tafsir') {
      final fullVerseText =
          await QuranRepository.getVerseText(surahNumber, ayahNumber) ?? '';
      if (!mounted) return;
      await showAyahTafsirSheet(
        context: context,
        surahNumber: surahNumber,
        surahName: surahName,
        ayahNumber: ayahNumber,
        ayahText: fullVerseText,
      );
    }

    if (!mounted) return;
    setState(() {
      _inspectingVerse = null;
      _inspectingPage = null;
      _inspectingSurahNumber = null;
    });
  }

  void _jumpToPage(int page) {
    final targetPage = page.clamp(1, 604);
    if (widget.singleSurahOnly) {
      final idx = _surahPages.indexOf(targetPage);
      if (idx == -1) return;
      final currentIdx = _surahPages.indexOf(_currentPage);
      if (currentIdx != -1 && (idx - currentIdx).abs() > 3) {
        _pageController.jumpToPage(idx);
      } else {
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      if ((targetPage - _currentPage).abs() > 3) {
        _pageController.jumpToPage(targetPage - 1);
      } else {
        _pageController.animateToPage(
          targetPage - 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _showJumpToPageDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentPage.toString());
    String? errorText;

    void submit(BuildContext ctx, StateSetter setDialogState) {
      final normalized =
          QuranTextFormatter.toEnglishDigits(controller.text.trim());
      final p = int.tryParse(normalized);
      if (p != null && p >= 1 && p <= 604) {
        Navigator.pop(ctx);
        _jumpToPage(p);
      } else {
        setDialogState(() {
          errorText = "أدخل رقماً صحيحاً بين ١ و ٦٠٤";
        });
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              "الانتقال إلى صفحة 📖",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
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
                    textInputAction: TextInputAction.go,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => submit(ctx, setDialogState),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: "مثال: 293",
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                ),
                onPressed: () => submit(ctx, setDialogState),
                child: const Text(
                  "انتقال 🎯",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
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
        resizeToAvoidBottomInset: false,
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
                  itemCount: widget.singleSurahOnly ? _surahPages.length : 604,
                  onPageChanged: (pageIndex) {
                    final newPage = widget.singleSurahOnly
                        ? _surahPages[pageIndex]
                        : pageIndex + 1;
                    final cached = QcfMushafRepository.getCachedPage(
                      newPage,
                      onlySurahNumber: _onlySurahFilter,
                    );
                    final range = QuranPageMapping.getPageRange(newPage);
                    final meta = QuranData.surahs.firstWhere(
                      (s) => s.number == range.startSurah,
                      orElse: () => QuranData.surahs.first,
                    );
                    final nextSurahName = widget.singleSurahOnly
                        ? widget.surah.name
                        : (cached?.surahName ?? meta.name);
                    _currentPage = newPage;
                    _currentSurahName = nextSurahName;
                    _currentPageNotifier.value = newPage;
                    _currentSurahNameNotifier.value = nextSurahName;
                    if (!widget.singleSurahOnly) {
                      _pendingLastReadPage = newPage;
                      _pendingLastReadSurahNum = meta.number;
                      _pendingLastReadSurahName = nextSurahName;
                      _saveLastReadDebounce?.cancel();
                      _saveLastReadDebounce =
                          Timer(const Duration(milliseconds: 500), () {
                        final prefs = StorageService.instance.prefs;
                        prefs.setInt('last_read_page_number', newPage);
                        prefs.setInt('last_read_surah_number', meta.number);
                        prefs.setString('last_read_surah_name', nextSurahName);
                        _pendingLastReadPage = null;
                      });
                    }
                    QcfMushafRepository.prefetchAdjacentPages(
                      newPage,
                      onlySurahNumber: _onlySurahFilter,
                      allowedPages:
                          widget.singleSurahOnly ? _surahPages : null,
                    );
                    if (cached == null) {
                      QcfMushafRepository.loadPage(
                        newPage,
                        onlySurahNumber: _onlySurahFilter,
                      ).then((content) {
                        if (mounted &&
                            _currentPage == newPage &&
                            !widget.singleSurahOnly &&
                            _currentSurahName != content.surahName) {
                          _currentSurahName = content.surahName;
                          _currentSurahNameNotifier.value = content.surahName;
                          _pendingLastReadSurahName = content.surahName;
                        }
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final pageNumber = widget.singleSurahOnly
                        ? _surahPages[index]
                        : index + 1;
                    final cachedPage = QcfMushafRepository.getCachedPage(
                      pageNumber,
                      onlySurahNumber: _onlySurahFilter,
                    );

                    return FutureBuilder<QcfMushafPageData>(
                      initialData: cachedPage,
                      future: cachedPage != null
                          ? null
                          : QcfMushafRepository.loadPage(
                              pageNumber,
                              onlySurahNumber: _onlySurahFilter,
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

                        final pageData = snapshot.data!;
                        String? highlightedKey;
                        if (_inspectingPage == pageNumber &&
                            _inspectingSurahNumber != null &&
                            _inspectingVerse != null) {
                          highlightedKey =
                              '$_inspectingSurahNumber:$_inspectingVerse';
                        } else if (_selectedPage == pageNumber &&
                            _selectedSurahNumber != null &&
                            _selectedAyahNumber != null) {
                          highlightedKey =
                              '$_selectedSurahNumber:$_selectedAyahNumber';
                        } else if (_savedVerseBookmarkPage == pageNumber &&
                            _savedVerseBookmarkVerse != null) {
                          final surahNum = _savedVerseBookmarkSurahNumber ??
                              pageData.surahNumber;
                          final ayahInt = QuranTextFormatter.parseVerseNumber(
                            _savedVerseBookmarkVerse!,
                          );
                          if (ayahInt != null) {
                            highlightedKey = '$surahNum:$ayahInt';
                          }
                        }

                        return QcfMushafPageWidget(
                          pageData: pageData,
                          highlightedVerseKey: highlightedKey,
                          isPageBookmarked: _savedPageBookmark == pageNumber,
                          topInset: MediaQuery.paddingOf(context).top,
                          isDark: isDark,
                          accentColor: accent,
                          onTapVerse: null,
                          onLongPressVerse: (sNum, aNum) =>
                              _onVerseLongPressed(pageNumber, sNum, aNum),
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
                  valueListenable: _currentPageNotifier,
                  builder: (_, currentPage, __) {
                    final currentJuz =
                        QuranPageMapping.getJuzForPage(currentPage);
                    final arabicPageNum = QuranTextFormatter.toArabicDigits(
                      currentPage.toString(),
                    );
                    final arabicJuzNum = QuranTextFormatter.toArabicDigits(
                      currentJuz.toString(),
                    );
                    final singleSurahIdx = _surahPages.indexOf(currentPage);
                    final subtitleText = widget.singleSurahOnly
                        ? "الجزء $arabicJuzNum • صفحة $arabicPageNum (${QuranTextFormatter.toArabicDigits(((singleSurahIdx == -1 ? 0 : singleSurahIdx) + 1).toString())} من ${QuranTextFormatter.toArabicDigits(_surahPages.length.toString())})"
                        : "الجزء $arabicJuzNum • الصفحة $arabicPageNum من ٦٠٤";
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
                                child: SizedBox(
                                  height: kToolbarHeight,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: readerTheme.actionIcon,
                                          size: 20,
                                        ),
                                        onPressed: () => Navigator.pop(context),
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
                                              alignment: AlignmentDirectional
                                                  .centerStart,
                                              child: ValueListenableBuilder<
                                                  String>(
                                                valueListenable:
                                                    _currentSurahNameNotifier,
                                                builder: (_, surahName, __) =>
                                                    Text(
                                                  "سورة ${surahName.isNotEmpty ? surahName : widget.surah.name}",
                                                  maxLines: 1,
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15.5,
                                                    color:
                                                        readerTheme.primaryText,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: AlignmentDirectional
                                                  .centerStart,
                                              child: Text(
                                                subtitleText,
                                                maxLines: 1,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color:
                                                      readerTheme.secondaryText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          (_savedPageBookmark != null ||
                                                  _savedVerseBookmarkPage !=
                                                      null)
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_add_outlined,
                                          color: (_savedPageBookmark != null ||
                                                  _savedVerseBookmarkPage !=
                                                      null)
                                              ? readerTheme.activeBookmark
                                              : readerTheme.actionIcon,
                                        ),
                                        tooltip: "حفظ موضع القراءة",
                                        onPressed: () =>
                                            _showBookmarkOptionsSheet(
                                                context, isDark),
                                      ),
                                      if (!widget.singleSurahOnly)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            Icons.menu_book_rounded,
                                            color: readerTheme.actionIcon,
                                          ),
                                          tooltip: "الانتقال لصفحة",
                                          onPressed: () =>
                                              _showJumpToPageDialog(context),
                                        ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          Icons.style_rounded,
                                          color: readerTheme.actionIcon,
                                        ),
                                        tooltip: "صانع البطاقات الإيمانية",
                                        onPressed: () async {
                                          final fullText = await QuranRepository
                                              .getSurahFullText(
                                            widget.surah.number,
                                          );
                                          if (!context.mounted) return;
                                          showDialog(
                                            context: context,
                                            builder: (_) =>
                                                IslamicCardGeneratorDialog(
                                              title: "سورة ${widget.surah.name}",
                                              content: fullText,
                                              subtitle:
                                                  "${widget.surah.type} • ${widget.surah.ayahCount} آية",
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          MushafPageSideIndicator(
                            pageNumber: currentPage,
                            isDark: isDark,
                            pageController: widget.singleSurahOnly
                                ? null
                                : _pageController,
                            pageIndexOffset: 1,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            if (widget.singleSurahOnly && widget.onMarkCompleted != null)
              ValueListenableBuilder<bool>(
                valueListenable: _showControlsNotifier,
                builder: (_, showControls, child) =>
                    showControls ? child! : const SizedBox.shrink(),
                child: Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
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
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
