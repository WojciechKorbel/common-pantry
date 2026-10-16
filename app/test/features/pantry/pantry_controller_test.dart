import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns [groups] or throws [error] instead of calling the server.
class _FakePantryRepository implements PantryRepository {
  _FakePantryRepository({this.groups = const [], this.error});

  final List<PantryGroup> groups;
  final Object? error;
  final requestedIds = <int>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PantryGroup>> getPantry(int householdId) async {
    requestedIds.add(householdId);
    if (error case final Object error) {
      throw error;
    }
    return groups;
  }
}

const _home = Household(id: 1, name: 'Home');

PantryGroup _group(int id, String name) => PantryGroup(
  id: id,
  name: name,
  brand: null,
  imageUrl: null,
  packageSize: '',
  category: null,
  itemCount: 1,
  earliestExpiry: DateTime(2026, 10, 20),
  items: const [],
);

PantryController _controller(_FakePantryRepository repository) =>
    PantryController(repository, HouseholdController(initial: _home));

void main() {
  test('load stores groups of the current household', () async {
    final repository = _FakePantryRepository(groups: [_group(1, 'Serek'), _group(2, 'Mleko')]);
    final controller = _controller(repository);

    await controller.load();

    expect(repository.requestedIds, [1]);
    expect(controller.isLoading, isFalse);
    expect(controller.hasLoaded, isTrue);
    expect(controller.errorMessage, isNull);
    expect(controller.groups, hasLength(2));
  });

  test('load shows a connection message when the server is unreachable', () async {
    final controller = _controller(
      _FakePantryRepository(
        error: DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    await controller.load();

    expect(controller.hasLoaded, isFalse);
    expect(controller.errorMessage, contains('Cannot reach the server'));
  });

  test('setQuery narrows visible groups and notifies the screen', () async {
    final controller = _controller(
      _FakePantryRepository(groups: [_group(1, 'Serek'), _group(2, 'Mleko')]),
    );
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.setQuery('mle');

    expect(controller.visibleGroups.map((group) => group.name), ['Mleko']);
    expect(notifications, 1);
  });

  test('switching household reloads the pantry of the new household', () async {
    final repository = _FakePantryRepository(groups: [_group(1, 'Serek')]);
    final households = HouseholdController(initial: _home);
    final controller = PantryController(repository, households);
    await controller.load();

    households.select(const Household(id: 2, name: 'Work'));
    await Future<void>.delayed(Duration.zero);

    expect(repository.requestedIds, [1, 2]);
    expect(controller.hasLoaded, isTrue);
  });
}
