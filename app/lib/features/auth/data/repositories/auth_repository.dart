import 'dart:async';

import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/core/services/notification_service.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:common_pantry/features/auth/data/models/auth_tokens.dart';
import 'package:common_pantry/features/auth/data/models/login_request.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository(this.api, this.tokenStorage) : notificationService = NotificationService(api) {
    _initGoogleSignIn();
  }

  final ApiClient api;
  final TokenStorage tokenStorage;
  final NotificationService notificationService;

  static const String _serverClientId =
      '140271937404-b6u2qh3tsbb0qi8sag88udgotdhfnun8.apps.googleusercontent.com';

  bool _isGoogleInitialized = false;

  Future<void> _initGoogleSignIn() async {
    if (_isGoogleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      );
      _isGoogleInitialized = true;
    } catch (_) {}
  }

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

    // 1. Save JWT tokens FIRST so ApiClient attaches Authorization header.
    await tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );

    // 2. Register FCM token for this authenticated user.
    try {
      await notificationService.registerDevice();
    } catch (e) {
      // print('FCM registration failed: $e');
    }
  }

  Future<bool> loginWithGoogle() async {
    await _initGoogleSignIn();

    try {
      final account = await GoogleSignIn.instance.authenticate();

      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw const FormatException('Failed to retrieve ID token from Google.');
      }

      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/auth/google/',
        data: {'id_token': idToken},
      );

      final tokens = AuthTokens.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      await tokenStorage.saveTokens(
        access: tokens.access,
        refresh: tokens.refresh,
      );

      try {
        await notificationService.registerDevice();
      } catch (e) {
        // print('FCM registration after Google login failed: $e');
      }

      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return false;
      }
      rethrow;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    // 1. Unregister FCM token BEFORE clearing JWT tokens (endpoint requires auth).
    await notificationService.unregisterDevice();

    // 2. Sign out from Google if applicable.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    // 3. Clear local JWT tokens.
    await tokenStorage.clear();
  }

  Future<bool> isLoggedIn() async {
    final loggedIn =
        await tokenStorage.getAccessToken() != null || await tokenStorage.getRefreshToken() != null;

    if (loggedIn) {
      // Ensure FCM token is synced on app restart / token refresh.
      unawaited(
        notificationService.registerDevice().catchError((e) {
          // print('FCM sync on startup failed: $e');
        }),
      );
    }

    return loggedIn;
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
