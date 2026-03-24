import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../storage/local_storage.dart';

/// Attaches the stored JWT token to every outgoing request and
/// handles 401 responses by clearing the session.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('AuthInterceptor: 401 Unauthorized – clearing session');
      LocalStorage.clearSession();
      // Navigation to login is handled at the app level via auth state
      // listeners (e.g. GoRouter redirect or Riverpod auth provider).
    }
    handler.next(err);
  }
}
