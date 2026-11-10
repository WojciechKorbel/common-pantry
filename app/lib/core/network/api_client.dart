import 'package:common_pantry/core/config/env.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class ApiClient {
  ApiClient(
    this.tokenStorage, {
    String? baseUrl,
    HttpClientAdapter? httpClientAdapter,
  }) : _baseUrl = baseUrl ?? Env.apiUrl,
       _httpClientAdapter = httpClientAdapter,
       dio = _createDio(baseUrl ?? Env.apiUrl, httpClientAdapter) {
    debugPrint('[DEBUG] API URL: $_baseUrl'); // TODO: debug print is here!

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthRequest =
              options.path == '/api/auth/token/' || options.path == '/api/auth/token/refresh/';

          if (!isAuthRequest) {
            final access = await tokenStorage.getAccessToken();

            if (access != null) {
              options.headers['Authorization'] = 'Bearer $access';

              debugPrint(
                '[DEBUG] Access token loaded and attached: ${options.path}', // TODO: debug print is here!
              );
            } else {
              debugPrint(
                '[DEBUG] No access token found: ${options.path}', // TODO: debug print is here!
              );
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;

          final isAuthRequest =
              request.path == '/api/auth/token/' || request.path == '/api/auth/token/refresh/';

          if (error.response?.statusCode != 401 ||
              isAuthRequest ||
              request.extra['retried'] == true) {
            handler.next(error);
            return;
          }

          debugPrint('[DEBUG] 401 for: ${request.path}'); // TODO: debug print is here!
          debugPrint('[DEBUG] Token refresh start'); // TODO: debug print is here!

          String? newAccess;
          try {
            newAccess = await _refreshAccessToken();
          } catch (e) {
            debugPrint('[DEBUG] Refresh failed: $e'); // TODO: debug print is here!
            newAccess = null;
          }

          if (newAccess == null) {
            debugPrint('[DEBUG] Token refresh failed'); // TODO: debug print is here!
            handler.next(error);
            return;
          }

          debugPrint('[DEBUG] Token refresh success'); // TODO: debug print is here!
          debugPrint('[DEBUG] Retrying request: ${request.path}'); // TODO: debug print is here!

          request.headers['Authorization'] = 'Bearer $newAccess';
          request.extra['retried'] = true;

          try {
            final response = await dio.fetch<dynamic>(request);

            debugPrint(
              '[DEBUG] Retried request: ${response.statusCode}',
            ); // TODO: debug print is here!
            handler.resolve(response);
          } on DioException catch (e) {
            if (e.response?.statusCode == 401) {
              await tokenStorage.clear();
            }
            handler.next(e);
          } catch (e) {
            handler.reject(DioException(requestOptions: request, error: e));
          }
        },
      ),
    );
  }

  final TokenStorage tokenStorage;
  final String _baseUrl;
  final HttpClientAdapter? _httpClientAdapter;
  final Dio dio;

  /// [httpClientAdapter] replaces the real network in tests.
  static Dio _createDio(String baseUrl, HttpClientAdapter? httpClientAdapter) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    if (httpClientAdapter != null) {
      dio.httpClientAdapter = httpClientAdapter;
    }
    return dio;
  }

  Future<String?>? _refreshing;

  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _performRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refresh = await tokenStorage.getRefreshToken();

    if (refresh == null) {
      await tokenStorage.clear();
      return null;
    }

    final refreshDio = _createDio(_baseUrl, _httpClientAdapter);

    try {
      debugPrint('[DEBUG] Sending refresh'); // TODO: debug print is here!

      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/auth/token/refresh/',
        data: {'refresh': refresh},
      );

      debugPrint('[DEBUG] Refresh status: ${response.statusCode}'); // TODO: debug print is here!

      final newAccess = response.data?['access'] as String?;
      final newRefresh = response.data?['refresh'] as String?;

      if (newAccess == null) {
        await tokenStorage.clear();
        return null;
      }

      await tokenStorage.saveTokens(
        access: newAccess,
        refresh: newRefresh ?? refresh,
      );

      return newAccess;
    } on DioException {
      await tokenStorage.clear();
      return null;
    }
  }
}
