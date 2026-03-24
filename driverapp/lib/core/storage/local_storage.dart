import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception(
        'LocalStorage not initialized. Call LocalStorage.initialize() first.',
      );
    }
    return _prefs!;
  }

  // Keys
  static const String _keyUserId = 'user_id';
  static const String _keyAgentId = 'agent_id';
  static const String _keyAgentName = 'agent_name';
  static const String _keyVehicleType = 'vehicle_type';
  static const String _keyIsOnline = 'is_online';
  static const String _keyPreferredMapsApp = 'preferred_maps_app';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyOnboardingComplete = 'onboarding_complete';

  // User ID
  static String? get userId => _instance.getString(_keyUserId);
  static Future<bool> setUserId(String value) =>
      _instance.setString(_keyUserId, value);

  // Agent ID
  static String? get agentId => _instance.getString(_keyAgentId);
  static Future<bool> setAgentId(String value) =>
      _instance.setString(_keyAgentId, value);

  // Agent Name
  static String? get agentName => _instance.getString(_keyAgentName);
  static Future<bool> setAgentName(String value) =>
      _instance.setString(_keyAgentName, value);

  // Vehicle Type
  static String? get vehicleType => _instance.getString(_keyVehicleType);
  static Future<bool> setVehicleType(String value) =>
      _instance.setString(_keyVehicleType, value);

  // Is Online
  static bool get isOnline => _instance.getBool(_keyIsOnline) ?? false;
  static Future<bool> setIsOnline(bool value) =>
      _instance.setBool(_keyIsOnline, value);

  // Preferred Maps App
  static String get preferredMapsApp =>
      _instance.getString(_keyPreferredMapsApp) ?? 'google';
  static Future<bool> setPreferredMapsApp(String value) =>
      _instance.setString(_keyPreferredMapsApp, value);

  // Auth Token
  static String? get authToken => _instance.getString(_keyAuthToken);
  static Future<bool> setAuthToken(String value) =>
      _instance.setString(_keyAuthToken, value);
  static Future<bool> removeAuthToken() => _instance.remove(_keyAuthToken);

  // Onboarding Complete
  static bool get onboardingComplete =>
      _instance.getBool(_keyOnboardingComplete) ?? false;
  static Future<bool> setOnboardingComplete(bool value) =>
      _instance.setBool(_keyOnboardingComplete, value);

  // Clear all
  static Future<bool> clearAll() => _instance.clear();

  // Check if logged in
  static bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;
}
