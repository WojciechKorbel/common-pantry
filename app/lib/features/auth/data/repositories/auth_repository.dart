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

    final response = await api.dio.post<Map<String, dynamic>>(
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

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/register/',
      data: {
        'email': email.trim(),
        'username': username.trim(),
        'password': password,
      },
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/verify-email/',
      data: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      },
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/resend-code/',
      data: {
        'email': email.trim().toLowerCase(),
      },
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/password-reset/',
      data: {'email': email.trim()},
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/password-reset/verify/',
      data: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> resendPasswordResetCode({
    required String email,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/password-reset/resend/',
      data: {'email': email.trim()},
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/auth/password-reset/confirm/',
      data: {
        'reset_token': resetToken,
        'new_password': newPassword,
      },
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }
}
