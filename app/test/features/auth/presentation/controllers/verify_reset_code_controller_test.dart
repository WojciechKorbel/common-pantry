import 'package:common_pantry/features/auth/presentation/controllers/verify_reset_code_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late VerifyResetCodeController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = VerifyResetCodeController(repository);
  });

  tearDown(() => controller.dispose());

  group('verifyCode', () {
    test('an empty code is rejected without calling the server', () async {
      expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '  '), isNull);

      expect(controller.errorMessage, 'Enter the reset code.');
      expect(repository.calls, isEmpty);
    });

    test('returns the reset token from the server', () async {
      repository.response = {'reset_token': 'token-1'};

      expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '123456'), 'token-1');

      expect(repository.calls, ['verifyPasswordResetCode jan@pantry.pl 123456']);
      expect(controller.errorMessage, isNull);
      expect(controller.isVerifying, isFalse);
    });

    test('a response without a token is treated as an error', () async {
      repository.response = {'detail': 'OK'};

      expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '123456'), isNull);
      expect(controller.errorMessage, 'Invalid response received from the server.');
    });

    test('shows the server error', () async {
      repository.error = serverError(400, data: {'detail': 'Invalid or expired code.'});

      expect(await controller.verifyCode(email: 'jan@pantry.pl', code: '123456'), isNull);
      expect(controller.errorMessage, 'Invalid or expired code.');
      expect(controller.isVerifying, isFalse);
    });
  });

  group('resendCode', () {
    test('shows the message from the server, or a default one', () async {
      repository.response = {'detail': 'A new code has been sent.'};
      expect(await controller.resendCode(email: 'jan@pantry.pl'), isTrue);
      expect(controller.infoMessage, 'A new code has been sent.');

      repository.response = {};
      expect(await controller.resendCode(email: 'jan@pantry.pl'), isTrue);
      expect(
        controller.infoMessage,
        'If an active account exists for this address, a reset code will be sent.',
      );
      expect(controller.isResending, isFalse);
    });

    test('shows the server error', () async {
      repository.error = serverError(429);

      expect(await controller.resendCode(email: 'jan@pantry.pl'), isFalse);
      expect(controller.errorMessage, 'Too many attempts. Please wait and try again.');
      expect(controller.infoMessage, isNull);
    });
  });
}
