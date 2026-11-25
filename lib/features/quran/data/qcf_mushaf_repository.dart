import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';

class QcfMushafWord {
  static final RegExp _pureDigitsRegex = RegExp(r'^[\u0660-\u06690-9]+$');
  static final RegExp _trailingDigitsRegex = RegExp(r'\s+[\u0660-\u06690-9]+$');
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  static final RegExp _divineNameRegex = RegExp(
    r'^(?:[وبفتكل]|ا|اب|ول|فل|بل|تل)?(?:الله|لله|اللهم)$',
  );
  static final RegExp _rabbRegex = RegExp(
    r'^(?:[وبفل]|ول|فل|بل)?(?:ال)?رب(?:[يى]|ك|كم|كما|نا|هم|هما|هن|ها|ه)?$',
  );
  static final RegExp _ilahRegex = RegExp(
    r'^(?:[وبفول]|ا|ول|فل)?اله(?:[يى]|ك|كم|نا|هم|ه)?$',
  );
  static final RegExp _huwaRegex = RegExp(r'^(?:[وف])?هو$');
  static const Set<String> _explicitDivineHuwaLocations = <String>{
    '85:13:2',
    '85:14:1',
    '112:1:2',
    '2:255:4',
    '59:22:3',
    '59:23:3',
    '59:24:1',
  };
  static const Set<String> _verifiedDivineNames = <String>{
    'الرحمن',
    'الرحيم',
    'الغفور',
    'العزيز',
    'الحكيم',
    'العليم',
    'السميع',
    'البصير',
    'القدير',
    'اللطيف',
    'الخبير',
    'التواب',
    'الغني',
    'الحميد',
    'المجيد',
    'الودود',
    'القيوم',
    'الصمد',
    'الغفار',
    'القهار',
    'الوهاب',
    'الرزاق',
    'الفتاح',
    'الحليم',
    'العظيم',
    'الرقيب',
    'المجيب',
    'القدوس',
    'المهيمن',
    'الجبار',
    'المتكبر',
    'البارئ',
    'المصور',
    'الشكور',
    'الرؤوف',
    'الواسع',
    'الحفيظ',
    'الحسيب',
    'المقيت',
  };
  static const Set<String> _nonDivineNameContexts = <String>{
    '12:30:6',
    '12:51:19',
    '12:78:3',
    '12:88:6',
  };

  final int surahNumber;
  final int ayahNumber;
  final int wordIndex;
  final String arabicWord;
  final String glyph;

  const QcfMushafWord({
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.arabicWord,
    required this.glyph,
  });

  String get verseKey => '$surahNumber:$ayahNumber';
  String get locationKey => '$surahNumber:$ayahNumber:$wordIndex';

  bool get isPureAyahOrnament => _pureDigitsRegex.hasMatch(arabicWord.trim());

  bool get isSajdahWord => arabicWord.contains('\u06E9');

  bool get hasTrailingAyahOrnament =>
      !isPureAyahOrnament &&
      _trailingDigitsRegex.hasMatch(arabicWord.trim()) &&
      glyph.contains(' ');

  String get _normalizedWord {
    final withoutDigits =
        arabicWord.trim().replaceFirst(_trailingDigitsRegex, '');
    return withoutDigits
        .replaceAll(_diacriticsRegex, '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .trim();
  }

  bool get isDivineName => _divineNameRegex.hasMatch(_normalizedWord);

  bool get isDivineReference => isWordDivineReference(this);

  static bool isWordDivineReference(
    QcfMushafWord word, {
    QcfMushafWord? prevWord,
    QcfMushafWord? nextWord,
  }) {
    final normalized = word._normalizedWord;
    if (normalized.isEmpty) return false;
    if (_divineNameRegex.hasMatch(normalized)) return true;
    if (_rabbRegex.hasMatch(normalized)) return true;
    if (_ilahRegex.hasMatch(normalized)) return true;

    if (_huwaRegex.hasMatch(normalized)) {
      if (_explicitDivineHuwaLocations.contains(word.locationKey)) return true;
      if (prevWord != null &&
          prevWord.verseKey == word.verseKey &&
          prevWord._normalizedWord == 'الا') {
        return true;
      }
      if (nextWord != null &&
          nextWord.verseKey == word.verseKey &&
          (_divineNameRegex.hasMatch(nextWord._normalizedWord) ||
              _verifiedDivineNames.contains(nextWord._normalizedWord))) {
        return true;
      }
      return false;
    }

    if (_nonDivineNameContexts.contains(word.locationKey)) return false;

    var baseName = normalized;
    if ((baseName.startsWith('و') ||
            baseName.startsWith('ف') ||
            baseName.startsWith('ب')) &&
        baseName.length > 3 &&
        baseName.substring(1).startsWith('ال')) {
      baseName = baseName.substring(1);
    }
    return _verifiedDivineNames.contains(baseName);
  }

  factory QcfMushafWord.fromJson(Map<String, dynamic> json) {
    final loc = (json['location'] as String? ?? '1:1:1').split(':');
    final surah = int.tryParse(loc.isNotEmpty ? loc[0] : '1') ?? 1;
    final ayah = int.tryParse(loc.length > 1 ? loc[1] : '1') ?? 1;
    final wordIdx = int.tryParse(loc.length > 2 ? loc[2] : '1') ?? 1;

    return QcfMushafWord(
      surahNumber: surah,
      ayahNumber: ayah,
      wordIndex: wordIdx,
      arabicWord: json['word'] as String? ?? '',
      glyph: json['qpcV1'] as String? ?? '',
    );
  }
}

class QcfMushafLine {
  final int lineNumber;
  final String type;
  final String text;
  final String? surahCode;
  final String? qpcV1;
  final List<QcfMushafWord> words;

