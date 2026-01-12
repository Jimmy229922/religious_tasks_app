import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/strings.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Returns the current position or null if failed/denied.
  /// Also returns a status message.
  Future<({Position? position, String message})> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (position: null, message: AppStrings.enableLocationService);
      }

      final status = await Permission.location.request();
      if (status.isDenied) {
        return (position: null, message: AppStrings.locationDenied);
      }
      if (status.isPermanentlyDenied) {
        return (position: null, message: AppStrings.locationDeniedForever);
      }

      // Try cached first
      final cached = await Geolocator.getLastKnownPosition();

      // If cached is available, check if it is recent enough (e.g. within 24 hours)
      // or just return it immediately to speed up the app significantly.
      // For Prayer App, city-level accuracy is fine, so 500 meters or even a few km is okay.
      if (cached != null) {
        // Return cached immediately if we have it, then we can update quietly if needed.
        return (position: cached, message: '');
      }

      // If no cached location, we MUST fetch fresh.
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy:
                LocationAccuracy.low, // Changed from medium to low for speed
            timeLimit: Duration(seconds: 10),
          ),
        );
        return (position: position, message: '');
      } catch (e) {
        debugPrint("Location fetch error: $e");
        if (cached != null) {
          return (position: cached, message: '');
        }
        return (position: null, message: AppStrings.locationError);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      return (position: null, message: AppStrings.locationError);
    }
  }

  Future<String> getLocationName(Position position) async {
    try {
      // NOTE: localeIdentifier parameter might not be supported in some versions of geocoding package.
      // If removed, it will use the system or device locale.
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final parts = <String>[];

        // Hierarchical Address for Professional Look:
        // Country -> Administrative Area (Gov) -> Locality (City) -> SubLocality (Neighborhood)

        // 1. Country (e.g. مصر)
        if (place.country?.isNotEmpty == true) {
          parts.add(place.country!);
        }

        // 2. Governorate (e.g. محافظة القاهرة)
        // We prefer AdministrativeArea.
        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }

        // 3. City/District (e.g. مدينة نصر)
        // Locality is usually the city. SubAdministrativeArea is sometimes equivalent.
        if (place.locality?.isNotEmpty == true) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea?.isNotEmpty == true) {
          parts.add(place.subAdministrativeArea!);
        }

        // Construct the full string
        final uniqueParts = parts.toSet().toList();

        // Join with comma for a classic address format
        final clean =
            uniqueParts.where((e) => e.trim().isNotEmpty).join("، ").trim();

        return clean.isNotEmpty ? clean : AppStrings.unknownLocation;
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return AppStrings.unknownLocation;
  }
}
