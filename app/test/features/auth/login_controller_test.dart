import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:common_pantry/features/auth/presentation/controllers/login_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? error;
  int loginCalls = 0;
  String? username;
  String? password;

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    this.username = username;
    this.password = password;

    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuthRepository repository;
  late LoginController controller;

  setUp(() {
    repository = _FakeAuthRepository();
    controller = LoginController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('login succeeds with valid credentials', () async {
    final result = await controller.login(
      username: 'user1',
      password: 'secret123',
    );

    expect(result, isTrue);
    expect(repository.loginCalls, 1);
    expect(repository.username, 'user1');
    expect(repository.password, 'secret123');
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('login rejects empty credentials', () async {
    final result = await controller.login(
      username: '  ',
      password: 'secret123',
    );

    expect(result, isFalse);
    expect(repository.loginCalls, 0);
    expect(controller.errorMessage, 'Enter your username and password.');
    expect(controller.isLoading, isFalse);
  });

  test('login shows an error for invalid credentials', () async {
    repository.error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/token/'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/auth/token/'),
        statusCode: 401,
      ),
    );

    final result = await controller.login(
      username: 'user1',
      password: 'wrong-password',
    );

    expect(result, isFalse);
    expect(controller.errorMessage, 'Invalid username or password.');
    expect(controller.isLoading, isFalse);
  });
}
