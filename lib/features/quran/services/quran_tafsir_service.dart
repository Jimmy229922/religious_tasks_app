import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:religious_tasks_app/core/services/storage_service.dart';

enum QuranTafsirSource {
  muyassar(
    'التفسير الميسر',
    'مجمع الملك فهد لطباعة المصحف الشريف',
    'ar-tafsir-muyassar',
  ),
  saadi(
    'تفسير السعدي',
    'تيسير الكريم الرحمن للعلامة عبد الرحمن السعدي',
    'ar-tafsir-as-saadi',
  );

  final String label;
  final String referenceName;
  final String cdnSlug;
  const QuranTafsirSource(this.label, this.referenceName, this.cdnSlug);
}

class QuranTafsirResult {
  final String text;
  final String sourceName;
  final bool fromCache;

  const QuranTafsirResult({
    required this.text,
    required this.sourceName,
    this.fromCache = false,
  });
}

class QuranTafsirService {
  static const String _cachePrefix = 'quran_tafsir_v1_';
  static Map<QuranTafsirSource, int>? _resolvedTafseerIds;

  static Future<Map<QuranTafsirSource, int>> _getTafseerIds() async {
    if (_resolvedTafseerIds != null) return _resolvedTafseerIds!;

    final defaults = <QuranTafsirSource, int>{
      QuranTafsirSource.muyassar: 1,
      QuranTafsirSource.saadi: 3,
    };

    try {
      final response = await http
          .get(Uri.parse('https://api.quran-tafseer.com/tafseer/'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          for (final item in decoded.whereType<Map>()) {
            final id = item['id'];
            final name = item['name']?.toString() ?? '';
            if (id is int) {
              if (name.contains('الميسر')) {
                defaults[QuranTafsirSource.muyassar] = id;
              } else if (name.contains('السعدي')) {
                defaults[QuranTafsirSource.saadi] = id;
              }
            }
          }
        }
      }
    } catch (_) {}

    _resolvedTafseerIds = defaults;
    return defaults;
  }

  static Future<QuranTafsirResult?> fetchAyahTafsir({
    required int surahNumber,
    required int ayahNumber,
    required QuranTafsirSource source,
  }) async {
    final cacheKey = '$_cachePrefix${source.name}_${surahNumber}_$ayahNumber';
    try {
      final cached = StorageService.instance.getString(cacheKey);
      if (cached != null && cached.trim().isNotEmpty) {
        return QuranTafsirResult(
          text: cached.trim(),
          sourceName: source.referenceName,
          fromCache: true,
        );
      }
    } catch (_) {}

    try {
      final cdnUrl = Uri.parse(
        'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/${source.cdnSlug}/$surahNumber/$ayahNumber.json',
      );
      final cdnResponse =
          await http.get(cdnUrl).timeout(const Duration(seconds: 8));
      if (cdnResponse.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(cdnResponse.bodyBytes));
        final rawText = decoded is Map ? (decoded['text']?.toString() ?? '') : '';
        final cleaned = _cleanHtmlText(rawText);
        if (cleaned.isNotEmpty) {
          try {
            await StorageService.instance.setString(cacheKey, cleaned);
          } catch (_) {}
          return QuranTafsirResult(
            text: cleaned,
            sourceName: source.referenceName,
          );
        }
      }
    } catch (_) {}

    try {
      final ids = await _getTafseerIds();
      final tafseerId = ids[source] ?? 1;
      final url = Uri.parse(
        'https://api.quran-tafseer.com/tafseer/$tafseerId/$surahNumber/$ayahNumber',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final rawText = decoded is Map ? (decoded['text']?.toString() ?? '') : '';
        final cleaned = _cleanHtmlText(rawText);
        if (cleaned.isNotEmpty) {
          try {
            await StorageService.instance.setString(cacheKey, cleaned);
          } catch (_) {}
          return QuranTafsirResult(
            text: cleaned,
            sourceName: source.referenceName,
          );
        }
      }
    } catch (_) {}

    if (source == QuranTafsirSource.muyassar) {
      return _fetchFromQuranComFallback(surahNumber, ayahNumber, cacheKey, source);
    }
    return null;
  }

  static Future<QuranTafsirResult?> _fetchFromQuranComFallback(
    int surahNumber,
    int ayahNumber,
    String cacheKey,
    QuranTafsirSource source,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/16/by_ayah/$surahNumber:$ayahNumber',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final tafsirMap = decoded is Map ? decoded['tafsir'] : null;
        final rawText = tafsirMap is Map ? (tafsirMap['text']?.toString() ?? '') : '';
        final cleaned = _cleanHtmlText(rawText);
        if (cleaned.isNotEmpty) {
          try {
            await StorageService.instance.setString(cacheKey, cleaned);
          } catch (_) {}
          return QuranTafsirResult(
            text: cleaned,
            sourceName: source.referenceName,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  static String _cleanHtmlText(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
