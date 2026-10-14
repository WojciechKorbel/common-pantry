import 'package:common_pantry/core/config/env.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(this.tokenStorage) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthRequest =
              options.path == '/api/auth/token/' || options.path == '/api/auth/token/refresh/';

          if (!isAuthRequest) {
            final access = await tokenStorage.getAccessToken();

            if (access != null) {
              options.headers['Authorization'] = 'Bearer $access';
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

          try {
            final newAccess = await _refreshAccessToken();

            if (newAccess == null) {
              handler.next(error);
              return;
            }

            request.headers['Authorization'] = 'Bearer $newAccess';
            request.extra['retried'] = true;

            final response = await dio.fetch(request);
            handler.resolve(response);
          } catch (_) {
            await tokenStorage.clear();
            handler.next(error);
          }
        },
      ),
    );
  }

  final TokenStorage tokenStorage;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

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

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    try {
      final response = await refreshDio.post(
        '/api/auth/token/refresh/',
        data: {'refresh': refresh},
      );

      final newAccess = response.data['access'] as String?;
      final newRefresh = response.data['refresh'] as String?;

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
