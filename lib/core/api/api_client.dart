import 'package:dio/dio.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Singleton HTTP client built on top of [Dio].
///
/// The backend URL is injected at compile time via
/// `--dart-define=BACKEND_URL=https://…`.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment('BACKEND_URL'),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  static final ApiClient _instance = ApiClient._internal();

  /// Returns the singleton [ApiClient] instance.
  static ApiClient get instance => _instance;

  factory ApiClient() => _instance;

  late final Dio _dio;

  /// Exposes the underlying [Dio] instance for advanced usage.
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Convenience request methods
  // ---------------------------------------------------------------------------

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Sends a multipart/form-data request (e.g. file uploads).
  Future<Response> postFormData(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: options ?? Options(contentType: Headers.multipartFormDataContentType),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }
}
