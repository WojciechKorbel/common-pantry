import 'package:dio/dio.dart';

String passwordResetErrorMessage(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;

  if (data is Map) {
    final detail = data['detail'];

    if (detail != null) {
      return detail.toString();
    }

    final passwordErrors = data['new_password'];

    if (passwordErrors is List && passwordErrors.isNotEmpty) {
      return passwordErrors.join('\n');
    }

    final emailErrors = data['email'];

    if (emailErrors is List && emailErrors.isNotEmpty) {
      return emailErrors.join('\n');
    }
  }

  if (statusCode == 400) {
    return 'Invalid data. Please check the entered information.';
  }

  if (statusCode == 429) {
    return 'Too many attempts. Please wait and try again.';
  }

  if (statusCode == 503) {
    return 'Unable to send the email. Try again later.';
  }

  if (statusCode == null) {
    return 'Could not connect to the server. Please try again.';
  }

  return 'An unexpected error occurred. Please try again.';
}
