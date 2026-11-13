import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:common_pantry/features/households/presentation/controllers/create_household_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHouseholdsRepository implements HouseholdsRepository {
  Household? result;
  Object? error;
  String? receivedName;
  int calls = 0;

  @override
  Future<Household> createHousehold({
    required String name,
  }) async {
    calls++;
    receivedName = name;

    if (error != null) throw error!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeHouseholdsRepository repository;
  late CreateHouseholdController controller;

  setUp(() {
    repository = _FakeHouseholdsRepository()..result = const Household(id: 1, name: 'Home');
    controller = CreateHouseholdController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('creates household with trimmed name', () async {
    final success = await controller.createHousehold('  Home  ');

    expect(success, isTrue);
    expect(repository.receivedName, 'Home');
    expect(controller.createdHousehold, const Household(id: 1, name: 'Home'));
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('rejects an empty household name', () async {
    final success = await controller.createHousehold('   ');

    expect(success, isFalse);
    expect(repository.calls, 0);
    expect(controller.errorMessage, 'Enter a household name.');
    expect(controller.isLoading, isFalse);
  });

  test('sets an error when household creation fails', () async {
    repository.error = Exception('Server error');

    final success = await controller.createHousehold('Home');

    expect(success, isFalse);
    expect(controller.createdHousehold, isNull);
    expect(controller.errorMessage, contains('Failed to create household'));
    expect(controller.isLoading, isFalse);
  });
}
