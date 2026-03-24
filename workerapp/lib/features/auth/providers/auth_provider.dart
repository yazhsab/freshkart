import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/models/worker_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  needsRegistration,
  pendingApproval,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? phone;
  final WorkerModel? worker;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.phone,
    this.worker,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? phone,
    WorkerModel? worker,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      phone: phone ?? this.phone,
      worker: worker ?? this.worker,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _supabase = Supabase.instance.client;

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, phone: phone);
    try {
      await _supabase.auth.signInWithOtp(phone: '+91$phone');
      state = state.copyWith(status: AuthStatus.otpSent);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: '+91$phone',
        token: otp,
        type: OtpType.sms,
      );

      if (response.user == null) {
        state = state.copyWith(status: AuthStatus.error, error: 'Invalid OTP');
        return;
      }

      final workerData = await _supabase
          .from('workers')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (workerData == null) {
        state = state.copyWith(status: AuthStatus.needsRegistration);
        return;
      }

      final worker = WorkerModel.fromJson(workerData);
      LocalStorage.workerId = worker.id;

      if (!worker.isBgvApproved) {
        state = state.copyWith(
          status: AuthStatus.pendingApproval,
          worker: worker,
        );
        return;
      }

      state = state.copyWith(status: AuthStatus.authenticated, worker: worker);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    LocalStorage.workerId = null;
    LocalStorage.activeBookingId = null;
    LocalStorage.jobStartTime = null;
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
