import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SignUpController extends ChangeNotifier {
  SignUpController(this._authRepository);

  final AuthRepository _authRepository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> signUp({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    errorMessage = null;

    if (email.trim().isEmpty ||
        username.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      errorMessage = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _authRepository.register(
        email: email,
        username: username,
        password: password,
      );
      return true;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (statusCode == 400) {
        errorMessage = _extractMessage(data) ?? 'Please check your registration details.';
      } else if (statusCode == 429) {
        errorMessage = 'Too many requests. Please try again later.';
      } else if (statusCode == 503) {
        errorMessage = 'Could not send the verification email. Try again later.';
      } else {
        errorMessage = 'Could not connect to the server. Please try again.';
      }

      return false;
    } on FormatException {
      errorMessage = 'Invalid response received from the server.';
      return false;
    } catch (_) {
      errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is! Map) return null;

    final detail = data['detail'];
    if (detail is String) return detail;

    for (final value in data.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String) return value;
    }

    return null;
  }
}
