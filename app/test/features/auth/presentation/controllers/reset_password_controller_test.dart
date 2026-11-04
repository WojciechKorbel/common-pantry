import 'package:common_pantry/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ResetPasswordController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = ResetPasswordController(repository);
  });

  tearDown(() => controller.dispose());

  Future<bool> reset(String password, String confirmation) => controller.resetPassword(
    resetToken: 'token-1',
    newPassword: password,
    confirmPassword: confirmation,
  );

  test('both fields must be filled and match', () async {
    expect(await reset('', 'Secret123!'), isFalse);
    expect(controller.errorMessage, 'Fill in both password fields.');

    expect(await reset('Secret123!', 'Secret321!'), isFalse);
    expect(controller.errorMessage, 'Passwords do not match.');

    expect(repository.calls, isEmpty);
  });

  test('sends the reset token with the new password', () async {
    expect(await reset('Secret123!', 'Secret123!'), isTrue);

    expect(repository.calls, ['confirmPasswordReset token-1 Secret123!']);
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('shows password rules rejected by the server', () async {
    repository.error = serverError(
      400,
      data: {
        'new_password': ['This password is too common.'],
      },
    );

    expect(await reset('password', 'password'), isFalse);
    expect(controller.errorMessage, 'This password is too common.');
    expect(controller.isLoading, isFalse);
  });
}
