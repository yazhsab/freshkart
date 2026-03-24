import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._internal();

  static final LocalStorage _instance = LocalStorage._internal();
  static LocalStorage get instance => _instance;

  late SharedPreferences _prefs;

  // Keys
  static const String kAuthToken = 'auth_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId = 'user_id';
  static const String kUserRole = 'user_role';
  static const String kUserPhone = 'user_phone';
  static const String kVendorId = 'vendor_id';
  static const String kVendorData = 'vendor_data';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kShopOpen = 'shop_open';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  // Bool
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  // Remove
  Future<bool> remove(String key) => _prefs.remove(key);

  // Session management
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userId,
    required String role,
    required String phone,
  }) async {
    await Future.wait([
      setString(kAuthToken, token),
      setString(kRefreshToken, refreshToken),
      setString(kUserId, userId),
      setString(kUserRole, role),
      setString(kUserPhone, phone),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      remove(kAuthToken),
      remove(kRefreshToken),
      remove(kUserId),
      remove(kUserRole),
      remove(kUserPhone),
      remove(kVendorId),
      remove(kVendorData),
    ]);
  }

  bool get isLoggedIn {
    final token = getString(kAuthToken);
    return token != null && token.isNotEmpty;
  }

  String? getToken() => getString(kAuthToken);

  Future<void> saveVendorId(String id) => setString(kVendorId, id);

  String? getVendorId() => getString(kVendorId);
}
