class AppConfig {
  static const String appName = 'FreshKart Worker';
  static const String appVersion = '1.0.0';
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const double platformCommissionRate = 0.20;
  static const double commissionRate = platformCommissionRate;
  static const int bookingFee = 99;
  static const int bookingAcceptTimeoutMinutes = 120;
  static const int minWorkDescriptionLength = 20;
  static const int maxBioLength = 200;
  static const int maxJobNotes = 500;
  static const int maxCertificateUploads = 5;
  static const List<String> supportedCities = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Salem',
    'Trichy',
  ];
}
