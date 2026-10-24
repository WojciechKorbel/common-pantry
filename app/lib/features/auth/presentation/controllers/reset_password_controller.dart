import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:common_pantry/features/auth/presentation/controllers/password_reset_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ResetPasswordController extends ChangeNotifier {
  ResetPasswordController(this._repository);

  final AuthRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      errorMessage = 'Fill in both password fields.';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.confirmPasswordReset(
        resetToken: resetToken,
        newPassword: newPassword,
      );

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
