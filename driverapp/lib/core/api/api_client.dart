import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  ApiClient._();

  static ApiClient? _instance;
  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  late final Dio _dio;
  VoidCallback? _onUnauthorized;

  Dio get dio => _dio;

  void initialize({VoidCallback? onUnauthorized}) {
    _onUnauthorized = onUnauthorized;

    _dio = Dio(
      BaseOptions(
        baseUrl: DeliveryAppConfig.apiBaseUrl,
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
      ErrorInterceptor(onUnauthorized: _onUnauthorized),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          // Only log in debug mode
          assert(() {
            // ignore: avoid_print
            print(obj);
            return true;
          }());
        },
      ),
    ]);
  }

  // GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // PATCH
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // DELETE
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // Multipart upload
  Future<Response> upload(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }
}

typedef VoidCallback = void Function();
