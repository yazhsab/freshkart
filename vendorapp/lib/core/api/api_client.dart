import 'package:dio/dio.dart';
import 'package:freshkart_vendor/core/api/interceptors/auth_interceptor.dart';
import 'package:freshkart_vendor/core/api/interceptors/error_interceptor.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:3000',
        ),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    ]);
  }

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> postFormData(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onSendProgress,
  }) {
    return _dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      onSendProgress: onSendProgress,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
