class VendorApiEndpoints {
  VendorApiEndpoints._();

  static const String base = '/api/v1';

  // Auth
  static const String sendOtp = '$base/auth/send-otp';
  static const String verifyOtp = '$base/auth/verify-otp';

  // Profile
  static const String profile = '$base/profile';

  // Vendor
  static const String vendorMe = '$base/vendor/me';
  static const String vendorRegister = '$base/vendor/register';
  static const String vendorToggleOpen = '$base/vendor/toggle-open';
  static const String vendorDocs = '$base/vendor/documents';
  static const String vendorOrders = '$base/vendor/orders';

  static String orderById(String id) => '$base/vendor/orders/$id';
  static String orderStatus(String id) => '$base/vendor/orders/$id/status';

  // Products
  static const String products = '$base/vendor/products';

  static String productById(String id) => '$base/vendor/products/$id';
  static String productStock(String id) => '$base/vendor/products/$id/stock';
  static String productAvailability(String id) =>
      '$base/vendor/products/$id/availability';
  static String productImage(String id) => '$base/vendor/products/$id/image';

  // Categories
  static const String groceryCategories = '$base/categories/grocery';

  // Earnings & Payouts
  static const String earnings = '$base/vendor/earnings';
  static const String payoutsVendor = '$base/vendor/payouts';

  // Reviews
  static const String reviewsVendor = '$base/vendor/reviews';

  // FCM
  static const String fcmToken = '$base/fcm-token';
}
