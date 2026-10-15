import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._authRepository);

  final AuthRepository _authRepository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      errorMessage = 'Enter your username and password.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(
        username: username.trim(),
        password: password,
      );

      return true;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        errorMessage = 'Invalid username or password.';
      } else if (statusCode == 400) {
        errorMessage = 'Please check your login credentials.';
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
}
