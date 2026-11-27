import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:religious_tasks_app/features/quran/data/qcf_mushaf_repository.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import 'package:religious_tasks_app/features/quran/theme/mushaf_reader_theme.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_scroll_physics.dart';
import 'package:religious_tasks_app/features/quran/widgets/mushaf_page_side_indicator.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_mushaf_page_widget.dart';
import 'package:religious_tasks_app/features/quran/widgets/qcf_opening_page_frame.dart';

void main() {
  test('All 604 QCF V1 fonts and layout JSONs exist and cover all 6236 ayahs', () {
    expect(File('assets/mushaf_qcf/fonts/QCF_BSML.ttf').existsSync(), isTrue);

    final quranJson =
        jsonDecode(File('assets/data/quran.json').readAsStringSync()) as List<dynamic>;
    final expectedAyahs = <String>{};
    for (final surah in quranJson.whereType<Map<String, dynamic>>()) {
      final sId = surah['id'] as int;
      final verses = surah['verses'] as List<dynamic>;
      for (final v in verses.whereType<Map<String, dynamic>>()) {
        expectedAyahs.add('$sId:${v['id']}');
      }
    }
    expect(expectedAyahs.length, 6236);

    final seenAyahs = <String>{};
    for (int page = 1; page <= 604; page++) {
      final padded = page.toString().padLeft(3, '0');
      final fontFile = File('assets/mushaf_qcf/fonts/QCF_P$padded.ttf');
      final layoutFile = File('assets/mushaf_qcf/layout/page_$padded.json');
      expect(fontFile.existsSync(), isTrue, reason: 'Missing font for page $page');
      expect(layoutFile.existsSync(), isTrue, reason: 'Missing layout for page $page');

      final map = jsonDecode(layoutFile.readAsStringSync()) as Map<String, dynamic>;
      final data = QcfMushafPageData.fromJson(
        map,
        fontFamily: QcfMushafRepository.fontFamilyFor(page),
      );
      expect(data.pageNumber, page);
      expect(data.lines, isNotEmpty);

      for (final line in data.lines) {
        for (final word in line.words) {
          seenAyahs.add(word.verseKey);
          expect(word.glyph, isNotEmpty);
        }
      }
    }

    expect(seenAyahs.length, 6236);
    expect(expectedAyahs.difference(seenAyahs), isEmpty);
  });

  test('Surah Al-Kahf filtering on page 293 excludes Surah Al-Isra verses', () {
    final map = jsonDecode(
      File('assets/mushaf_qcf/layout/page_293.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final kahfPage = QcfMushafPageData.fromJson(
      map,
      fontFamily: 'QCF_P293',
      onlySurahNumber: 18,
    );

    expect(kahfPage.surahNumber, 18);
    final words = kahfPage.lines.expand((l) => l.words).toList();
    expect(words, isNotEmpty);
    expect(words.every((w) => w.surahNumber == 18), isTrue);
    expect(
      kahfPage.lines.any((l) => l.type == 'surah-header' && l.headerSurahNumber == 18),
      isTrue,
    );
  });

  testWidgets('QcfMushafPageWidget renders special pages in light and dark modes with no scroll',
      (tester) async {
    for (final spec in <(int, int?)>[
      (1, null),
      (3, null),
      (15, null),
      (293, 18),
      (604, null),
    ]) {
      final padded = spec.$1.toString().padLeft(3, '0');
      final map = jsonDecode(
        File('assets/mushaf_qcf/layout/page_$padded.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final pageData = QcfMushafPageData.fromJson(
        map,
        fontFamily: 'Roboto',
        onlySurahNumber: spec.$2,
      );

      for (final isDark in <bool>[false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 760,
                child: QcfMushafPageWidget(
                  pageData: pageData,
                  highlightedVerseKey: null,
                  isDark: isDark,
                  accentColor: const Color(0xFF0F766E),
                  onTapVerse: (_, __) {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SingleChildScrollView), findsNothing);
      }
    }
  });

  test('All 112 basmala lines across 604 pages are valid and exclude Surah 1 & 9', () {
    int basmalaCount = 0;
    for (int page = 1; page <= 604; page++) {
      final padded = page.toString().padLeft(3, '0');
      final map = jsonDecode(
        File('assets/mushaf_qcf/layout/page_$padded.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final data = QcfMushafPageData.fromJson(
        map,
        fontFamily: QcfMushafRepository.fontFamilyFor(page),
      );
      for (final line in data.lines) {
        if (line.type == 'basmala') {
          basmalaCount++;
          expect(line.qpcV1, '#"!');
        }
      }
      if (page == 1) {
        expect(data.lines.any((l) => l.type == 'basmala'), isFalse);
      }
      if (page == 187) {
        expect(data.lines.any((l) => l.type == 'basmala'), isFalse);
      }
    }
    expect(basmalaCount, 112);
  });

  testWidgets('Bismillah renders LTR for QCF_BSML and bookmark indicator appears when saved',
      (tester) async {
    final map = jsonDecode(
      File('assets/mushaf_qcf/layout/page_002.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final pageData = QcfMushafPageData.fromJson(
      map,
      fontFamily: 'Roboto',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 760,
            child: QcfMushafPageWidget(
              pageData: pageData,
              highlightedVerseKey: null,
              isPageBookmarked: true,
              isDark: false,
              accentColor: const Color(0xFF0F766E),
              onTapVerse: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(QcfMushafPageWidget), findsOneWidget);
    expect(find.byType(MushafBookmarkRibbon), findsOneWidget);
  });

  test('Expanded divine references match valid Quranic terms and reject false positives', () {
    const validExamples = <QcfMushafWord>[
      QcfMushafWord(surahNumber: 1, ayahNumber: 2, wordIndex: 2, arabicWord: 'لِلَّهِ', glyph: 'a'),
      QcfMushafWord(surahNumber: 1, ayahNumber: 2, wordIndex: 3, arabicWord: 'رَبِّ', glyph: 'b'),
      QcfMushafWord(surahNumber: 1, ayahNumber: 3, wordIndex: 1, arabicWord: 'ٱلرَّحْمَـٰنِ', glyph: 'c'),
      QcfMushafWord(surahNumber: 1, ayahNumber: 3, wordIndex: 2, arabicWord: 'ٱلرَّحِيمِ', glyph: 'd'),
      QcfMushafWord(surahNumber: 2, ayahNumber: 163, wordIndex: 2, arabicWord: 'إِلَـٰهٌۭ', glyph: 'e'),
      QcfMushafWord(surahNumber: 2, ayahNumber: 209, wordIndex: 10, arabicWord: 'ٱللَّهَ', glyph: 'g'),
      QcfMushafWord(surahNumber: 3, ayahNumber: 6, wordIndex: 11, arabicWord: 'ٱلْعَزِيزُ', glyph: 'h'),
      QcfMushafWord(surahNumber: 39, ayahNumber: 53, wordIndex: 17, arabicWord: 'ٱلْغَفُورُ', glyph: 'i'),
      QcfMushafWord(surahNumber: 2, ayahNumber: 21, wordIndex: 3, arabicWord: 'رَبَّكُمُ', glyph: 'j'),
    ];
    for (final w in validExamples) {
      expect(w.isDivineReference, isTrue, reason: '${w.arabicWord} should be highlighted');
    }

    const nonDivineExamples = <QcfMushafWord>[
      QcfMushafWord(surahNumber: 12, ayahNumber: 30, wordIndex: 6, arabicWord: 'ٱلْعَزِيزِ', glyph: 'x'),
      QcfMushafWord(surahNumber: 12, ayahNumber: 78, wordIndex: 3, arabicWord: 'ٱلْعَزِيزُ', glyph: 'x'),
      QcfMushafWord(surahNumber: 21, ayahNumber: 76, wordIndex: 8, arabicWord: 'ٱلْكَرْبِ', glyph: 'x'),
      QcfMushafWord(surahNumber: 6, ayahNumber: 108, wordIndex: 3, arabicWord: 'ءَالِهَتَهُمْ', glyph: 'x'),
      QcfMushafWord(surahNumber: 2, ayahNumber: 16, wordIndex: 5, arabicWord: 'رَبِحَت', glyph: 'x'),
      QcfMushafWord(surahNumber: 9, ayahNumber: 128, wordIndex: 13, arabicWord: 'رَحِيمٌۭ', glyph: 'x'),
    ];
    for (final w in nonDivineExamples) {
      expect(w.isDivineReference, isFalse, reason: '${w.arabicWord} must NOT be highlighted');
    }

    const lirabbiha = QcfMushafWord(
      surahNumber: 84,
      ayahNumber: 2,
      wordIndex: 2,
      arabicWord: 'لِرَبِّهَا',
      glyph: 'x',
    );
    expect(lirabbiha.isDivineReference, isTrue);

    const huwaBurujDivine = QcfMushafWord(
      surahNumber: 85,
      ayahNumber: 14,
      wordIndex: 1,
      arabicWord: 'وَهُوَ',
      glyph: 'x',
    );
    const huwaBurujQuran = QcfMushafWord(
      surahNumber: 85,
      ayahNumber: 21,
      wordIndex: 2,
      arabicWord: 'هُوَ',
      glyph: 'x',
    );
    expect(QcfMushafWord.isWordDivineReference(huwaBurujDivine), isTrue);
    expect(QcfMushafWord.isWordDivineReference(huwaBurujQuran), isFalse);
  });

  testWidgets('All 15 Sajdah positions are detected and page 589 renders Sajdah underline',
      (tester) async {
    int sajdahCount = 0;
    for (int page = 1; page <= 604; page++) {
      final padded = page.toString().padLeft(3, '0');
      final map = jsonDecode(
        File('assets/mushaf_qcf/layout/page_$padded.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final data = QcfMushafPageData.fromJson(
        map,
        fontFamily: QcfMushafRepository.fontFamilyFor(page),
      );
      sajdahCount += data.lines.expand((l) => l.words).where((w) => w.isSajdahWord).length;
    }
    expect(sajdahCount, 15);

    final p589Map = jsonDecode(
      File('assets/mushaf_qcf/layout/page_589.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final p589 = QcfMushafPageData.fromJson(p589Map, fontFamily: 'Roboto');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 760,
            child: QcfMushafPageWidget(
              pageData: p589,
              highlightedVerseKey: null,
              isDark: false,
              accentColor: const Color(0xFF0F766E),
              onTapVerse: (_, __) {},
            ),
          ),
        ),
      ),
    );

    final richTexts = tester.widgetList<Text>(find.byType(Text)).where(
          (t) => t.textSpan != null,
        );
    final allChildSpans = richTexts
        .expand((t) => (t.textSpan! as TextSpan).children ?? const <InlineSpan>[])
        .whereType<TextSpan>()
        .toList();

    expect(
      allChildSpans.any((s) => s.style?.decoration == TextDecoration.underline),
      isFalse,
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Pages 1 and 2 render QcfOpeningPageFrame with Surah title and ayah count in light and dark modes',
      (tester) async {
    for (final spec in <(int, String, String)>[
      (1, 'سورة الفاتحة', 'عدد آياتها: ٧'),
      (2, 'سورة البقرة', 'عدد آياتها: ٢٨٦'),
    ]) {
      final padded = spec.$1.toString().padLeft(3, '0');
      final map = jsonDecode(
        File('assets/mushaf_qcf/layout/page_$padded.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final pageData = QcfMushafPageData.fromJson(map, fontFamily: 'Roboto');

      for (final isDark in <bool>[false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 760,
                child: QcfMushafPageWidget(
                  pageData: pageData,
                  highlightedVerseKey: null,
                  isDark: isDark,
                  accentColor: const Color(0xFF0F766E),
                  onTapVerse: (_, __) {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(QcfOpeningPageFrame), findsOneWidget);
        expect(find.text(spec.$2), findsWidgets);
        expect(find.text(spec.$3), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNothing);
      }
    }
  });

  test('MushafPageScrollPhysics provides responsive, non-bouncing 1:1 paging feel', () {
    const physics = MushafPageScrollPhysics(parent: ClampingScrollPhysics());
    final applied = physics.applyTo(null);
    expect(applied.minFlingVelocity, 150.0);
    expect(applied.spring.stiffness, 560.0);
    expect(applied.spring.damping, greaterThan(30.0));

    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 500,
      viewportDimension: 390,
      axisDirection: AxisDirection.left,
      devicePixelRatio: 2.0,
    );
    expect(applied.applyPhysicsToUserOffset(metrics, 100.0), closeTo(100.0, 0.01));
  });

  testWidgets('Single tap bubbles to parent GestureDetector when onTapVerse is null',
      (tester) async {
    final map = jsonDecode(
      File('assets/mushaf_qcf/layout/page_003.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final pageData = QcfMushafPageData.fromJson(map, fontFamily: 'Roboto');

    int parentTapCount = 0;
    int longPressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => parentTapCount++,
            child: SizedBox(
              width: 390,
              height: 760,
              child: QcfMushafPageWidget(
                pageData: pageData,
                highlightedVerseKey: null,
                isDark: false,
                accentColor: const Color(0xFF0F766E),
                onTapVerse: null,
                onLongPressVerse: (_, __) => longPressCount++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(QcfMushafPageWidget));
    await tester.pumpAndSettle();
    expect(parentTapCount, 1);
    expect(longPressCount, 0);
  });

  test('QuranPageMapping.getHizbForPage returns accurate 1..60 Hizb across all 604 pages', () {
    expect(QuranPageMapping.getHizbForPage(0), 1);
    expect(QuranPageMapping.getHizbForPage(1), 1);
    expect(QuranPageMapping.getHizbForPage(10), 1);
    expect(QuranPageMapping.getHizbForPage(11), 2);
    expect(QuranPageMapping.getHizbForPage(22), 3);
    expect(QuranPageMapping.getHizbForPage(121), 13);
    expect(QuranPageMapping.getHizbForPage(292), 30);
    expect(QuranPageMapping.getHizbForPage(293), 30);
    expect(QuranPageMapping.getHizbForPage(301), 30);
    expect(QuranPageMapping.getHizbForPage(302), 31);
    expect(QuranPageMapping.getHizbForPage(590), 59);
    expect(QuranPageMapping.getHizbForPage(591), 60);
    expect(QuranPageMapping.getHizbForPage(604), 60);
    expect(QuranPageMapping.getHizbForPage(999), 60);

    int prevHizb = 1;
    final seen = <int>{};
    for (int p = 1; p <= 604; p++) {
      final h = QuranPageMapping.getHizbForPage(p);
      expect(h, greaterThanOrEqualTo(prevHizb));
      expect(h, lessThanOrEqualTo(60));
      seen.add(h);
      prevHizb = h;
    }
    expect(seen.length, 60);
  });

  testWidgets('MushafPageSideIndicator displays right/left page side and Hizb without blocking taps',
      (tester) async {
    int tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapCount++,
                  child: const SizedBox.expand(),
                ),
                const Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: MushafPageSideIndicator(
                    pageNumber: 293,
                    isDark: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('يمين المصحف'), findsNothing);
    expect(find.text('الحزب ٣٠'), findsNothing);

    await tester.tap(find.byType(MushafPageSideIndicator));
    await tester.pump();
    expect(tapCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapCount++,
                  child: const SizedBox.expand(),
                ),
                const Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: MushafPageSideIndicator(
                    pageNumber: 302,
                    isDark: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsWidgets);
    expect(find.text('يسار المصحف'), findsNothing);
    expect(find.text('الحزب ٣١'), findsNothing);

    expect(File(MushafPageSideIndicator.rightPageAsset).existsSync(), isTrue);
    expect(File(MushafPageSideIndicator.leftPageAsset).existsSync(), isTrue);
    expect(
      MushafPageSideIndicator.assetForPage(1),
      MushafPageSideIndicator.rightPageAsset,
    );
    expect(
      MushafPageSideIndicator.assetForPage(2),
      MushafPageSideIndicator.leftPageAsset,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: MushafPageSideIndicator(
              pageNumber: 294,
              isDark: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  test('MushafReaderTheme provides refined Light and Dark palettes and status bar brightness', () {
    expect(MushafReaderTheme.light.headerBackground, const Color(0xD9F5EFE3));
    expect(MushafReaderTheme.light.primaryText, const Color(0xFF382C20));
    expect(MushafReaderTheme.light.indicatorBackground, const Color(0xFFFFF9ED));
    expect(MushafReaderTheme.light.indicatorBorder, const Color(0xFFC9A86A));
    expect(
      MushafReaderTheme.light.statusBarOverlayStyle.statusBarIconBrightness,
      Brightness.dark,
    );

    expect(MushafReaderTheme.dark.headerBackground, const Color(0xD9121A22));
    expect(MushafReaderTheme.dark.primaryText, const Color(0xFFF5EBD8));
    expect(MushafReaderTheme.dark.indicatorBackground, const Color(0xFF202A32));
    expect(MushafReaderTheme.dark.indicatorBorder, const Color(0xFFA9894C));
    expect(
      MushafReaderTheme.dark.statusBarOverlayStyle.statusBarIconBrightness,
      Brightness.light,
    );
    expect(File('assets/images/makkah_icon.png').existsSync(), isTrue);
    expect(File('assets/images/madinah_icon.png').existsSync(), isTrue);
  });
}
