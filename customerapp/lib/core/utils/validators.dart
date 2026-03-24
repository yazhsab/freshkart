class Validators {
  Validators._();

  /// Validates an Indian mobile phone number.
  /// Must be 10 digits starting with 6, 7, 8, or 9.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number';
    }

    return null;
  }

  /// Validates a 6-digit OTP.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }

    return null;
  }

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Validates a Tamil Nadu pincode (6 digits, starts with 6).
  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }

    if (!RegExp(r'^6\d{5}$').hasMatch(value.trim())) {
      return 'Enter a valid Tamil Nadu pincode (starts with 6)';
    }

    return null;
  }

  /// Check if pincode is within Tamil Nadu
  static bool isValidTNPincode(String? pincode) {
    if (pincode == null || pincode.isEmpty) return false;
    return RegExp(r'^6\d{5}$').hasMatch(pincode.trim());
  }

  /// Get TN district from pincode prefix
  static String? getDistrictFromPincode(String pincode) {
    if (!isValidTNPincode(pincode)) return null;
    final prefix = pincode.substring(0, 3);
    return _pincodeDistrictMap[prefix];
  }

  static const _pincodeDistrictMap = {
    '600': 'Chennai', '601': 'Chengalpattu', '602': 'Chengalpattu',
    '603': 'Chengalpattu', '604': 'Villupuram', '605': 'Cuddalore',
    '606': 'Tiruvannamalai', '607': 'Cuddalore', '608': 'Nagapattinam',
    '609': 'Nagapattinam', '610': 'Thanjavur', '611': 'Thanjavur',
    '612': 'Thanjavur', '613': 'Thanjavur', '614': 'Pudukkottai',
    '620': 'Tiruchirappalli', '621': 'Tiruchirappalli', '622': 'Sivaganga',
    '623': 'Ramanathapuram', '624': 'Dindigul', '625': 'Madurai',
    '626': 'Virudhunagar', '627': 'Tirunelveli', '628': 'Thoothukudi',
    '629': 'Tirunelveli', '630': 'Sivaganga', '631': 'Kanchipuram',
    '632': 'Vellore', '633': 'Tiruvannamalai', '634': 'Dharmapuri',
    '635': 'Krishnagiri', '636': 'Salem', '637': 'Namakkal',
    '638': 'Erode', '639': 'Karur', '641': 'Coimbatore',
    '642': 'Coimbatore', '643': 'Nilgiris',
  };

  /// Tamil Nadu districts list
  static const tnDistricts = [
    'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem',
    'Tirunelveli', 'Erode', 'Vellore', 'Thanjavur', 'Dindigul',
    'Thoothukudi', 'Tirupur', 'Kanchipuram', 'Cuddalore', 'Nagapattinam',
    'Villupuram', 'Krishnagiri', 'Sivaganga', 'Ramanathapuram',
    'Virudhunagar', 'Namakkal', 'Karur', 'Perambalur', 'Ariyalur',
    'Nilgiris', 'Dharmapuri', 'Theni', 'Tiruvannamalai', 'Pudukkottai',
    'Chengalpattu', 'Kallakurichi', 'Ranipet', 'Tenkasi', 'Tirupattur',
    'Mayiladuthurai',
  ];

  /// Tamil month names
  static const tamilMonths = [
    'சித்திரை', 'வைகாசி', 'ஆனி', 'ஆடி', 'ஆவணி', 'புரட்டாசி',
    'ஐப்பசி', 'கார்த்திகை', 'மார்கழி', 'தை', 'மாசி', 'பங்குனி',
  ];

  /// Validates that a field is not empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length.
  static String? minLength(
    String? value,
    int min, [
    String fieldName = 'This field',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum length.
  static String? maxLength(
    String? value,
    int max, [
    String fieldName = 'This field',
  ]) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }
}
