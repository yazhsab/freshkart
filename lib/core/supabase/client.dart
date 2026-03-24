import 'package:supabase_flutter/supabase_flutter.dart';

/// Regular Supabase client (uses anon key, respects RLS).
SupabaseClient get supabase => Supabase.instance.client;

/// Admin Supabase client (uses service role key, bypasses RLS).
/// Used for all admin data operations.
late final SupabaseClient adminClient;

void initAdminClient() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
  if (serviceRoleKey.isNotEmpty) {
    adminClient = SupabaseClient(url, serviceRoleKey);
  } else {
    // Fallback to regular client if service role key not provided
    adminClient = supabase;
  }
}
