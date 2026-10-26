import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:common_pantry/features/auth/presentation/controllers/password_reset_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController(this._repository);

  final AuthRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> requestCode({required String email}) async {
    final value = email.trim();

    if (value.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.requestPasswordReset(email: value);
      return true;
    } on DioException catch (error) {
      errorMessage = passwordResetErrorMessage(error);
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
