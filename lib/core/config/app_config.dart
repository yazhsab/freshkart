class AppConfig {
  AppConfig._();

  // App info
  static const String appName = 'FreshKart';
  static const String currencySymbol = '₹';
  static const String defaultCity = 'Chennai';
  static const String defaultState = 'Tamil Nadu';
  static const String countryCode = '+91';

  // Delivery
  static const double deliveryFeeThreshold = 299.0;
  static const double deliveryFee = 30.0;
  static const double defaultDeliveryRadiusKm = 5.0;

  // Services
  static const double bookingFee = 99.0;

  // Cart
  static const int maxCartItemsPerProduct = 10;

  // OTP
  static const int otpLength = 6;
  static const int otpTimeoutSeconds = 30;

  // Search
  static const int searchDebounceMs = 300;

  // Pagination
  static const int defaultPageSize = 20;

  // Image
  static const double productImageSize = 120.0;
  static const double categoryImageSize = 64.0;

  // Map
  static const double defaultLatitude = 13.0827;
  static const double defaultLongitude = 80.2707;
}
