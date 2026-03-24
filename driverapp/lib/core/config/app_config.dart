class DeliveryAppConfig {
  DeliveryAppConfig._();

  static const String appName = 'FreshKart Delivery';
  static const String currency = '\u20B9';

  // API & Supabase from environment
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Delivery fee settings
  static const double baseDeliveryFee = 30.0;
  static const double peakHourBonus = 10.0;
  static const double longDistanceBonusPerKm = 5.0;
  static const double longDistanceThresholdKm = 5.0;

  // Order settings
  static const int orderAcceptTimeoutSeconds = 15;
  static const int deliveryOtpLength = 4;

  // Location tracking
  static const int locationUpdateIntervalSeconds = 5;
  static const int locationDistanceFilterMeters = 10;

  // Peak hours (24h format)
  static const List<int> peakHoursStart = [11, 18];
  static const List<int> peakHoursEnd = [14, 22];

  static bool isPeakHour() {
    final now = DateTime.now().hour;
    for (int i = 0; i < peakHoursStart.length; i++) {
      if (now >= peakHoursStart[i] && now < peakHoursEnd[i]) {
        return true;
      }
    }
    return false;
  }

  static double calculateDeliveryFee(double distanceKm) {
    double fee = baseDeliveryFee;
    if (isPeakHour()) {
      fee += peakHourBonus;
    }
    if (distanceKm > longDistanceThresholdKm) {
      fee += (distanceKm - longDistanceThresholdKm) * longDistanceBonusPerKm;
    }
    return fee;
  }
}
