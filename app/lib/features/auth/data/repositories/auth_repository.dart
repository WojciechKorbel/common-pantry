import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:common_pantry/features/auth/data/models/auth_tokens.dart';
import 'package:common_pantry/features/auth/data/models/login_request.dart';

class AuthRepository {
  AuthRepository(this.api, this.tokenStorage);

  final ApiClient api;
  final TokenStorage tokenStorage;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final request = LoginRequest(
      username: username,
      password: password,
    );

    final response = await api.dio.post<dynamic>(
      '/api/auth/token/',
      data: request.toJson(),
    );

    final tokens = AuthTokens.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    await tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );
  }

  Future<void> logout() {
    return tokenStorage.clear();
  }

  Future<bool> isLoggedIn() async {
    return await tokenStorage.getAccessToken() != null ||
        await tokenStorage.getRefreshToken() != null;
  }
}
