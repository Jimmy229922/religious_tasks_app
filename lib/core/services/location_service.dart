import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/strings.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Fetches a fresh high-accuracy GPS fix for Qibla precision without
  /// relying on stale 24-hour cached positions.
  Future<({Position? position, String message})> getHighAccuracyPosition({
    bool requestPermission = false,
  }) async {
    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (requestPermission) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        if (!serviceEnabled) {
          return (position: null, message: AppStrings.enableLocationService);
        }
      }

      var status = await Permission.location.status;
      if (status.isDenied && requestPermission) {
        status = await Permission.location.request();
      }
      if (status.isDenied) {
        return (position: null, message: AppStrings.locationDenied);
      }
      if (status.isPermanentlyDenied) {
        return (position: null, message: AppStrings.locationDeniedForever);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        return (position: position, message: '');
      } catch (e) {
        debugPrint("High accuracy location fetch error: $e");
        final cached = await Geolocator.getLastKnownPosition();
        if (cached != null) {
          return (position: cached, message: '');
        }
        return (position: null, message: AppStrings.locationError);
      }
    } catch (e) {
      debugPrint("Error getting high accuracy location: $e");
      return (position: null, message: AppStrings.locationError);
    }
  }

  /// Returns the current position or null if failed/denied.
  /// Also returns a status message.
  Future<({Position? position, String message})> getCurrentPosition({
    bool requestPermission = false,
  }) async {
    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (requestPermission) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        if (!serviceEnabled) {
          return (position: null, message: AppStrings.enableLocationService);
        }
      }

      var status = await Permission.location.status;
      if (status.isDenied && requestPermission) {
        status = await Permission.location.request();
      }
      if (status.isDenied) {
        return (position: null, message: AppStrings.locationDenied);
      }
      if (status.isPermanentlyDenied) {
        return (position: null, message: AppStrings.locationDeniedForever);
      }

      // Try cached first
      final cached = await Geolocator.getLastKnownPosition();

      final cachedIsRecent = cached != null &&
          DateTime.now().difference(cached.timestamp).abs() <=
              const Duration(hours: 24);
      if (cachedIsRecent) {
        return (position: cached, message: '');
      }

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
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final parts = <String>[];

        if (place.country?.isNotEmpty == true) {
          parts.add(place.country!);
        }

        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }

        if (place.locality?.isNotEmpty == true) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea?.isNotEmpty == true) {
          parts.add(place.subAdministrativeArea!);
        }

        final uniqueParts = parts.toSet().toList();
        final clean =
            uniqueParts.where((e) => e.trim().isNotEmpty).join("، ").trim();

        return clean.isNotEmpty ? clean : AppStrings.unknownLocation;
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return AppStrings.unknownLocation;
  }

  /// Returns the ISO country code (e.g., "EG", "SA")
  Future<String?> getCountryCode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        return placemarks[0].isoCountryCode;
      }
    } catch (e) {
      debugPrint("Error getting country code: $e");
    }
    return null;
  }
}
