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
      if (cached != null) {
        // Return cached immediately, but maybe the caller wants fresh?
        // Logic in View could be: use cached, then try fresh in background.
        // For simplicity here, we try fresh, if fails, return cached.
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
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
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final parts = <String>[];

        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }
        if (place.locality?.isNotEmpty == true) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea?.isNotEmpty == true) {
          parts.add(place.subAdministrativeArea!);
        }
        if (place.subLocality?.isNotEmpty == true) {
          parts.add(place.subLocality!);
        }

        final uniqueParts = parts.toSet().toList();
        final clean = uniqueParts
            .where((e) => e.trim().isNotEmpty)
            .take(2)
            .join(" - ")
            .trim();

        return clean.isNotEmpty ? clean : AppStrings.unknownLocation;
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return AppStrings.unknownLocation;
  }
}
