import 'package:dio/dio.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.instance.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      LocalStorage.instance.clearSession();
    }
    handler.next(err);
  }
}
