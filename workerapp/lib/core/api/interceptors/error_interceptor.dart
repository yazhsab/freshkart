import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final data = err.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        } else if (statusCode == 401) {
          message = 'Session expired. Please login again.';
        } else if (statusCode == 403) {
          message = 'Access denied.';
        } else if (statusCode == 404) {
          message = 'Not found.';
        } else if (statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Something went wrong.';
        }
        break;
      default:
        message = 'Something went wrong.';
    }
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
}
