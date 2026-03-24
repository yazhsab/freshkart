import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Converts [DioException]s into user-friendly error messages.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _mapError(err);
    debugPrint('ErrorInterceptor: ${err.type} → $message');

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: message,
      ),
    );
  }

  String _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet and try again.';

      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending data. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Please try again later.';

      case DioExceptionType.badResponse:
        return _extractServerMessage(err.response) ??
            _fallbackForStatus(err.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Please check your internet connection.';

      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';

      case DioExceptionType.unknown:
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Attempts to pull a human-readable error from the response body.
  /// Supports common backend shapes:
  ///   { "message": "..." }
  ///   { "error": "..." }
  ///   { "error": { "message": "..." } }
  String? _extractServerMessage(Response? response) {
    final data = response?.data;
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // { "message": "..." }
      if (data['message'] is String) return data['message'] as String;

      // { "error": "..." }
      final error = data['error'];
      if (error is String) return error;

      // { "error": { "message": "..." } }
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
    }

    return null;
  }

  String _fallbackForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. Please try again.';
      case 422:
        return 'Invalid data submitted. Please review and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Server error (${statusCode ?? 'unknown'}). Please try again.';
    }
  }
}
