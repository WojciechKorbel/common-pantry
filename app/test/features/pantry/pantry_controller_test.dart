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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PantryGroup>> getPantry(int householdId) async {
    if (error case final Object error) {
      throw error;
    }
    return groups;
  }
}

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

void main() {
  test('load stores groups and finishes loading', () async {
    final controller = PantryController(
      _FakePantryRepository(groups: [_group(1, 'Serek'), _group(2, 'Mleko')]),
      householdId: 1,
    );

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.hasLoaded, isTrue);
    expect(controller.errorMessage, isNull);
    expect(controller.groups, hasLength(2));
  });

  test('load shows a connection message when the server is unreachable', () async {
    final controller = PantryController(
      _FakePantryRepository(
        error: DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      ),
      householdId: 1,
    );

    await controller.load();

    expect(controller.hasLoaded, isFalse);
    expect(controller.errorMessage, contains('Cannot reach the server'));
  });

  test('setQuery narrows visible groups and notifies the screen', () async {
    final controller = PantryController(
      _FakePantryRepository(groups: [_group(1, 'Serek'), _group(2, 'Mleko')]),
      householdId: 1,
    );
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.setQuery('mle');

    expect(controller.visibleGroups.map((group) => group.name), ['Mleko']);
    expect(notifications, 1);
  });
}
