import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';

class MushafPageSection {
  final int surahNumber;
  final String surahName;
  final int verseStart;
  final int verseEnd;
  final String text;

  const MushafPageSection({
    required this.surahNumber,
    required this.surahName,
    required this.verseStart,
    required this.verseEnd,
    required this.text,
  });

  bool get startsSurah => verseStart == 1;
  bool get showBismillah =>
      verseStart == 1 && surahNumber != 1 && surahNumber != 9;
}

class MushafPageContent {
  final int pageNumber;
  final int juz;
  final int surahNumber;
  final String surahName;
  final String contentText;
  final List<MushafPageSection> sections;

  const MushafPageContent({
    required this.pageNumber,
    required this.juz,
    required this.surahNumber,
    required this.surahName,
    required this.contentText,
    this.sections = const [],
  });
}

class QuranRepository {
  static List<dynamic>? _quranJsonData;
  static Map<String, dynamic>? _pageMappingJson;
  static final Map<int, String> _surahTextCache = {};
  static final Map<int, MushafPageContent> _pageCache = {};
  static final Map<int, MushafPageContent> _kahfPageCache = {};

  /// Loads and validates the full Quran JSON from assets/data/quran.json
  static Future<List<dynamic>> loadQuran() async {
    if (_quranJsonData != null) return _quranJsonData!;

    final text = await rootBundle.loadString('assets/data/quran.json');
    final surahs = jsonDecode(text) as List<dynamic>;

    final ayahCount = surahs.fold<int>(
      0,
      (total, surah) => total + (surah['verses'] as List).length,
    );

    if (surahs.length != 114 || ayahCount != 6236) {
      throw const FormatException('Incomplete Quran data');
    }

    _quranJsonData = surahs;
    return surahs;
  }

  /// Loads the official 604 Madani page mapping JSON
  static Future<Map<String, dynamic>> loadPageMapping() async {
    if (_pageMappingJson != null) return _pageMappingJson!;
    try {
      final text = await rootBundle.loadString('assets/data/quran_pages_mapping.json');
      _pageMappingJson = jsonDecode(text) as Map<String, dynamic>;
      return _pageMappingJson!;
    } catch (_) {
      return {};
    }
  }