  const QcfMushafLine({
    required this.lineNumber,
    required this.type,
    required this.text,
    this.surahCode,
    this.qpcV1,
    required this.words,
  });

  int? get headerSurahNumber =>
      surahCode == null ? null : int.tryParse(surahCode!);

  factory QcfMushafLine.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>? ?? const [];
    return QcfMushafLine(
      lineNumber: json['line'] as int? ?? 1,
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String? ?? '',
      surahCode: json['surah'] as String?,
      qpcV1: json['qpcV1'] as String?,
      words: rawWords
          .whereType<Map<String, dynamic>>()
          .map(QcfMushafWord.fromJson)
          .toList(growable: false),
    );
  }
}

class QcfMushafPageData {
  final int pageNumber;
  final String fontFamily;
  final int surahNumber;
  final String surahName;
  final int juz;
  final List<QcfMushafLine> lines;

  const QcfMushafPageData({
    required this.pageNumber,
    required this.fontFamily,
    required this.surahNumber,
    required this.surahName,
    required this.juz,
    required this.lines,
  });

  factory QcfMushafPageData.fromJson(
    Map<String, dynamic> json, {
    required String fontFamily,
    int? onlySurahNumber,
  }) {
    final pageNum = (json['page'] as int? ?? 1).clamp(1, 604);
    final rawLines = json['lines'] as List<dynamic>? ?? const [];
    final allLines = rawLines
        .whereType<Map<String, dynamic>>()
        .map(QcfMushafLine.fromJson)
        .toList(growable: false);

    final filteredLines = onlySurahNumber == null
        ? allLines
        : _filterLinesForSurah(allLines, onlySurahNumber);

    int primarySurah = onlySurahNumber ??
        QuranPageMapping.getPageRange(pageNum).startSurah;
    if (onlySurahNumber == null) {
      for (final line in filteredLines) {
        if (line.type == 'text' && line.words.isNotEmpty) {
          primarySurah = line.words.first.surahNumber;
          break;
        }
        if (line.type == 'surah-header' && line.headerSurahNumber != null) {
          primarySurah = line.headerSurahNumber!;
          break;
        }
      }
    }

    final surahMeta = QuranData.surahs.firstWhere(
      (s) => s.number == primarySurah,
      orElse: () => QuranData.surahs.first,
    );

    return QcfMushafPageData(
      pageNumber: pageNum,
      fontFamily: fontFamily,
      surahNumber: primarySurah,
      surahName: surahMeta.name,
      juz: QuranPageMapping.getJuzForPage(pageNum),
      lines: filteredLines,
    );
  }

  static List<QcfMushafLine> _filterLinesForSurah(
    List<QcfMushafLine> lines,
    int surahNumber,
  ) {
    final result = <QcfMushafLine>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.type == 'surah-header') {
        if (line.headerSurahNumber == surahNumber) {
          result.add(line);
        }
      } else if (line.type == 'basmala') {
        bool belongsToSurah = false;
        for (int j = i + 1; j < lines.length; j++) {
          if (lines[j].type == 'text' && lines[j].words.isNotEmpty) {
            belongsToSurah =
                lines[j].words.any((w) => w.surahNumber == surahNumber);
            break;
          }
        }
        if (belongsToSurah) {
          result.add(line);
        }
      } else {
        final filteredWords = line.words
            .where((w) => w.surahNumber == surahNumber)
            .toList(growable: false);
        if (filteredWords.isNotEmpty) {
          result.add(
            QcfMushafLine(
              lineNumber: line.lineNumber,
              type: line.type,
              text: line.text,
              surahCode: line.surahCode,
              qpcV1: line.qpcV1,
              words: filteredWords,
            ),
          );
        }
      }
    }
    return result;
  }
}

