import 'package:common_pantry/features/auth/presentation/controllers/sign_up_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SignUpController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = SignUpController(repository);
  });

  tearDown(() => controller.dispose());

  Future<bool> signUp({
    String email = 'jan@pantry.pl',
    String username = 'user1',
    String password = 'Secret123!',
    String confirmPassword = 'Secret123!',
  }) => controller.signUp(
    email: email,
    username: username,
    password: password,
    confirmPassword: confirmPassword,
  );

  test('every field is required', () async {
    expect(await signUp(email: ''), isFalse);
    expect(await signUp(username: '   '), isFalse);
    expect(await signUp(password: ''), isFalse);
    expect(await signUp(confirmPassword: ''), isFalse);

    expect(controller.errorMessage, 'Please fill in all fields.');
    expect(repository.calls, isEmpty);
  });

  test('passwords must match', () async {
    expect(await signUp(confirmPassword: 'Secret321!'), isFalse);

    expect(controller.errorMessage, 'Passwords do not match.');
    expect(repository.calls, isEmpty);
  });

  test('registers the account', () async {
    expect(await signUp(), isTrue);

    expect(repository.calls, ['register jan@pantry.pl user1 Secret123!']);
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('shows a message for each kind of error', () async {
    final cases = <(Object, String)>[
      (
        serverError(
          400,
          data: {
            'username': ['A user with that username already exists.'],
          },
        ),
        'A user with that username already exists.',
      ),
      (serverError(400, data: {'detail': 'Registration is closed.'}), 'Registration is closed.'),
      (serverError(400), 'Please check your registration details.'),
      (serverError(429), 'Too many requests. Please try again later.'),
      (serverError(503), 'Could not send the verification email. Try again later.'),
      (connectionError(), 'Could not connect to the server. Please try again.'),
      (const FormatException('Invalid response'), 'Invalid response received from the server.'),
      (StateError('unexpected'), 'An unexpected error occurred.'),
    ];

    for (final (error, message) in cases) {
      repository.error = error;

      expect(await signUp(), isFalse);
      expect(controller.errorMessage, message);
      expect(controller.isLoading, isFalse);
    }
  });
}
