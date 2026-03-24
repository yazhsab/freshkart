import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';
import 'package:freshkart_vendor/core/models/profile_model.dart';
import 'package:freshkart_vendor/core/models/vendor_model.dart';
import 'package:freshkart_vendor/core/router/app_router.dart';

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

class AuthOtpSent extends AuthState {
  final String phone;
  const AuthOtpSent({required this.phone});
}

class AuthAuthenticated extends AuthState {
  final ProfileModel profile;
  final VendorModel? vendor;
  const AuthAuthenticated({required this.profile, this.vendor});
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}

// --- Auth Notifier ---

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial());

  final _api = ApiClient.instance;
  final _storage = LocalStorage.instance;

  /// Send OTP to the given phone number
  Future<void> sendOtp(String phone) async {
    state = const AuthLoading();

    try {
      await _api.post('/auth/send-otp', data: {'phone': phone});
      state = AuthOtpSent(phone: phone);
    } catch (e) {
      state = AuthError(message: _extractError(e, 'Failed to send OTP'));
    }
  }

  /// Verify OTP and handle session + vendor profile check
  Future<void> verifyOtp(String phone, String otp) async {
    state = const AuthLoading();

    try {
      final response = await _api.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );

      final data = response.data as Map<String, dynamic>;

      // Extract tokens and profile
      final token =
          data['access_token'] as String? ?? data['token'] as String? ?? '';
      final refreshToken = data['refresh_token'] as String? ?? '';
      final profileData =
          data['user'] as Map<String, dynamic>? ??
          data['profile'] as Map<String, dynamic>? ??
          data;
      final profile = ProfileModel.fromJson(profileData);

      // Save session
      await _storage.saveSession(
        token: token,
        refreshToken: refreshToken,
        userId: profile.id,
        role: profile.role,
        phone: profile.phone,
      );

      // Check vendor profile
      VendorModel? vendor;
      try {
        final vendorResponse = await _api.get('/vendors/me');
        final vendorData = vendorResponse.data as Map<String, dynamic>;
        vendor = VendorModel.fromJson(vendorData);
        await _storage.saveVendorId(vendor.id);
      } catch (_) {
        // No vendor record found - that's okay
        vendor = null;
      }

      state = AuthAuthenticated(profile: profile, vendor: vendor);

      // Navigate based on vendor status
      _navigateAfterAuth(vendor);
    } catch (e) {
      state = AuthError(message: _extractError(e, 'OTP verification failed'));
    }
  }

  /// Check vendor status (used from pending approval screen)
  Future<VendorModel?> checkVendorStatus() async {
    try {
      final vendorResponse = await _api.get('/vendors/me');
      final vendorData = vendorResponse.data as Map<String, dynamic>;
      final vendor = VendorModel.fromJson(vendorData);
      await _storage.saveVendorId(vendor.id);

      if (state is AuthAuthenticated) {
        state = AuthAuthenticated(
          profile: (state as AuthAuthenticated).profile,
          vendor: vendor,
        );
      }

      return vendor;
    } catch (e) {
      return null;
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthInitial();

    final context = AppRouter.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.go('/login');
    }
  }

  /// Navigate after authentication based on vendor status
  void _navigateAfterAuth(VendorModel? vendor) {
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    if (vendor == null) {
      context.go('/register-vendor');
    } else if (vendor.isApproved) {
      context.go('/dashboard');
    } else {
      context.go('/pending-approval');
    }
  }

  /// Extract error message from exception
  String _extractError(dynamic error, String fallback) {
    if (error is Exception) {
      final message = error.toString();
      // DioException contains the mapped message from ErrorInterceptor
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
