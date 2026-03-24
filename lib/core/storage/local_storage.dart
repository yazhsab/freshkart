import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] providing typed static helpers
/// and convenience methods for session management.
class LocalStorage {
  LocalStorage._();

  static late SharedPreferences _prefs;

  // -------------------------------------------------------------------------
  // Key constants
  // -------------------------------------------------------------------------
  static const kAuthToken = 'auth_token';
  static const kRefreshToken = 'refresh_token';
  static const kUserId = 'user_id';
  static const kUserRole = 'user_role';
  static const kUserPhone = 'user_phone';
  static const kOnboardingDone = 'onboarding_done';
  static const kSavedLat = 'saved_lat';
  static const kSavedLng = 'saved_lng';
  static const kSavedCity = 'saved_city';
  static const kCartData = 'cart_data';
  static const kRecentSearches = 'recent_searches';

  // -------------------------------------------------------------------------
  // Initialization
  // -------------------------------------------------------------------------

  /// Must be called once before any other method (typically in `main()`).
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // -------------------------------------------------------------------------
  // Generic getters / setters
  // -------------------------------------------------------------------------

  static String? getString(String key) => _prefs.getString(key);

  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  static bool? getBool(String key) => _prefs.getBool(key);

  static Future<bool> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  static double? getDouble(String key) => _prefs.getDouble(key);

  static Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  static Future<bool> remove(String key) => _prefs.remove(key);

  static Future<bool> clear() => _prefs.clear();

  // -------------------------------------------------------------------------
  // Session helpers
  // -------------------------------------------------------------------------

  /// Persists all session-related fields after a successful login.
  static Future<void> saveSession({
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

  /// Removes all session-related fields (logout).
  static Future<void> clearSession() async {
    await Future.wait([
      remove(kAuthToken),
      remove(kRefreshToken),
      remove(kUserId),
      remove(kUserRole),
      remove(kUserPhone),
    ]);
  }

  /// Returns `true` when a valid auth token is stored.
  static bool isLoggedIn() {
    final token = getString(kAuthToken);
    return token != null && token.isNotEmpty;
  }

  /// Returns the stored JWT token, or `null` if not logged in.
  static String? getToken() => getString(kAuthToken);
}
