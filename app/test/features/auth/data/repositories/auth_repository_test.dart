import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http.dart';

void main() {
  late FakeHttpAdapter server;
  late FakeTokenStorage tokens;
  late AuthRepository repository;

  setUp(() {
    server = FakeHttpAdapter();
    tokens = FakeTokenStorage();
    repository = AuthRepository(fakeApiClient(server, tokens: tokens), tokens);
  });

  FakeRequest lastRequest() => server.requests.last;

  group('session', () {
    test('login sends the credentials and saves both tokens', () async {
      server.answer = (_) => (status: 200, body: {'access': 'access-1', 'refresh': 'refresh-1'});

      await repository.login(username: 'user1', password: 'secret');

      expect(server.calls, [('POST', '/api/auth/token/')]);
      expect(lastRequest().data, {'username': 'user1', 'password': 'secret'});
      expect(tokens.access, 'access-1');
      expect(tokens.refresh, 'refresh-1');
    });

    test('an invalid login response saves nothing', () async {
      server.answer = (_) => (status: 200, body: {'access': 'access-1'});

      await expectLater(
        repository.login(username: 'user1', password: 'secret'),
        throwsFormatException,
      );
      expect(tokens.access, isNull);
    });

    test('a refresh token alone keeps the user logged in, logout clears both', () async {
      expect(await repository.isLoggedIn(), isFalse);

      tokens.refresh = 'refresh-1';
      expect(await repository.isLoggedIn(), isTrue);

      await repository.logout();
      expect(await repository.isLoggedIn(), isFalse);
    });
  });

  group('registration', () {
    test('trims the data, but never the password', () async {
      await repository.register(
        email: ' Jan@Pantry.pl ',
        username: ' user1 ',
        password: ' secret ',
      );

      expect(server.calls, [('POST', '/api/auth/register/')]);
      expect(lastRequest().data, {
        'email': 'Jan@Pantry.pl',
        'username': 'user1',
        'password': ' secret ',
      });
    });

    test('email verification sends a lowercase email and a trimmed code', () async {
      server.answer = (_) => (status: 200, body: {'detail': 'Account verified.'});

      final response = await repository.verifyEmail(email: ' Jan@Pantry.pl ', code: ' 123456 ');
      await repository.resendVerificationCode(email: 'Jan@Pantry.pl');

      expect(server.calls, [
        ('POST', '/api/auth/verify-email/'),
        ('POST', '/api/auth/resend-code/'),
      ]);
      expect(server.requests.first.data, {'email': 'jan@pantry.pl', 'code': '123456'});
      expect(lastRequest().data, {'email': 'jan@pantry.pl'});
      expect(response['detail'], 'Account verified.');
    });

    test('an empty response body gives an empty map', () async {
      server.answer = (_) => (status: 201, body: null);

      expect(
        await repository.register(email: 'jan@pantry.pl', username: 'user1', password: 'secret'),
        isEmpty,
      );
    });
  });

  test('password reset requests use the right paths and bodies', () async {
    await repository.requestPasswordReset(email: ' jan@pantry.pl ');
    await repository.verifyPasswordResetCode(email: 'jan@pantry.pl', code: ' 123456 ');
    await repository.resendPasswordResetCode(email: 'jan@pantry.pl');
    await repository.confirmPasswordReset(resetToken: 'token-1', newPassword: 'Secret123!');

    expect(server.calls, [
      ('POST', '/api/auth/password-reset/'),
      ('POST', '/api/auth/password-reset/verify/'),
      ('POST', '/api/auth/password-reset/resend/'),
      ('POST', '/api/auth/password-reset/confirm/'),
    ]);
    expect(server.requests.map((request) => request.data), [
      {'email': 'jan@pantry.pl'},
      {'email': 'jan@pantry.pl', 'code': '123456'},
      {'email': 'jan@pantry.pl'},
      {'reset_token': 'token-1', 'new_password': 'Secret123!'},
    ]);
  });
}
