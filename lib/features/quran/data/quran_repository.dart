import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';

class QuranRepository {
  static List<dynamic>? _quranJsonData;
  static final Map<int, String> _surahTextCache = {};

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
}
