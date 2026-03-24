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

  // Map — Tamil Nadu center (Chennai)
  static const double defaultLatitude = 13.0827;
  static const double defaultLongitude = 80.2707;

  // Tamil Nadu center (for state-wide view)
  static const double tnCenterLatitude = 10.8505;
  static const double tnCenterLongitude = 78.2711;

  // Wallet
  static const double maxWalletBalance = 10000.0;
  static const double maxTopupAmount = 10000.0;

  // Loyalty
  static const int minRedeemPoints = 50;
  static const double pointValueInr = 1.0;

  // Referral
  static const double referrerReward = 50.0;
  static const double refereeReward = 25.0;

  // Scheduled orders
  static const int minScheduleHoursAhead = 2;
  static const int maxScheduleDaysAhead = 7;

  // Supported locales
  static const String defaultLocale = 'en';
  static const List<String> supportedLocales = ['en', 'ta'];

  // Tamil Nadu only
  static const String operatingState = 'Tamil Nadu';
  static const String operatingStateTamil = 'தமிழ்நாடு';
}
