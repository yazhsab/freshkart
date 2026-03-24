import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Provides static helpers for obtaining the device location and
/// reverse-geocoding coordinates via the backend.
class LocationService {
  LocationService._();

  /// Attempts to get the current device position.
  ///
  /// Returns `null` when location services are disabled or the user
  /// has denied permission (both normal and permanent denial).
  static Future<Position?> getCurrentPosition() async {
    // 1. Check if location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services are disabled.');
      return null;
    }

    // 2. Check / request permission.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Location permission denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'LocationService: Location permission permanently denied. '
        'User must enable it from app settings.',
      );
      return null;
    }

    // 3. Fetch position.
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting position – $e');
      return null;
    }
  }

  /// Calls the backend reverse-geocode endpoint to convert lat/lng
  /// into a human-readable address string.
  static Future<String> getAddressFromCoords(double lat, double lng) async {
    try {
      final response = await ApiClient().get(
        ApiEndpoints.reverseGeocode,
        queryParameters: {'lat': lat, 'lng': lng},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['address'] as String?) ??
            (data['formatted_address'] as String?) ??
            'Unknown location';
      }

      return 'Unknown location';
    } catch (e) {
      debugPrint('LocationService: Reverse geocode failed – $e');
      return 'Unknown location';
    }
  }
}