  /// Gets the complete text for a specific surah by number (1 to 114)
  static Future<String> getSurahFullText(int surahNumber) async {
    if (_surahTextCache.containsKey(surahNumber)) {
      return _surahTextCache[surahNumber]!;
    }

    try {
      final surahs = await loadQuran();
      final surahData = surahs.firstWhere(
        (s) => s['id'] == surahNumber,
        orElse: () => null,
      );

      if (surahData != null && surahData['verses'] is List) {
        final verses = surahData['verses'] as List;
        final buffer = StringBuffer();

        for (final v in verses) {
          final id = v['id'];
          var text = v['text'] as String;

          // Strip prepended Bismillah from verse 1 for surahs 2..114 (except #9 At-Tawbah)
          if (id == 1 && surahNumber != 1 && surahNumber != 9) {
            final bismillahPattern = RegExp(
              r'^بِسۡمِ\s+ٱللَّهِ\s+ٱلرَّحۡمَٰنِ\s+ٱلرَّحِيمِ\s*|^بِسْمِ\s+ٱللَّهِ\s+ٱلرَّحْمَٰنِ\s+ٱلرَّحِيمِ\s*|^بِسْمِ\s+اللَّهِ\s+الرَّحْمَٰنِ\s+الرَّحِيمِ\s*',
            );
            text = text.replaceFirst(bismillahPattern, '').trim();
          }

          buffer.write('$text ﴿$id﴾ ');
        }

        final fullText = buffer.toString().trim();
        _surahTextCache[surahNumber] = fullText;
        return fullText;
      }
    } catch (_) {}

    // Fallback to static surah text if needed
    final fallback = QuranData.surahs.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () => QuranData.surahs.first,
    );
    return fallback.text;
  }

  static MushafPageContent? getCachedPageContent(
    int pageNumber, {
    bool filterKahfOnly = false,
  }) {
    final pageNum = pageNumber.clamp(1, 604);
    return filterKahfOnly ? _kahfPageCache[pageNum] : _pageCache[pageNum];
  }

  static void prefetchAdjacentPages(
    int pageNumber, {
    bool filterKahfOnly = false,
  }) {
    final minPage = filterKahfOnly ? 293 : 1;
    final maxPage = filterKahfOnly ? 304 : 604;
    for (final target in [pageNumber - 1, pageNumber + 1]) {
      if (target >= minPage && target <= maxPage) {
        if (getCachedPageContent(target, filterKahfOnly: filterKahfOnly) ==
            null) {
          getPageContent(target, filterKahfOnly: filterKahfOnly);
        }
      }
    }
  }

  /// Gets the exact page content for any Madani Mushaf page (1 to 604) based on official 604-page mapping JSON
  static Future<MushafPageContent> getPageContent(int pageNumber, {bool filterKahfOnly = false}) async {
    final pageNum = pageNumber.clamp(1, 604);
    if (filterKahfOnly && _kahfPageCache.containsKey(pageNum)) {
      return _kahfPageCache[pageNum]!;
    }
    if (!filterKahfOnly && _pageCache.containsKey(pageNum)) {
      return _pageCache[pageNum]!;
    }

    final mapping = await loadPageMapping();
    final surahs = await loadQuran();
    final juz = QuranPageMapping.getJuzForPage(pageNum);

    if (mapping.containsKey('pages') && mapping['pages'] is List) {
      final pagesList = mapping['pages'] as List;
      final pageData = pagesList.firstWhere(
        (p) => p['page'] == pageNum,
        orElse: () => null,
      );

      if (pageData != null && pageData['sections'] is List) {
        final sections = pageData['sections'] as List;
        final buffer = StringBuffer();
        final pageSections = <MushafPageSection>[];
        int primarySurahNumber = 18;
        String primarySurahName = "الكهف";

        for (int i = 0; i < sections.length; i++) {
          final sec = sections[i];
          final sId = sec['surah_number'] as int;
          final sName = sec['surah_name'] as String;
          final vStart = sec['verse_start'] as int;
          final vEnd = sec['verse_end'] as int;

          // If in Surah Kahf screen, skip Surah 17 (Al-Isra) verses on Page 293
          if (filterKahfOnly && sId != 18) {
            continue;
          }

          if (buffer.isEmpty) {
            primarySurahNumber = sId;
            primarySurahName = sName;
          }

          final surahObj = surahs.firstWhere(
            (s) => s['id'] == sId,
            orElse: () => null,
          );

          if (surahObj != null && surahObj['verses'] is List) {
            final verses = surahObj['verses'] as List;
            final sectionBuffer = StringBuffer();

            for (final v in verses) {
              final vId = v['id'] as int;
              if (vId >= vStart && vId <= vEnd) {
                var text = v['text'] as String;

                // Strip Bismillah prefix from verse 1 for surahs 2..114 (except #9)
                if (vId == 1 && sId != 1 && sId != 9) {
                  final bismillahPattern = RegExp(
                    r'^بِسۡمِ\s+ٱللَّهِ\s+ٱلرَّحۡمَٰنِ\s+ٱلرَّحِيمِ\s*|^بِسْمِ\s+ٱللَّهِ\s+ٱلرَّحْمَٰنِ\s+ٱلرَّحِيمِ\s*|^بِسْمِ\s+اللَّهِ\s+الرَّحْمَٰنِ\s+الرَّحِيمِ\s*',
                  );
                  text = text.replaceFirst(bismillahPattern, '').trim();
                }

                sectionBuffer.write('$text ﴿$vId﴾ ');
                buffer.write('$text ﴿$vId﴾ ');
              }
            }

            final sectionText = sectionBuffer.toString().trim();
            if (sectionText.isNotEmpty) {
              pageSections.add(
                MushafPageSection(
                  surahNumber: sId,
                  surahName: sName,
                  verseStart: vStart,
                  verseEnd: vEnd,
                  text: sectionText,
                ),
              );
            }
          }
        }

        final pageContent = MushafPageContent(
          pageNumber: pageNum,
          juz: juz,
          surahNumber: primarySurahNumber,
          surahName: primarySurahName,
          contentText: buffer.toString().trim(),
          sections: pageSections,
        );

        if (filterKahfOnly) {
          _kahfPageCache[pageNum] = pageContent;
        } else {
          _pageCache[pageNum] = pageContent;
        }
        return pageContent;
      }
    }

    // Fallback range lookup if mapping JSON unavailable
    final range = QuranPageMapping.getPageRange(pageNum);
    final buffer = StringBuffer();
    final pageSections = <MushafPageSection>[];
    final primarySurahMeta = QuranData.surahs.firstWhere(
      (s) => s.number == range.startSurah,
      orElse: () => QuranData.surahs.first,
    );

    for (int sId = range.startSurah; sId <= range.endSurah; sId++) {
      if (filterKahfOnly && sId != 18) continue;

      final surahData = surahs.firstWhere(
        (s) => s['id'] == sId,
        orElse: () => null,
      );
      final surahMeta = QuranData.surahs.firstWhere(
        (s) => s.number == sId,
        orElse: () => primarySurahMeta,
      );

      if (surahData != null && surahData['verses'] is List) {
        final verses = surahData['verses'] as List;
        final startA = (sId == range.startSurah) ? range.startAyah : 1;
        final endA = (sId == range.endSurah) ? range.endAyah : verses.length;
        final sectionBuffer = StringBuffer();

        for (final v in verses) {
          final vId = v['id'] as int;
          if (vId >= startA && vId <= endA) {
            var text = v['text'] as String;

            if (vId == 1 && sId != 1 && sId != 9) {
              final bismillahPattern = RegExp(
                r'^بِسۡمِ\s+ٱللَّهِ\s+ٱلرَّحۡمَٰنِ\s+ٱلرَّحِيمِ\s*|^بِسْمِ\s+ٱللَّهِ\s+ٱلرَّحْمَٰنِ\s+ٱلرَّحِيمِ\s*|^بِسْمِ\s+اللَّهِ\s+الرَّحْمَٰنِ\s+الرَّحِيمِ\s*',
              );
              text = text.replaceFirst(bismillahPattern, '').trim();
            }

            sectionBuffer.write('$text ﴿$vId﴾ ');
            buffer.write('$text ﴿$vId﴾ ');
          }
        }

        final sectionText = sectionBuffer.toString().trim();
        if (sectionText.isNotEmpty) {
          pageSections.add(
            MushafPageSection(
              surahNumber: sId,
              surahName: surahMeta.name,
              verseStart: startA,
              verseEnd: endA,
              text: sectionText,
            ),
          );
        }
      }
    }

    final pageContent = MushafPageContent(
      pageNumber: pageNum,
      juz: range.juz,
      surahNumber: range.startSurah,
      surahName: primarySurahMeta.name,
      contentText: buffer.toString().trim(),
      sections: pageSections,
    );

    if (filterKahfOnly) {
      _kahfPageCache[pageNum] = pageContent;
    } else {
      _pageCache[pageNum] = pageContent;
    }
    return pageContent;
  }
}
