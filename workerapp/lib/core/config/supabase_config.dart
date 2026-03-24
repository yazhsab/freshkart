import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  static String? get currentUserId => client.auth.currentUser?.id;
  static bool get isAuthenticated => client.auth.currentUser != null;
  static Future<void> signOut() async => await client.auth.signOut();
}
