import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  /// Returns the Supabase client instance.
  /// Ensure [Supabase.initialize] has been called before accessing this.
  static SupabaseClient get client => Supabase.instance.client;

  /// Returns the current authenticated user, or null if not signed in.
  static User? get currentUser => client.auth.currentUser;

  /// Returns the current session, or null if not authenticated.
  static Session? get currentSession => client.auth.currentSession;

  /// Whether the user is currently authenticated.
  static bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
