import 'package:common_pantry/features/auth/presentation/controllers/password_reset_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';

void main() {
  test('the server detail wins over everything else', () {
    final error = serverError(400, data: {'detail': 'Invalid or expired code.'});

    expect(passwordResetErrorMessage(error), 'Invalid or expired code.');
  });

  test('password rules from the server are shown one per line', () {
    final error = serverError(
      400,
      data: {
        'new_password': ['This password is too short.', 'This password is too common.'],
      },
    );

    expect(
      passwordResetErrorMessage(error),
      'This password is too short.\nThis password is too common.',
    );
  });

  test('email errors from the server are shown', () {
    final error = serverError(
      400,
      data: {
        'email': ['Enter a valid email address.'],
      },
    );

    expect(passwordResetErrorMessage(error), 'Enter a valid email address.');
  });

  test('falls back to a message based on the status code', () {
    final cases = [
      (serverError(400), 'Invalid data. Please check the entered information.'),
      (serverError(429), 'Too many attempts. Please wait and try again.'),
      (serverError(503), 'Unable to send the email. Try again later.'),
      (serverError(500), 'An unexpected error occurred. Please try again.'),
      (connectionError(), 'Could not connect to the server. Please try again.'),
    ];

    for (final (error, message) in cases) {
      expect(passwordResetErrorMessage(error), message, reason: '${error.response?.statusCode}');
    }
  });
}
