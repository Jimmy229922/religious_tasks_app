import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';

class NearbyMosque {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double bearingDeg;
  final String address;

  const NearbyMosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.bearingDeg,
    this.address = '',
  });

  String get formattedDistanceArabic {
    if (distanceMeters < 1000) {
      final meters = distanceMeters.round();
      return '${QuranTextFormatter.toArabicDigits(meters.toString())} م';
    }
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    return '${QuranTextFormatter.toArabicDigits(km)} كم';
  }

  String get walkingTimeArabic {
    final minutes = (distanceMeters / 75.0).ceil().clamp(1, 180);
    return '${QuranTextFormatter.toArabicDigits(minutes.toString())} د مشي';
  }

  String get drivingTimeArabic {
    final minutes = (distanceMeters / 450.0).ceil().clamp(1, 90);
    return '${QuranTextFormatter.toArabicDigits(minutes.toString())} د بالسيارة';
  }

  String get cardinalDirectionArabic {
    final deg = ((bearingDeg % 360) + 360) % 360;
    const dirs = [
      'الشمال',
      'الشمال الشرقي',
      'الشرق',
      'الجنوب الشرقي',
      'الجنوب',
      'الجنوب الغربي',
      'الغرب',
      'الشمال الغربي',
    ];
    final idx = ((deg + 22.5) / 45.0).floor() % 8;
    return dirs[idx];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'address': address,
      };

  static NearbyMosque fromCachedJson(
    Map<String, dynamic> json,
    double userLat,
    double userLng,
  ) {
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    return NearbyMosque(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'مسجد').toString(),
      latitude: lat,
      longitude: lng,
      distanceMeters: Geolocator.distanceBetween(userLat, userLng, lat, lng),
      bearingDeg: _computeBearing(userLat, userLng, lat, lng),
      address: (json['address'] ?? '').toString(),
    );
  }

  static double _computeBearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final dLambda = (lng2 - lng1) * math.pi / 180.0;
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return ((math.atan2(y, x) * 180.0 / math.pi) + 360.0) % 360.0;
  }
}

class NearbyMosquesService {
  static const String _cacheKey = 'nearby_mosques_cache_v1';
  static const List<String> _overpassEndpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
  ];

  Future<List<NearbyMosque>> loadCachedMosques({
    required double userLat,
    required double userLng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      final list = decoded['items'];
      if (list is! List) return const [];
      final mosques = list
          .whereType<Map<String, dynamic>>()
          .map((m) => NearbyMosque.fromCachedJson(m, userLat, userLng))
          .toList();
      mosques.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return mosques;
    } catch (_) {
      return const [];
    }
  }

  Future<List<NearbyMosque>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
  }) async {
    final query = '''
[out:json][timeout:12];
(
  nw["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nw["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
);
out center 100;
''';

    Object? lastError;
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'RafeeqAlMuslimApp/1.0',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 14));

        if (response.statusCode != 200) {
          lastError = Exception('HTTP ${response.statusCode}');
          continue;
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final elements = (decoded['elements'] as List?) ?? const [];
        final seenIds = <String>{};
        final mosques = <NearbyMosque>[];

        for (final el in elements) {
          if (el is! Map) continue;
          final rawId = '${el['type']}_${el['id']}';
          if (!seenIds.add(rawId)) continue;

          final center = el['center'];
          final double? lat = (el['lat'] as num?)?.toDouble() ??
              (center is Map ? (center['lat'] as num?)?.toDouble() : null);
          final double? lng = (el['lon'] as num?)?.toDouble() ??
              (center is Map ? (center['lon'] as num?)?.toDouble() : null);
          if (lat == null || lng == null) continue;

          final tags = (el['tags'] as Map?) ?? const {};
          final name = (tags['name:ar'] ??
                  tags['name'] ??
                  tags['official_name:ar'] ??
                  tags['alt_name'] ??
                  'مسجد قريب')
              .toString()
              .trim();
          final street = (tags['addr:street'] ?? '').toString().trim();
          final district =
              (tags['addr:district'] ?? tags['addr:suburb'] ?? '')
                  .toString()
                  .trim();
          final address = [street, district]
              .where((part) => part.isNotEmpty)
              .join(' - ');

          final distance =
              Geolocator.distanceBetween(latitude, longitude, lat, lng);
          final bearing =
              NearbyMosque._computeBearing(latitude, longitude, lat, lng);

          final resolvedName = name.isEmpty ? 'مسجد قريب' : name;
          final duplicateIdx = mosques.indexWhere(
            (existing) =>
                Geolocator.distanceBetween(
                  existing.latitude,
                  existing.longitude,
                  lat,
                  lng,
                ) <
                20.0,
          );
          if (duplicateIdx != -1) {
            if (mosques[duplicateIdx].name == 'مسجد قريب' &&
                resolvedName != 'مسجد قريب') {
              mosques[duplicateIdx] = NearbyMosque(
                id: rawId,
                name: resolvedName,
                latitude: lat,
                longitude: lng,
                distanceMeters: distance,
                bearingDeg: bearing,
                address: address,
              );
            }
            continue;
          }

          mosques.add(
            NearbyMosque(
              id: rawId,
              name: resolvedName,
              latitude: lat,
              longitude: lng,
              distanceMeters: distance,
              bearingDeg: bearing,
              address: address,
            ),
          );
        }

        mosques.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        await _saveCache(mosques);
        return mosques;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    return const [];
  }

  Future<void> _saveCache(List<NearbyMosque> mosques) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': mosques.take(40).map((m) => m.toJson()).toList(),
      };
      await prefs.setString(_cacheKey, jsonEncode(payload));
    } catch (_) {}
  }
}
