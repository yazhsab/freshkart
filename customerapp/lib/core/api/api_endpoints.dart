class ApiEndpoints {
  ApiEndpoints._();
  static const base = '/api/v1';

  // Auth
  static const sendOtp = '$base/auth/send-otp';
  static const verifyOtp = '$base/auth/verify-otp';
  static const profile = '$base/auth/profile';
  static const googleSignIn = '$base/auth/google';
  static const appleSignIn = '$base/auth/apple';

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

  // Wallet
  static const wallet = '$base/wallet';
  static const walletTopup = '$base/wallet/topup';
  static const walletTransactions = '$base/wallet/transactions';

  // Loyalty
  static const loyalty = '$base/loyalty';
  static const loyaltyRedeem = '$base/loyalty/redeem';
  static const loyaltyTransactions = '$base/loyalty/transactions';

  // Coupons
  static const coupons = '$base/coupons';
  static const applyCoupon = '$base/coupons/apply';
  static String couponByCode(String code) => '$base/coupons/code/$code';

  // Referrals
  static const referralCode = '$base/referrals/code';
  static const referralStats = '$base/referrals/stats';
  static const applyReferral = '$base/referrals/apply';

  // Chat
  static const chatRooms = '$base/chat/rooms';
  static String chatMessages(String roomId) => '$base/chat/rooms/$roomId/messages';
  static String chatRoom(String roomId) => '$base/chat/rooms/$roomId';

  // Zones
  static const zones = '$base/zones';
  static String zoneByPincode(String pincode) => '$base/zones/pincode/$pincode';
}
