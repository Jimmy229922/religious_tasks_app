import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/qcf_mushaf_repository.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_scroll_physics.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_section_start_toast.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_mushaf_page_widget.dart';

class MushafPagedReader extends StatefulWidget {
  final PageController controller;
  final List<int>? pages;
  final int? onlySurahNumber;
  final bool isDark;
  final Color accentColor;
  final String loadingSourceName;
  final int? bookmarkedPage;
  final VoidCallback onToggleControls;
  final void Function(
    int pageIndex,
    int pageNumber,
    QcfMushafPageData? cachedPage,
  ) onPageChanged;
  final String? Function(int pageNumber, QcfMushafPageData pageData)
      highlightedVerseKeyBuilder;
  final void Function(int pageNumber, int surahNumber, int ayahNumber)?
      onTapVerse;
  final void Function(int pageNumber, int surahNumber, int ayahNumber)?
      onLongPressVerse;
  final ValueNotifier<int> toastPageNotifier;
  final int toastPageIndexOffset;
  final String? Function(int page)? toastExtraTitleForPage;

  const MushafPagedReader({
    super.key,
    required this.controller,
    this.pages,
    this.onlySurahNumber,
    required this.isDark,
    required this.accentColor,
    required this.loadingSourceName,
    required this.bookmarkedPage,
    required this.onToggleControls,
    required this.onPageChanged,
    required this.highlightedVerseKeyBuilder,
    this.onTapVerse,
    this.onLongPressVerse,
    required this.toastPageNotifier,
    this.toastPageIndexOffset = 0,
    this.toastExtraTitleForPage,
  });

  @override
  State<MushafPagedReader> createState() => _MushafPagedReaderState();
}

class _MushafPagedReaderState extends State<MushafPagedReader> {
  @override
  void initState() {
    super.initState();
    if (!kReleaseMode) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    }
  }

  @override
  void dispose() {
    if (!kReleaseMode) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (kReleaseMode) return;
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
      if (buildMs > 16.6 || rasterMs > 16.6 || totalMs > 16.6) {
        debugPrint(
          '[QCF_PERF] slowFrame ui=${buildMs.toStringAsFixed(2)}ms raster=${rasterMs.toStringAsFixed(2)}ms total=${totalMs.toStringAsFixed(2)}ms',
        );
      }
    }
  }

  int _pageAt(int index) {
    final list = widget.pages;
    return list != null ? list[index] : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final pageList = widget.pages;
    final itemCount = pageList != null ? pageList.length : 604;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onToggleControls,
          child: SafeArea(
            top: false,
            child: PageView.builder(
              controller: widget.controller,
              allowImplicitScrolling: true,
              physics: const MushafPageScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              itemCount: itemCount,
              onPageChanged: (pageIndex) {
                final newPage = _pageAt(pageIndex);
                final prevToastValue =
                    widget.toastPageNotifier.value + widget.toastPageIndexOffset;
                final readingDirection = newPage.compareTo(prevToastValue);
                final cached = QcfMushafRepository.getCachedPage(
                  newPage,
                  onlySurahNumber: widget.onlySurahNumber,
                );
                if (!kReleaseMode) {
                  debugPrint(
                    '[QCF_PERF] onPageChanged index=$pageIndex page=$newPage dir=$readingDirection cached=${cached != null}',
                  );
                }
                widget.onPageChanged(pageIndex, newPage, cached);
                QcfMushafRepository.prefetchAdjacentPages(
                  newPage,
                  direction: readingDirection,
                  onlySurahNumber: widget.onlySurahNumber,
                  allowedPages: pageList,
                );
              },
              itemBuilder: (context, index) {
                final pageNumber = _pageAt(index);
                return _MushafPageFutureSlot(
                  key: ValueKey<String>(
                    'qcf_slot_${widget.onlySurahNumber ?? 'all'}_$pageNumber',
                  ),
                  pageNumber: pageNumber,
                  onlySurahNumber: widget.onlySurahNumber,
                  isDark: widget.isDark,
                  accentColor: widget.accentColor,
                  loadingSourceName: widget.loadingSourceName,
                  isPageBookmarked: widget.bookmarkedPage == pageNumber,
                  topInset: topInset,
                  highlightedVerseKeyBuilder: widget.highlightedVerseKeyBuilder,
                  onTapVerse: widget.onTapVerse,
                  onLongPressVerse: widget.onLongPressVerse,
                );
              },
            ),
          ),
        ),
        MushafSectionStartToast(
          pageNotifier: widget.toastPageNotifier,
          isDark: widget.isDark,
          pageIndexOffset: widget.toastPageIndexOffset,
          extraTitleForPage: widget.toastExtraTitleForPage,
        ),
      ],
    );
  }
}

