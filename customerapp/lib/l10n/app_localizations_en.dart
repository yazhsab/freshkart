// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FreshKart';

  @override
  String get home => 'Home';

  @override
  String get orders => 'Orders';

  @override
  String get services => 'Services';

  @override
  String get profile => 'Profile';

  @override
  String get search => 'Search';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get cart => 'Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhone => 'Enter your 10-digit phone number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get enterOtp => 'Enter the 6-digit OTP sent to your phone';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get welcome => 'Welcome to FreshKart';

  @override
  String get nearbyStores => 'Nearby Stores';

  @override
  String get categories => 'Categories';

  @override
  String get featuredProducts => 'Featured Products';

  @override
  String get viewAll => 'View All';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get removeFromCart => 'Remove from Cart';

  @override
  String get quantity => 'Quantity';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get total => 'Total';

  @override
  String get freeDelivery => 'Free Delivery';

  @override
  String freeDeliveryAbove(String amount) {
    return 'Free delivery above ₹$amount';
  }

  @override
  String get placeOrder => 'Place Order';

  @override
  String get orderPlaced => 'Order Placed!';

  @override
  String get orderConfirmed => 'Order Confirmed';

  @override
  String get orderPacking => 'Packing';

  @override
  String get orderReady => 'Ready for Pickup';

  @override
  String get orderPickedUp => 'Out for Delivery';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get orderCancelled => 'Cancelled';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get rateOrder => 'Rate Order';

  @override
  String get reorder => 'Reorder';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get upi => 'UPI';

  @override
  String get card => 'Card';

  @override
  String get cod => 'Cash on Delivery';

  @override
  String get wallet => 'Wallet';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get walletTopup => 'Top Up Wallet';

  @override
  String get walletHistory => 'Transaction History';

  @override
  String get topupAmount => 'Top Up Amount';

  @override
  String get topupSuccess => 'Wallet topped up successfully!';

  @override
  String get insufficientBalance => 'Insufficient wallet balance';

  @override
  String get loyaltyPoints => 'Loyalty Points';

  @override
  String get pointsBalance => 'Points Balance';

  @override
  String get earnedPoints => 'Points Earned';

  @override
  String get redeemedPoints => 'Points Redeemed';

  @override
  String get redeemPoints => 'Redeem Points';

  @override
  String pointsEarned(String points) {
    return 'You earned $points points!';
  }

  @override
  String get coupon => 'Coupon';

  @override
  String get applyCoupon => 'Apply Coupon';

  @override
  String get removeCoupon => 'Remove Coupon';

  @override
  String get enterCouponCode => 'Enter coupon code';

  @override
  String couponApplied(String amount) {
    return 'Coupon applied! You save ₹$amount';
  }

  @override
  String get availableCoupons => 'Available Coupons';

  @override
  String get noCoupons => 'No coupons available';

  @override
  String get couponDiscount => 'Coupon Discount';

  @override
  String get referAndEarn => 'Refer & Earn';

  @override
  String get yourReferralCode => 'Your Referral Code';

  @override
  String get shareCode => 'Share Code';

  @override
  String referralReward(String amount) {
    return 'Earn ₹$amount for each friend!';
  }

  @override
  String get totalReferrals => 'Total Referrals';

  @override
  String get totalEarned => 'Total Earned';

  @override
  String get enterReferralCode => 'Enter Referral Code';

  @override
  String get scheduleOrder => 'Schedule Order';

  @override
  String get scheduleForLater => 'Schedule for Later';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String scheduledFor(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get chat => 'Chat';

  @override
  String get chatWithVendor => 'Chat with Vendor';

  @override
  String get chatWithDriver => 'Chat with Driver';

  @override
  String get chatWithWorker => 'Chat with Worker';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get myAddresses => 'My Addresses';

  @override
  String get addAddress => 'Add Address';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get help => 'Help & Support';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get specialInstructions => 'Special Instructions';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get items => 'Items';

  @override
  String get bookNow => 'Book Now';

  @override
  String get bookService => 'Book Service';

  @override
  String get selectSlot => 'Select Slot';

  @override
  String get bookingConfirmed => 'Booking Confirmed!';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get upcomingBookings => 'Upcoming Bookings';

  @override
  String get pastBookings => 'Past Bookings';

  @override
  String get rateService => 'Rate Service';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get noBookings => 'No bookings yet';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get inStock => 'In Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String off(String percent) {
    return '$percent% OFF';
  }

  @override
  String minOrder(String amount) {
    return 'Min. order ₹$amount';
  }

  @override
  String deliveryIn(String mins) {
    return 'Delivery in $mins mins';
  }

  @override
  String km(String distance) {
    return '$distance km';
  }

  @override
  String get noResults => 'No results found';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get seeAll => 'See All';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get startShopping => 'Start Shopping';

  @override
  String get locationPermission => 'Location Permission Required';

  @override
  String get locationPermissionDesc =>
      'We need your location to find nearby stores';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get tamilNadu => 'Tamil Nadu';

  @override
  String get pincode => 'Pincode';

  @override
  String get district => 'District';

  @override
  String get city => 'City';

  @override
  String get area => 'Area';

  @override
  String get flatNo => 'Flat/House No.';

  @override
  String get walletPayment => 'Pay from Wallet';

  @override
  String get loyaltyRedemption => 'Redeem Loyalty Points';

  @override
  String get paymentSummary => 'Payment Summary';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get discountAmount => 'Discount';

  @override
  String get walletDeducted => 'Wallet Deducted';

  @override
  String get loyaltyDeducted => 'Loyalty Discount';

  @override
  String get amountToPay => 'Amount to Pay';

  @override
  String get freshGroceries => 'Fresh Groceries';

  @override
  String get homeServices => 'Home Services';

  @override
  String get onboardingTitle1 => 'Fresh Groceries at Your Doorstep';

  @override
  String get onboardingDesc1 =>
      'Get fresh vegetables, fruits and groceries delivered in minutes';

  @override
  String get onboardingTitle2 => 'Home Services You Can Trust';

  @override
  String get onboardingDesc2 =>
      'Book plumbers, electricians, cleaners and more';

  @override
  String get onboardingTitle3 => 'Quick & Safe Delivery';

  @override
  String get onboardingDesc3 =>
      'Track your order in real-time with live updates';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';
}
