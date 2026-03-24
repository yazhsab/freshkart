import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'app_config.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: DeliveryAppConfig.supabaseUrl,
      anonKey: DeliveryAppConfig.supabaseAnonKey,
    );
  }

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