class _MushafPageFutureSlot extends StatefulWidget {
  final int pageNumber;
  final int? onlySurahNumber;
  final bool isDark;
  final Color accentColor;
  final String loadingSourceName;
  final bool isPageBookmarked;
  final double topInset;
  final String? Function(int pageNumber, QcfMushafPageData pageData)
      highlightedVerseKeyBuilder;
  final void Function(int pageNumber, int surahNumber, int ayahNumber)?
      onTapVerse;
  final void Function(int pageNumber, int surahNumber, int ayahNumber)?
      onLongPressVerse;

  const _MushafPageFutureSlot({
    super.key,
    required this.pageNumber,
    required this.onlySurahNumber,
    required this.isDark,
    required this.accentColor,
    required this.loadingSourceName,
    required this.isPageBookmarked,
    required this.topInset,
    required this.highlightedVerseKeyBuilder,
    this.onTapVerse,
    this.onLongPressVerse,
  });

  @override
  State<_MushafPageFutureSlot> createState() => _MushafPageFutureSlotState();
}

class _MushafPageFutureSlotState extends State<_MushafPageFutureSlot> {
  QcfMushafPageData? _cachedPage;
  Future<QcfMushafPageData>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _resolvePageSource();
  }

  @override
  void didUpdateWidget(covariant _MushafPageFutureSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.onlySurahNumber != widget.onlySurahNumber) {
      _resolvePageSource();
    } else if (_cachedPage == null) {
      final refreshed = QcfMushafRepository.getCachedPage(
        widget.pageNumber,
        onlySurahNumber: widget.onlySurahNumber,
      );
      if (refreshed != null) {
        _cachedPage = refreshed;
        _loadFuture = null;
      }
    }
  }

  void _resolvePageSource() {
    final cached = QcfMushafRepository.getCachedPage(
      widget.pageNumber,
      onlySurahNumber: widget.onlySurahNumber,
    );
    _cachedPage = cached;
    _loadFuture = cached != null
        ? null
        : QcfMushafRepository.loadPage(
            widget.pageNumber,
            onlySurahNumber: widget.onlySurahNumber,
          );
  }

  Widget _buildPageWidget(QcfMushafPageData pageData) {
    final pageNumber = widget.pageNumber;
    return QcfMushafPageWidget(
      pageData: pageData,
      highlightedVerseKey:
          widget.highlightedVerseKeyBuilder(pageNumber, pageData),
      isPageBookmarked: widget.isPageBookmarked,
      topInset: widget.topInset,
      isDark: widget.isDark,
      accentColor: widget.accentColor,
      onTapVerse: widget.onTapVerse == null
          ? null
          : (sNum, aNum) => widget.onTapVerse!(pageNumber, sNum, aNum),
      onLongPressVerse: widget.onLongPressVerse == null
          ? null
          : (sNum, aNum) => widget.onLongPressVerse!(pageNumber, sNum, aNum),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cached = _cachedPage;
    if (cached != null) {
      return _buildPageWidget(cached);
    }

    return FutureBuilder<QcfMushafPageData>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          final arabicPageNum = QuranTextFormatter.toArabicDigits(
            widget.pageNumber.toString(),
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: widget.accentColor,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'جاري فتح الصفحة $arabicPageNum من ${widget.loadingSourceName}...',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDark ? Colors.tealAccent : widget.accentColor,
                  ),
                ),
              ],
            ),
          );
        }

        final pageData = snapshot.data!;
        _cachedPage = pageData;
        return _buildPageWidget(pageData);
      },
    );
  }
}
