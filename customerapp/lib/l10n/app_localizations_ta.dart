// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'ஃப்ரெஷ்கார்ட்';

  @override
  String get home => 'முகப்பு';

  @override
  String get orders => 'ஆர்டர்கள்';

  @override
  String get services => 'சேவைகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get search => 'தேடு';

  @override
  String get searchProducts => 'பொருட்களைத் தேடுங்கள்...';

  @override
  String get cart => 'கூடை';

  @override
  String get checkout => 'பணம் செலுத்து';

  @override
  String get login => 'உள்நுழைவு';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get enterPhone => 'உங்கள் 10 இலக்க தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get sendOtp => 'OTP அனுப்பு';

  @override
  String get verifyOtp => 'OTP சரிபார்';

  @override
  String get enterOtp =>
      'உங்கள் தொலைபேசிக்கு அனுப்பப்பட்ட 6 இலக்க OTP-ஐ உள்ளிடவும்';

  @override
  String get resendOtp => 'OTP மீண்டும் அனுப்பு';

  @override
  String get welcome => 'ஃப்ரெஷ்கார்ட்-க்கு வரவேற்கிறோம்';

  @override
  String get nearbyStores => 'அருகிலுள்ள கடைகள்';

  @override
  String get categories => 'வகைகள்';

  @override
  String get featuredProducts => 'சிறப்பு பொருட்கள்';

  @override
  String get viewAll => 'அனைத்தும் காண்க';

  @override
  String get addToCart => 'கூடையில் சேர்';

  @override
  String get removeFromCart => 'கூடையிலிருந்து நீக்கு';

  @override
  String get quantity => 'எண்ணிக்கை';

  @override
  String get subtotal => 'உபகூட்டுத்தொகை';

  @override
  String get deliveryFee => 'டெலிவரி கட்டணம்';

  @override
  String get total => 'மொத்தம்';

  @override
  String get freeDelivery => 'இலவச டெலிவரி';

  @override
  String freeDeliveryAbove(String amount) {
    return '₹$amount மேல் இலவச டெலிவரி';
  }

  @override
  String get placeOrder => 'ஆர்டர் செய்';

  @override
  String get orderPlaced => 'ஆர்டர் பதிவாகியது!';

  @override
  String get orderConfirmed => 'ஆர்டர் உறுதிப்படுத்தப்பட்டது';

  @override
  String get orderPacking => 'பேக் செய்யப்படுகிறது';

  @override
  String get orderReady => 'எடுக்க தயாராக உள்ளது';

  @override
  String get orderPickedUp => 'டெலிவரிக்கு புறப்பட்டது';

  @override
  String get orderDelivered => 'டெலிவரி ஆகிவிட்டது';

  @override
  String get orderCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get trackOrder => 'ஆர்டர் கண்காணி';

  @override
  String get cancelOrder => 'ஆர்டர் ரத்து செய்';

  @override
  String get rateOrder => 'மதிப்பிடு';

  @override
  String get reorder => 'மீண்டும் ஆர்டர் செய்';

  @override
  String get noOrders => 'ஆர்டர்கள் இல்லை';

  @override
  String get paymentMethod => 'பணம் செலுத்தும் முறை';

  @override
  String get upi => 'UPI';

  @override
  String get card => 'கார்டு';

  @override
  String get cod => 'டெலிவரியில் பணம்';

  @override
  String get wallet => 'வாலட்';

  @override
  String get walletBalance => 'வாலட் இருப்பு';

  @override
  String get walletTopup => 'வாலட் நிரப்பு';

  @override
  String get walletHistory => 'பரிவர்த்தனை வரலாறு';

  @override
  String get topupAmount => 'நிரப்பும் தொகை';

  @override
  String get topupSuccess => 'வாலட் வெற்றிகரமாக நிரப்பப்பட்டது!';

  @override
  String get insufficientBalance => 'போதுமான வாலட் இருப்பு இல்லை';

  @override
  String get loyaltyPoints => 'லாயல்டி புள்ளிகள்';

  @override
  String get pointsBalance => 'புள்ளிகள் இருப்பு';

  @override
  String get earnedPoints => 'கிடைத்த புள்ளிகள்';

  @override
  String get redeemedPoints => 'பயன்படுத்திய புள்ளிகள்';

  @override
  String get redeemPoints => 'புள்ளிகள் பயன்படுத்து';

  @override
  String pointsEarned(String points) {
    return '$points புள்ளிகள் கிடைத்தது!';
  }

  @override
  String get coupon => 'கூப்பன்';

  @override
  String get applyCoupon => 'கூப்பன் பயன்படுத்து';

  @override
  String get removeCoupon => 'கூப்பன் நீக்கு';

  @override
  String get enterCouponCode => 'கூப்பன் குறியீடு உள்ளிடவும்';

  @override
  String couponApplied(String amount) {
    return 'கூப்பன் பயன்படுத்தப்பட்டது! ₹$amount சேமிப்பு';
  }

  @override
  String get availableCoupons => 'கிடைக்கும் கூப்பன்கள்';

  @override
  String get noCoupons => 'கூப்பன்கள் இல்லை';

  @override
  String get couponDiscount => 'கூப்பன் தள்ளுபடி';

  @override
  String get referAndEarn => 'பரிந்துரை & சம்பாதி';

  @override
  String get yourReferralCode => 'உங்கள் பரிந்துரை குறியீடு';

  @override
  String get shareCode => 'குறியீடு பகிர்';

  @override
  String referralReward(String amount) {
    return 'ஒவ்வொரு நண்பருக்கும் ₹$amount சம்பாதிக்கலாம்!';
  }

  @override
  String get totalReferrals => 'மொத்த பரிந்துரைகள்';

  @override
  String get totalEarned => 'மொத்த சம்பாத்தியம்';

  @override
  String get enterReferralCode => 'பரிந்துரை குறியீடு உள்ளிடவும்';

  @override
  String get scheduleOrder => 'ஆர்டர் திட்டமிடு';

  @override
  String get scheduleForLater => 'பின்னர் திட்டமிடு';

  @override
  String get selectDate => 'தேதி தேர்வு';

  @override
  String get selectTime => 'நேரம் தேர்வு';

  @override
  String scheduledFor(String date) {
    return '$date திட்டமிடப்பட்டது';
  }

  @override
  String get chat => 'அரட்டை';

  @override
  String get chatWithVendor => 'கடைக்காரரிடம் அரட்டை';

  @override
  String get chatWithDriver => 'டெலிவரி நபரிடம் அரட்டை';

  @override
  String get chatWithWorker => 'தொழிலாளரிடம் அரட்டை';

  @override
  String get typeMessage => 'செய்தி தட்டச்சு செய்க...';

  @override
  String get noMessages => 'செய்திகள் இல்லை';

  @override
  String get signInWithGoogle => 'Google மூலம் உள்நுழைக';

  @override
  String get signInWithApple => 'Apple மூலம் உள்நுழைக';

  @override
  String get orContinueWith => 'அல்லது தொடரவும்';

  @override
  String get myAddresses => 'எனது முகவரிகள்';

  @override
  String get addAddress => 'முகவரி சேர்';

  @override
  String get editProfile => 'சுயவிவரம் திருத்து';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get help => 'உதவி & ஆதரவு';

  @override
  String get language => 'மொழி';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get selectLanguage => 'மொழி தேர்வு';

  @override
  String get deliveryAddress => 'டெலிவரி முகவரி';

  @override
  String get specialInstructions => 'சிறப்பு அறிவுறுத்தல்கள்';

  @override
  String orderNumber(String number) {
    return 'ஆர்டர் #$number';
  }

  @override
  String get items => 'பொருட்கள்';

  @override
  String get bookNow => 'இப்போதே முன்பதிவு';

  @override
  String get bookService => 'சேவை முன்பதிவு';

  @override
  String get selectSlot => 'நேர இடைவெளி தேர்வு';

  @override
  String get bookingConfirmed => 'முன்பதிவு உறுதிப்படுத்தப்பட்டது!';

  @override
  String get myBookings => 'எனது முன்பதிவுகள்';

  @override
  String get upcomingBookings => 'வரவிருக்கும் முன்பதிவுகள்';

  @override
  String get pastBookings => 'முந்தைய முன்பதிவுகள்';

  @override
  String get rateService => 'சேவையை மதிப்பிடு';

  @override
  String get cancelBooking => 'முன்பதிவு ரத்து';

  @override
  String get noBookings => 'முன்பதிவுகள் இல்லை';

  @override
  String get open => 'திறந்துள்ளது';

  @override
  String get closed => 'மூடப்பட்டது';

  @override
  String get inStock => 'கையிருப்பு உள்ளது';

  @override
  String get outOfStock => 'கையிருப்பு இல்லை';

  @override
  String off(String percent) {
    return '$percent% தள்ளுபடி';
  }

  @override
  String minOrder(String amount) {
    return 'குறைந்தபட்ச ஆர்டர் ₹$amount';
  }

  @override
  String deliveryIn(String mins) {
    return '$mins நிமிடங்களில் டெலிவரி';
  }

  @override
  String km(String distance) {
    return '$distance கி.மீ';
  }

  @override
  String get noResults => 'முடிவுகள் இல்லை';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get confirm => 'உறுதிப்படுத்து';

  @override
  String get save => 'சேமி';

  @override
  String get delete => 'நீக்கு';

  @override
  String get edit => 'திருத்து';

  @override
  String get done => 'முடிந்தது';

  @override
  String get ok => 'சரி';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get error => 'ஏதோ தவறு ஏற்பட்டது';

  @override
  String get noInternet => 'இணைய இணைப்பு இல்லை';

  @override
  String get pullToRefresh => 'புதுப்பிக்க கீழே இழுக்கவும்';

  @override
  String get seeAll => 'அனைத்தும் காண்க';

  @override
  String get emptyCart => 'உங்கள் கூடை காலியாக உள்ளது';

  @override
  String get startShopping => 'ஷாப்பிங் தொடங்கு';

  @override
  String get locationPermission => 'இடம் அனுமதி தேவை';

  @override
  String get locationPermissionDesc =>
      'அருகிலுள்ள கடைகளைக் கண்டறிய உங்கள் இடம் தேவை';

  @override
  String get grantPermission => 'அனுமதி வழங்கு';

  @override
  String get tamilNadu => 'தமிழ்நாடு';

  @override
  String get pincode => 'அஞ்சல் குறியீடு';

  @override
  String get district => 'மாவட்டம்';

  @override
  String get city => 'நகரம்';

  @override
  String get area => 'பகுதி';

  @override
  String get flatNo => 'வீடு/அறை எண்';

  @override
  String get walletPayment => 'வாலட்டிலிருந்து செலுத்து';

  @override
  String get loyaltyRedemption => 'லாயல்டி புள்ளிகள் பயன்படுத்து';

  @override
  String get paymentSummary => 'பணம் செலுத்தும் விவரம்';

  @override
  String get orderSummary => 'ஆர்டர் சுருக்கம்';

  @override
  String get discountAmount => 'தள்ளுபடி';

  @override
  String get walletDeducted => 'வாலட்டிலிருந்து பிடிக்கப்பட்டது';

  @override
  String get loyaltyDeducted => 'லாயல்டி தள்ளுபடி';

  @override
  String get amountToPay => 'செலுத்த வேண்டிய தொகை';

  @override
  String get freshGroceries => 'புதிய மளிகை பொருட்கள்';

  @override
  String get homeServices => 'வீட்டு சேவைகள்';

  @override
  String get onboardingTitle1 => 'புதிய மளிகை பொருட்கள் உங்கள் வீட்டில்';

  @override
  String get onboardingDesc1 =>
      'புதிய காய்கறிகள், பழங்கள் மற்றும் மளிகை பொருட்கள் நிமிடங்களில் டெலிவரி';

  @override
  String get onboardingTitle2 => 'நம்பகமான வீட்டு சேவைகள்';

  @override
  String get onboardingDesc2 =>
      'குழாய் பணி, மின்சார பணி, சுத்தம் செய்தல் மற்றும் பலவற்றை முன்பதிவு செய்யுங்கள்';

  @override
  String get onboardingTitle3 => 'விரைவான & பாதுகாப்பான டெலிவரி';

  @override
  String get onboardingDesc3 =>
      'நேரடி புதுப்பிப்புகளுடன் உங்கள் ஆர்டரை கண்காணிக்கவும்';

  @override
  String get getStarted => 'தொடங்கு';

  @override
  String get skip => 'தவிர்';

  @override
  String get next => 'அடுத்து';
}
