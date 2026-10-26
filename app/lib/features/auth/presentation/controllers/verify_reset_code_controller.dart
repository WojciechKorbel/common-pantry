import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:common_pantry/features/auth/presentation/controllers/password_reset_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class VerifyResetCodeController extends ChangeNotifier {
  VerifyResetCodeController(this._repository);

  final AuthRepository _repository;

  bool isVerifying = false;
  bool isResending = false;

  String? errorMessage;
  String? infoMessage;

  Future<String?> verifyCode({
    required String email,
    required String code,
  }) async {
    if (code.trim().isEmpty) {
      errorMessage = 'Enter the reset code.';
      infoMessage = null;
      notifyListeners();
      return null;
    }

    isVerifying = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    try {
      final response = await _repository.verifyPasswordResetCode(
        email: email,
        code: code,
      );

      final token = response['reset_token'];

      if (token is! String || token.isEmpty) {
        errorMessage = 'Invalid response received from the server.';
        return null;
      }

      return token;
    } on DioException catch (error) {
      errorMessage = passwordResetErrorMessage(error);
      return null;
    } catch (_) {
      errorMessage = 'An unexpected error occurred.';
      return null;
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  Future<bool> resendCode({required String email}) async {
    isResending = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    try {
      final response = await _repository.resendPasswordResetCode(
        email: email,
      );

      infoMessage =
          response['detail']?.toString() ??
          'If an active account exists for this address, '
              'a reset code will be sent.';

      return true;
    } on DioException catch (error) {
      errorMessage = passwordResetErrorMessage(error);
      return false;
    } catch (_) {
      errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      isResending = false;
      notifyListeners();
    }
  }
}
