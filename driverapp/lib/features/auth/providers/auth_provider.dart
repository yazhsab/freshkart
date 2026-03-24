import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:freshkart_delivery/core/config/supabase_config.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/models/agent_model.dart';

// --- Auth State ---

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AgentModel agent;
  const AuthAuthenticated({required this.agent});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPendingApproval extends AuthState {
  const AuthPendingApproval();
}

class AuthNeedsRegistration extends AuthState {
  const AuthNeedsRegistration();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}

// --- Auth Notifier ---

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial());

  final _supabase = SupabaseConfig.client;

  /// Send OTP to the given phone number via Supabase
  Future<void> sendOtp(String phone) async {
    state = const AuthLoading();

    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      // Return to initial so the UI can navigate to OTP screen
      // We track the phone in the screen itself
      state = const AuthInitial();
    } catch (e) {
      state = AuthError(
        message: _extractError(e, 'Failed to send OTP. Please try again.'),
      );
    }
  }

  /// Verify OTP and check agent profile status
  Future<void> verifyOtp(String phone, String otp) async {
    state = const AuthLoading();

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.session == null || response.user == null) {
        state = const AuthError(message: 'Invalid OTP. Please try again.');
        return;
      }

      final userId = response.user!.id;
      final accessToken = response.session!.accessToken;

      // Save auth token for API calls
      await LocalStorage.setAuthToken(accessToken);
      await LocalStorage.setUserId(userId);

      // Check profiles table for role
      final profileResult = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = profileResult?['role'] as String?;

      // If role is not delivery_agent, check agents table directly
      if (role != 'delivery_agent') {
        // Still might have an agent record pending
        await _checkAgentRecord(userId);
        return;
      }

      // Role is delivery_agent, check agents table for approval
      await _checkAgentRecord(userId);
    } catch (e) {
      state = AuthError(
        message: _extractError(e, 'OTP verification failed. Please try again.'),
      );
    }
  }

  /// Check agent record in agents table
  Future<void> _checkAgentRecord(String userId) async {
    try {
      final agentResult = await _supabase
          .from('agents')
          .select()
          .eq('profile_id', userId)
          .maybeSingle();

      if (agentResult == null) {
        // No agent record found - needs registration
        state = const AuthNeedsRegistration();
        return;
      }

      final agent = AgentModel.fromJson(agentResult);

      if (!agent.isApproved) {
        // Agent exists but not approved yet
        state = const AuthPendingApproval();
        return;
      }

      // Agent is approved - save data and authenticate
      await LocalStorage.setAgentId(agent.id);
      await LocalStorage.setAgentName(agent.fullName);
      await LocalStorage.setVehicleType(agent.vehicleType);

      state = AuthAuthenticated(agent: agent);
    } catch (e) {
      // If agents table query fails, assume needs registration
      state = const AuthNeedsRegistration();
    }
  }

  /// Register a new delivery agent via backend API
  Future<void> registerAgent(Map<String, dynamic> data) async {
    state = const AuthLoading();

    try {
      await ApiClient.instance.post(ApiEndpoints.registerAgent, data: data);

      state = const AuthPendingApproval();
    } catch (e) {
      state = AuthError(
        message: _extractError(e, 'Registration failed. Please try again.'),
      );
    }
  }

  /// Logout - sign out from Supabase and clear local storage
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Ignore sign out errors
    }
    await LocalStorage.clearAll();
    state = const AuthUnauthenticated();
  }

  /// Check existing auth session on app startup
  Future<void> checkAuth() async {
    state = const AuthLoading();

    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        state = const AuthUnauthenticated();
        return;
      }

      final userId = session.user.id;
      await LocalStorage.setAuthToken(session.accessToken);
      await LocalStorage.setUserId(userId);

      // Check agent record
      await _checkAgentRecord(userId);
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Extract error message from exception
  String _extractError(dynamic error, String fallback) {
    if (error is AuthException) {
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('DioException')) {
        final match = RegExp(r'message: (.+?)(?:,|\])').firstMatch(message);
        if (match != null) return match.group(1) ?? fallback;
      }
      return message.replaceAll('Exception: ', '');
    }
    return fallback;
  }
}

// --- Provider ---

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
