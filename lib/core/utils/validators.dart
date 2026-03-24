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

  /// Validates an Indian pincode (6 digits, does not start with 0).
  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }

    if (!RegExp(r'^[1-9]\d{5}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }

    return null;
  }

  /// Validates that a field is not empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length.
  static String? minLength(String? value, int min, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum length.
  static String? maxLength(String? value, int max, [String fieldName = 'This field']) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }
}
