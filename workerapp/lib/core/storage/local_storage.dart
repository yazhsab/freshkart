import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get workerId => _prefs.getString('worker_id');
  static set workerId(String? value) {
    if (value != null) {
      _prefs.setString('worker_id', value);
    } else {
      _prefs.remove('worker_id');
    }
  }

  static bool get isAvailable => _prefs.getBool('is_available') ?? false;
  static set isAvailable(bool value) => _prefs.setBool('is_available', value);

  static String? get jobStartTime => _prefs.getString('job_start_time');
  static set jobStartTime(String? value) {
    if (value != null) {
      _prefs.setString('job_start_time', value);
    } else {
      _prefs.remove('job_start_time');
    }
  }

  static String? get activeBookingId => _prefs.getString('active_booking_id');
  static set activeBookingId(String? value) {
    if (value != null) {
      _prefs.setString('active_booking_id', value);
    } else {
      _prefs.remove('active_booking_id');
    }
  }

  static String? get fcmToken => _prefs.getString('fcm_token');
  static set fcmToken(String? value) {
    if (value != null) {
      _prefs.setString('fcm_token', value);
    } else {
      _prefs.remove('fcm_token');
    }
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }
}
