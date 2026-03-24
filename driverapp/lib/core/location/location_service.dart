import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  LocationService._();

  static Future<bool> initialize() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await initialize();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return distanceInMeters / 1000.0;
  }

  static String getGoogleMapsUrl(double destLat, double destLng) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&destination=$destLat,$destLng'
        '&travelmode=driving'
        '&dir_action=navigate';
  }

  static String getOlaMapsUrl(double destLat, double destLng) {
    return 'https://maps.olacabs.com/?'
        'dlat=$destLat&dlng=$destLng'
        '&drop_type=recent';
  }
}
