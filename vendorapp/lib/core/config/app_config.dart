class VendorAppConfig {
  VendorAppConfig._();

  static const String appName = 'FreshKart Vendor';
  static const String defaultCity = 'Chennai';
  static const String currency = '₹';

  // Order
  static const int orderAutoConfirmSeconds = 60;

  // Inventory
  static const int lowStockThreshold = 5;
  static const int maxProductImageSize = 800;
  static const int imageQuality = 85;
  static const int maxProductsPerVendor = 500;

  // Delivery
  static const double defaultDeliveryRadius = 5.0;

  // Platform
  static const double platformCommissionPct = 10.0;
  static const double bookingFee = 99.0;

  // Default Location (Chennai)
  static const double defaultLat = 13.0827;
  static const double defaultLng = 80.2707;
}
