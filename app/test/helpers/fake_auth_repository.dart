import 'dart:async';

import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';

/// In-memory [AuthRepository]: logs every call, then throws [error] or returns [response].
class FakeAuthRepository implements AuthRepository {
  Object? error;
  Map<String, dynamic> response = {};

  /// Readable log of calls, e.g. 'requestPasswordReset jan@pantry.pl'.
  final calls = <String>[];

  /// When set, login waits until the test completes it.
  Completer<void>? pendingLogin;

  @override
  Future<void> login({required String username, required String password}) async {
    calls.add('login $username $password');
    if (error case final Object error) {
      throw error;
    }
    final pending = pendingLogin;
    if (pending != null) {
      await pending.future;
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) => _call('register $email $username $password');

  @override
  Future<Map<String, dynamic>> verifyEmail({required String email, required String code}) =>
      _call('verifyEmail $email $code');

  @override
  Future<Map<String, dynamic>> resendVerificationCode({required String email}) =>
      _call('resendVerificationCode $email');

  @override
  Future<Map<String, dynamic>> requestPasswordReset({required String email}) =>
      _call('requestPasswordReset $email');

  @override
  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) => _call('verifyPasswordResetCode $email $code');

  @override
  Future<Map<String, dynamic>> resendPasswordResetCode({required String email}) =>
      _call('resendPasswordResetCode $email');

  @override
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) => _call('confirmPasswordReset $resetToken $newPassword');

  Future<Map<String, dynamic>> _call(String call) async {
    calls.add(call);
    if (error case final Object error) {
      throw error;
    }
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
