import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/user_model.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/features/auth/providers/auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ApiClient()),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthInitial());

  /// Sends an OTP to the given 10-digit phone number.
  Future<void> sendOtp(String phone) async {
    try {
      state = const AuthLoading();
      await _api.post(ApiEndpoints.sendOtp, data: {'phone': '+91$phone'});
      state = AuthOtpSent(phone: phone);
    } catch (e) {
      state = AuthError(message: _extractMessage(e));
    }
  }

  /// Verifies the OTP for the given phone number.
  Future<void> verifyOtp(String phone, String otp) async {
    try {
      state = const AuthLoading();
      final response = await _api.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': '+91$phone', 'otp': otp},
      );

      final body = response.data as Map<String, dynamic>;
      // Backend wraps in { success, message, data: { user, session } }
      final data = body['data'] as Map<String, dynamic>;
      final session = data['session'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      await LocalStorage.saveSession(
        token: session['access_token'] as String,
        refreshToken: session['refresh_token'] as String,
        userId: user.id,
        role: user.role,
        phone: user.phone,
      );

      state = AuthAuthenticated(user: user);
    } catch (e) {
      state = AuthError(message: _extractMessage(e));
    }
  }

  /// Signs in with Google — launches native Google Sign-In flow,
  /// then sends the ID token to the backend.
  Future<void> signInWithGoogle({String? referralCode}) async {
    try {
      state = const AuthLoading();

      // 1. Launch native Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        state = const AuthInitial(); // User cancelled
        return;
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        state = const AuthError(message: 'Failed to get Google ID token');
        return;
      }

      // 2. Send ID token to backend
      final response = await _api.post(
        ApiEndpoints.googleSignIn,
        data: {
          'id_token': idToken,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
        },
      );

      _handleAuthResponse(response);
    } catch (e) {
      state = AuthError(message: _extractMessage(e));
    }
  }

  /// Signs in with Apple — launches native Apple Sign-In flow,
  /// then sends the ID token to the backend.
  Future<void> signInWithApple({String? referralCode}) async {
    try {
      state = const AuthLoading();

      // 1. Launch native Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        state = const AuthError(message: 'Failed to get Apple ID token');
        return;
      }

      // 2. Send ID token to backend
      final response = await _api.post(
        ApiEndpoints.appleSignIn,
        data: {
          'id_token': idToken,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
        },
      );

      _handleAuthResponse(response);
    } catch (e) {
      state = AuthError(message: _extractMessage(e));
    }
  }

  /// Parses the standard auth response from the backend.
  void _handleAuthResponse(Response response) async {
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await LocalStorage.saveSession(
      token: session['access_token'] as String,
      refreshToken: session['refresh_token'] as String,
      userId: user.id,
      role: user.role,
      phone: user.phone,
    );

    state = AuthAuthenticated(user: user);
  }

  /// Extracts a user-friendly error message.
  String _extractMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
      return e.error?.toString() ?? e.message ?? 'Something went wrong';
    }
    return e.toString();
  }

  /// Clears the local session and resets to initial state.
  Future<void> logout() async {
    await LocalStorage.clearSession();
    state = const AuthInitial();
  }

  /// Checks if the user has a valid session by fetching the profile.
  Future<void> checkAuth() async {
    try {
      final response = await _api.get(ApiEndpoints.profile);
      final body = response.data as Map<String, dynamic>;
      // Backend: successResponse(res, profile) → { success, message, data: profile }
      final profileJson = body['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(profileJson);
      state = AuthAuthenticated(user: user);
    } catch (_) {
      state = const AuthInitial();
    }
  }
}
