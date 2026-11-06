import 'package:common_pantry/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ForgotPasswordController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = ForgotPasswordController(repository);
  });

  tearDown(() => controller.dispose());

  test('rejects invalid email addresses without calling the server', () async {
    for (final email in ['', '   ', 'jan', 'jan@', 'jan@pantry', 'jan kowalski@pantry.pl']) {
      expect(await controller.requestCode(email: email), isFalse, reason: email);
      expect(controller.errorMessage, 'Enter a valid email address.');
    }
    expect(repository.calls, isEmpty);
  });

  test('sends the trimmed email', () async {
    expect(await controller.requestCode(email: ' jan@pantry.pl '), isTrue);

    expect(repository.calls, ['requestPasswordReset jan@pantry.pl']);
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('shows the server error', () async {
    repository.error = serverError(429);

    expect(await controller.requestCode(email: 'jan@pantry.pl'), isFalse);
    expect(controller.errorMessage, 'Too many attempts. Please wait and try again.');
    expect(controller.isLoading, isFalse);
  });

  test('shows a generic message for an unexpected error', () async {
    repository.error = StateError('unexpected');

    expect(await controller.requestCode(email: 'jan@pantry.pl'), isFalse);
    expect(controller.errorMessage, 'An unexpected error occurred.');
  });
}
