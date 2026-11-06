import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:common_pantry/features/households/presentation/controllers/join_household_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHouseholdsRepository implements HouseholdsRepository {
  Household? result;
  Object? error;
  String? receivedInviteCode;
  int calls = 0;

  @override
  Future<Household> joinHousehold({
    required String inviteCode,
  }) async {
    calls++;
    receivedInviteCode = inviteCode;

    if (error != null) throw error!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeHouseholdsRepository repository;
  late JoinHouseholdController controller;

  setUp(() {
    repository = _FakeHouseholdsRepository()..result = const Household(id: 1, name: 'Home');

    controller = JoinHouseholdController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  void enterCode(String code) {
    for (var i = 0; i < code.length; i++) {
      controller.codeControllers[i].text = code[i];
    }
  }

  DioException dioError({
    required int statusCode,
    required String detail,
  }) {
    return DioException(
      requestOptions: RequestOptions(
        path: '/api/households/join/',
      ),
      response: Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/api/households/join/',
        ),
        statusCode: statusCode,
        data: {
          'success': false,
          'detail': detail,
        },
      ),
    );
  }

  test('joins household with a valid invitation code', () async {
    enterCode('766288');

    final success = await controller.joinHousehold();

    expect(success, isTrue);
    expect(repository.calls, 1);
    expect(repository.receivedInviteCode, '766288');
    expect(
      controller.joinedHousehold,
      const Household(id: 1, name: 'Home'),
    );
    expect(controller.errorMessage, isNull);
    expect(controller.hasError, isFalse);
    expect(controller.isLoading, isFalse);
  });

  test('rejects an incomplete invitation code', () async {
    enterCode('123');

    final success = await controller.joinHousehold();

    expect(success, isFalse);
    expect(repository.calls, 0);
    expect(controller.errorMessage, 'Please enter all 6 digits of the code.');
    expect(controller.hasError, isTrue);
    expect(controller.isLoading, isFalse);
  });

  test('sets an error for an invalid invitation code', () async {
    enterCode('123456');
    repository.error = dioError(
      statusCode: 404,
      detail: 'Invalid invite code.',
    );

    final success = await controller.joinHousehold();

    expect(success, isFalse);
    expect(repository.calls, 1);
    expect(controller.joinedHousehold, isNull);
    expect(controller.errorMessage, 'Invalid invite code.');
    expect(controller.isLoading, isFalse);
  });

  test('sets an error when user is already a household member', () async {
    enterCode('123456');
    repository.error = dioError(
      statusCode: 409,
      detail: 'You are already a member of this household.',
    );

    final success = await controller.joinHousehold();

    expect(success, isFalse);
    expect(controller.errorMessage, 'You are already a member of this household.');
    expect(controller.joinedHousehold, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('sets an error when the invitation code is rejected', () async {
    enterCode('123456');
    repository.error = dioError(
      statusCode: 400,
      detail: 'Invite code is required.',
    );

    final success = await controller.joinHousehold();

    expect(success, isFalse);
    expect(controller.errorMessage, 'Invite code is required.');
    expect(controller.isLoading, isFalse);
  });

  test('sets a generic error when an unexpected exception occurs', () async {
    enterCode('123456');
    repository.error = Exception('Unexpected error');

    final success = await controller.joinHousehold();

    expect(success, isFalse);
    expect(
      controller.errorMessage,
      'Something went wrong. Please try again.',
    );
    expect(controller.joinedHousehold, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('clears the invitation code and errors', () {
    enterCode('123456');
    controller.validateCode();

    controller.clearCode();

    expect(controller.code, '');
    expect(controller.hasError, isFalse);
    expect(controller.errorMessage, isNull);
    expect(controller.joinedHousehold, isNull);
  });

  test('clears the error after entering a digit', () {
    controller.validateCode();

    expect(controller.hasError, isTrue);

    controller.onDigitChanged('1', 0);

    expect(controller.hasError, isFalse);
    expect(controller.errorMessage, isNull);
  });
}
