class ApiEndpoints {
  ApiEndpoints._();
  static const base = '/api/v1';

  // Auth
  static const sendOtp = '$base/auth/send-otp';
  static const verifyOtp = '$base/auth/verify-otp';
  static const profile = '$base/auth/profile';

  // Vendors
  static const nearbyVendors = '$base/vendors/nearby';
  static String vendorById(String id) => '$base/vendors/$id';
  static String vendorProducts(String id) => '$base/vendors/$id/products';

  // Products
  static const searchProducts = '$base/products/search';
  static String productById(String id) => '$base/products/$id';

  // Categories
  static const groceryCategories = '$base/grocery-categories';

  // Orders
  static const createOrder = '$base/orders';
  static const myOrders = '$base/orders';
  static String orderById(String id) => '$base/orders/$id';
  static String cancelOrder(String id) => '$base/orders/$id/cancel';
  static String trackOrder(String id) => '$base/delivery/location/$id';

  // Addresses
  static const addresses = '$base/addresses';
  static String addressById(String id) => '$base/addresses/$id';

  // Payments
  static const razorpayCreateOrder = '$base/payments/razorpay/create-order';
  static const razorpayVerify = '$base/payments/razorpay/verify';
  static const phonepeInitiate = '$base/payments/phonepe/initiate';

  // Bookings
  static const createBooking = '$base/bookings';
  static const myBookings = '$base/bookings';
  static String bookingById(String id) => '$base/bookings/$id';
  static String cancelBooking(String id) => '$base/bookings/$id/cancel';

  // Services
  static const serviceCategories = '$base/services';
  static String availableWorkers(String categoryId) =>
      '$base/workers/available?service_category_id=$categoryId';
  static String availableSlots(String categoryId, String date) =>
      '$base/services/$categoryId/slots?date=$date';

  // Reviews
  static const reviews = '$base/reviews';

  // FCM
  static const saveFcmToken = '$base/auth/fcm-token';

  // Location
  static const reverseGeocode = '$base/delivery/reverse-geocode';
}
