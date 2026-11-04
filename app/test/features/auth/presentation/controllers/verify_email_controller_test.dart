import 'package:common_pantry/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late VerifyEmailController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = VerifyEmailController(repository);
  });

  tearDown(() => controller.dispose());

  group('verifyCode', () {
    test('only a 6-digit code is sent to the server', () async {
      for (final code in ['', '12345', '1234567', '12a456']) {
        expect(await controller.verifyCode(email: 'jan@pantry.pl', code: code), isFalse);
        expect(controller.errorMessage, 'Please enter a valid 6-digit code.', reason: code);
      }
      expect(repository.calls, isEmpty);
    });

    test('a valid code verifies the account', () async {
      repository.response = {'detail': 'Account verified.'};

      expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '123456'), isTrue);

      expect(repository.calls, ['verifyEmail jan@pantry.pl 123456']);
      expect(controller.successMessage, 'Account verified.');
      expect(controller.isLoading, isFalse);
    });

    test('shows a default success message when the server sends none', () async {
      expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '123456'), isTrue);
      expect(controller.successMessage, 'E-mail address has been verified successfully.');
    });

    test('shows a message for each kind of error', () async {
      final cases = [
        (serverError(400, data: {'detail': 'Code expired.'}), 'Code expired.'),
        (serverError(400), 'Invalid or expired verification code.'),
        (serverError(429), 'Attempt limit exceeded. Request a new code.'),
        (connectionError(), 'Could not connect to the server. Please try again.'),
      ];

      for (final (error, message) in cases) {
        repository.error = error;

        expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '123456'), isFalse);
        expect(controller.errorMessage, message);
        expect(controller.successMessage, isNull);
      }
    });
  });

  group('resendCode', () {
    test('sends a new code', () async {
      expect(await controller.resendCode(email: 'jan@pantry.pl'), isTrue);

      expect(repository.calls, ['resendVerificationCode jan@pantry.pl']);
      expect(
        controller.successMessage,
        'If your account requires verification, instructions will be sent.',
      );
      expect(controller.isResending, isFalse);
    });

    test('shows a message for each kind of error', () async {
      final cases = [
        (serverError(429), 'Please wait before requesting another code.'),
        (serverError(503), 'Could not send the email. Please try again later.'),
      ];

      for (final (error, message) in cases) {
        repository.error = error;

        expect(await controller.resendCode(email: 'jan@pantry.pl'), isFalse);
        expect(controller.errorMessage, message);
      }
    });
  });
}
