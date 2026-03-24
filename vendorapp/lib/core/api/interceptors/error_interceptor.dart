import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _mapError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: message,
        message: message,
      ),
    );
  }

  String _mapError(DioException err) {
    // Try extracting server message from response body
    final serverMessage = _extractServerMessage(err.response?.data);
    if (serverMessage != null) return serverMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending data.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';
      case DioExceptionType.badResponse:
        return _mapStatusCode(err.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Please check your internet.';
      case DioExceptionType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. Please refresh and try again.';
      case 422:
        return 'The data provided is invalid.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service is temporarily unavailable.';
      case 503:
        return 'Service under maintenance. Please try again later.';
      default:
        return 'Unexpected error occurred (code: $statusCode).';
    }
  }

  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['msg'] as String?;
    }
    return null;
  }
}
