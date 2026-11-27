import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/qcf_mushaf_repository.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_scroll_physics.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_section_start_toast.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_mushaf_page_widget.dart';

class MushafPagedReader extends StatelessWidget {
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

  int _pageAt(int index) {
    final list = pages;
    return list != null ? list[index] : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final pageList = pages;
    final itemCount = pageList != null ? pageList.length : 604;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onToggleControls,
          child: SafeArea(
            top: false,
            child: PageView.builder(
              controller: controller,
              allowImplicitScrolling: true,
              physics: const MushafPageScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              itemCount: itemCount,
              onPageChanged: (pageIndex) {
                final newPage = _pageAt(pageIndex);
                final prevToastValue =
                    toastPageNotifier.value + toastPageIndexOffset;
                final readingDirection = newPage.compareTo(prevToastValue);
                final cached = QcfMushafRepository.getCachedPage(
                  newPage,
                  onlySurahNumber: onlySurahNumber,
                );
                onPageChanged(pageIndex, newPage, cached);
                QcfMushafRepository.prefetchAdjacentPages(
                  newPage,
                  direction: readingDirection,
                  onlySurahNumber: onlySurahNumber,
                  allowedPages: pageList,
                );
                QcfMushafRepository.prefetchReadingPageFonts(
                  newPage,
                  direction: readingDirection,
                  allowedPages: pageList,
                );
              },
              itemBuilder: (context, index) {
                final pageNumber = _pageAt(index);
                final cachedPage = QcfMushafRepository.getCachedPage(
                  pageNumber,
                  onlySurahNumber: onlySurahNumber,
                );

                return FutureBuilder<QcfMushafPageData>(
                  initialData: cachedPage,
                  future: cachedPage != null
                      ? null
                      : QcfMushafRepository.loadPage(
                          pageNumber,
                          onlySurahNumber: onlySurahNumber,
                        ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      final arabicPageNum = QuranTextFormatter.toArabicDigits(
                        pageNumber.toString(),
                      );
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: accentColor,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'جاري فتح الصفحة $arabicPageNum من $loadingSourceName...',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.tealAccent : accentColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final pageData = snapshot.data!;
                    return QcfMushafPageWidget(
                      pageData: pageData,
                      highlightedVerseKey:
                          highlightedVerseKeyBuilder(pageNumber, pageData),
                      isPageBookmarked: bookmarkedPage == pageNumber,
                      topInset: topInset,
                      isDark: isDark,
                      accentColor: accentColor,
                      onTapVerse: onTapVerse == null
                          ? null
                          : (sNum, aNum) =>
                              onTapVerse!(pageNumber, sNum, aNum),
                      onLongPressVerse: onLongPressVerse == null
                          ? null
                          : (sNum, aNum) =>
                              onLongPressVerse!(pageNumber, sNum, aNum),
                    );
                  },
                );
              },
            ),
          ),
        ),
        MushafSectionStartToast(
          pageNotifier: toastPageNotifier,
          isDark: isDark,
          pageIndexOffset: toastPageIndexOffset,
          extraTitleForPage: toastExtraTitleForPage,
        ),
      ],
    );
  }
}
