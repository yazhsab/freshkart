import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_worker/core/config/app_config.dart';
import 'package:freshkart_worker/core/api/interceptors/auth_interceptor.dart';
import 'package:freshkart_worker/core/api/interceptors/error_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.addAll([AuthInterceptor(), ErrorInterceptor()]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Future<Response> upload(String path, FormData data) {
    return _dio.post(
      path,
      data: data,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }
}
