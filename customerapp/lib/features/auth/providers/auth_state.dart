import 'package:freshkart_customer/core/models/user_model.dart';

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
  final UserModel user;
  const AuthAuthenticated({required this.user});
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}
