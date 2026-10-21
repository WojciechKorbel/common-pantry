import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class VerifyEmailController extends ChangeNotifier {
  VerifyEmailController(this._authRepository);

  final AuthRepository _authRepository;

  bool isLoading = false;
  bool isResending = false;
  String? errorMessage;
  String? successMessage;

  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    errorMessage = null;
    successMessage = null;

    if (code.length != 6 || int.tryParse(code) == null) {
      errorMessage = 'Please enter a valid 6-digit code.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final result = await _authRepository.verifyEmail(
        email: email,
        code: code,
      );

      successMessage =
          result['detail'] as String? ?? 'E-mail address has been verified successfully.';
      return true;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final detail = _extractDetail(error.response?.data);

      if (statusCode == 429) {
        errorMessage = detail ?? 'Attempt limit exceeded. Request a new code.';
      } else if (statusCode == 400) {
        errorMessage = detail ?? 'Invalid or expired verification code.';
      } else {
        errorMessage = detail ?? 'Could not connect to the server. Please try again.';
      }

      return false;
    } catch (_) {
      errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendCode({required String email}) async {
    errorMessage = null;
    successMessage = null;

    isResending = true;
    notifyListeners();

    try {
      final result = await _authRepository.resendVerificationCode(
        email: email,
      );

      successMessage =
          result['detail'] as String? ??
          'If your account requires verification, instructions will be sent.';
      return true;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final detail = _extractDetail(error.response?.data);

      if (statusCode == 429) {
        errorMessage = detail ?? 'Please wait before requesting another code.';
      } else if (statusCode == 503) {
        errorMessage = detail ?? 'Could not send the email. Please try again later.';
      } else {
        errorMessage = detail ?? 'Could not connect to the server. Please try again.';
      }

      return false;
    } catch (_) {
      errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      isResending = false;
      notifyListeners();
    }
  }

  String? _extractDetail(dynamic data) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return null;
  }
}