class QcfMushafRepository {
  static const String basmalaFontFamily = 'QCF_BSML';
  static const int _maxCacheSize = 15;

  static final Set<String> _loadedFontFamilies = <String>{};
  static final Map<String, Future<void>> _inFlightFonts =
      <String, Future<void>>{};
  static final LinkedHashMap<String, QcfMushafPageData> _pageCache =
      LinkedHashMap<String, QcfMushafPageData>();

  static String fontFamilyFor(int pageNumber) {
    final padded = pageNumber.clamp(1, 604).toString().padLeft(3, '0');
    return 'QCF_P$padded';
  }

  static String fontAssetPathFor(int pageNumber) {
    final padded = pageNumber.clamp(1, 604).toString().padLeft(3, '0');
    return 'assets/mushaf_qcf/fonts/QCF_P$padded.ttf';
  }

  static String layoutAssetPathFor(int pageNumber) {
    final padded = pageNumber.clamp(1, 604).toString().padLeft(3, '0');
    return 'assets/mushaf_qcf/layout/page_$padded.json';
  }

  static Future<void> _ensureFontRegistered(
    String family,
    String assetPath,
  ) {
    if (_loadedFontFamilies.contains(family)) {
      return Future<void>.value();
    }
    final existing = _inFlightFonts[family];
    if (existing != null) return existing;

    final future = () async {
      final fontData = await rootBundle.load(assetPath);
      final loader = FontLoader(family)..addFont(Future<ByteData>.value(fontData));
      await loader.load();
      _loadedFontFamilies.add(family);
    }().whenComplete(() {
      _inFlightFonts.remove(family);
    });

    _inFlightFonts[family] = future;
    return future;
  }

  static Future<void> ensurePageFontsLoaded(int pageNumber) async {
    final page = pageNumber.clamp(1, 604);
    await Future.wait(<Future<void>>[
      _ensureFontRegistered(fontFamilyFor(page), fontAssetPathFor(page)),
      _ensureFontRegistered(
        basmalaFontFamily,
        'assets/mushaf_qcf/fonts/QCF_BSML.ttf',
      ),
    ]);
  }

  static String _cacheKey(int pageNumber, int? onlySurahNumber) =>
      onlySurahNumber != null
          ? '${onlySurahNumber}_$pageNumber'
          : 'mushaf_$pageNumber';

  static QcfMushafPageData? getCachedPage(
    int pageNumber, {
    int? onlySurahNumber,
  }) {
    final page = pageNumber.clamp(1, 604);
    final family = fontFamilyFor(page);
    if (!_loadedFontFamilies.contains(family)) return null;
    final key = _cacheKey(page, onlySurahNumber);
    final hit = _pageCache.remove(key);
    if (hit != null) {
      _pageCache[key] = hit;
    }
    return hit;
  }

  static Future<QcfMushafPageData> loadPage(
    int pageNumber, {
    int? onlySurahNumber,
  }) async {
    final page = pageNumber.clamp(1, 604);
    final key = _cacheKey(page, onlySurahNumber);
    final cached = _pageCache.remove(key);
    if (cached != null) {
      await ensurePageFontsLoaded(page);
      _pageCache[key] = cached;
      return cached;
    }

    await ensurePageFontsLoaded(page);
    final layoutJson = await rootBundle.loadString(layoutAssetPathFor(page));
    final decoded = jsonDecode(layoutJson) as Map<String, dynamic>;
    final pageData = QcfMushafPageData.fromJson(
      decoded,
      fontFamily: fontFamilyFor(page),
      onlySurahNumber: onlySurahNumber,
    );

    if (_pageCache.length >= _maxCacheSize) {
      _pageCache.remove(_pageCache.keys.first);
    }
    _pageCache[key] = pageData;
    return pageData;
  }

  static void prefetchAdjacentPages(
    int pageNumber, {
    int? onlySurahNumber,
    List<int>? allowedPages,
  }) {
    for (final target in <int>[
      pageNumber - 1,
      pageNumber + 1,
      pageNumber - 2,
      pageNumber + 2,
    ]) {
      if (target < 1 || target > 604) continue;
      if (allowedPages != null && !allowedPages.contains(target)) continue;
      if (getCachedPage(target, onlySurahNumber: onlySurahNumber) == null) {
        loadPage(target, onlySurahNumber: onlySurahNumber);
      }
    }
  }
}
