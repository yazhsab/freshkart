import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../storage/local_storage.dart';

class ErrorInterceptor extends Interceptor {
  final VoidCallback? onUnauthorized;

  ErrorInterceptor({this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _handleUnauthorized();
    }

    final message = _extractErrorMessage(err);
    final enrichedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: err.error,
      message: message,
    );

    handler.next(enrichedError);
  }

  void _handleUnauthorized() {
    LocalStorage.removeAuthToken();
    LocalStorage.clearAll();
    onUnauthorized?.call();
  }

  String _extractErrorMessage(DioException err) {
    if (err.response?.data is Map) {
      final data = err.response!.data as Map;
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return _statusCodeMessage(err.response?.statusCode);
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _statusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Requested resource not found.';
      case 409:
        return 'Conflict. This action has already been performed.';
      case 422:
        return 'Invalid data provided.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable.';
      case 503:
        return 'Service is under maintenance.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
