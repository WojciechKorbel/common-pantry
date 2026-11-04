import 'dart:async';

import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController controller;
  late List<({String householdName, List<PantryGroup> groups})> widgetUpdates;

  final serek = aPantryGroup(id: 1, name: 'Serek wiejski', category: dairy);
  final zupa = aPantryGroup(id: 2, name: 'Zupa pomidorowa', category: readyMeals);

  setUp(() {
    repository = FakePantryRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    widgetUpdates = [];
    controller = PantryController(
      repository,
      households,
      // "Today" is fixed so the expiry filter gives the same result on every day.
      now: () => DateTime(2026, 11, 4, 22),
      syncWidget: ({required String householdName, required List<PantryGroup> groups}) async {
        widgetUpdates.add((householdName: householdName, groups: groups));
      },
    );
  });

  tearDown(() {
    controller.dispose();
    households.dispose();
  });

  group('load', () {
    test('stores the pantry of the current household and updates the widget', () async {
      repository.pantry = [serek, zupa];

      await controller.load();

      expect(repository.pantryRequests.single.householdId, home.id);
      expect(controller.groups, [serek, zupa]);
      expect(controller.hasLoaded, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(widgetUpdates.single.householdName, 'Akademik');
      expect(widgetUpdates.single.groups, [serek, zupa]);
    });

    test('shows a connection message and does not touch the widget', () async {
      repository.pantryError = connectionError();

      await controller.load();

      expect(controller.hasLoaded, isFalse);
      expect(
        controller.errorMessage,
        'Cannot reach the server. Check your connection and try again.',
      );
      expect(widgetUpdates, isEmpty);
    });

    test('a failed refresh keeps the previous list', () async {
      repository.pantry = [serek, zupa];
      await controller.load();

      repository.pantryError = serverError(500);
      await controller.load();

      expect(controller.groups, [serek, zupa]);
      expect(controller.hasLoaded, isTrue);
      expect(controller.errorMessage, 'Something went wrong. Try again.');
    });

    test('an invalid response shows a message', () async {
      repository.pantryError = const FormatException('Invalid pantry group');

      await controller.load();

      expect(controller.errorMessage, 'Unexpected response from the server.');
    });

    test('a slow older response does not overwrite a newer one', () async {
      final slow = Completer<List<PantryGroup>>();
      repository
        ..pendingPantry = slow
        ..pantry = [zupa];

      final first = controller.load();
      await controller.load();
      slow.complete([serek]);
      await first;

      expect(controller.groups, [zupa]);
      expect(controller.isLoading, isFalse);
    });

    test('switching household resets filters and loads the new pantry', () async {
      controller
        ..setQuery('ser')
        ..setCategory(dairy.id)
        ..setExpiryFilter(ExpiryStatus.soon);

      households.select(const Household(id: 2, name: 'Dom'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.query, '');
      expect(controller.categoryId, isNull);
      expect(controller.expiryFilter, isNull);
      expect(repository.pantryRequests.last.householdId, 2);
    });
  });

  group('filters', () {
    final expired = aPantryGroup(id: 1, name: 'Jogurt', earliestExpiry: DateTime(2026, 11, 3));
    final soon = aPantryGroup(id: 2, name: 'Mleko', earliestExpiry: DateTime(2026, 11, 5));
    final fresh = aPantryGroup(id: 3, name: 'Ryż', earliestExpiry: DateTime(2026, 11, 20));

    test('search narrows visible groups and notifies the screen', () async {
      repository.pantry = [serek, zupa];
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setQuery('zupa');

      expect(controller.visibleGroups, [zupa]);
      expect(notifications, 1);
    });

    test('expiry filter compares dates with today', () async {
      repository.pantry = [expired, soon, fresh];
      await controller.load();

      controller.setExpiryFilter(ExpiryStatus.expired);
      expect(controller.visibleGroups, [expired]);

      controller.setExpiryFilter(ExpiryStatus.soon);
      expect(controller.visibleGroups, [soon]);

      controller.setExpiryFilter(ExpiryStatus.fresh);
      expect(controller.visibleGroups, [fresh]);

      controller.setExpiryFilter(null);
      expect(controller.visibleGroups, [expired, soon, fresh]);
    });

    test('search, category and expiry filters combine', () async {
      final soonDairy = aPantryGroup(
        id: 4,
        name: 'Serek homogenizowany',
        category: dairy,
        earliestExpiry: DateTime(2026, 11, 5),
      );
      repository.pantry = [serek, soon, soonDairy];
      await controller.load();

      controller
        ..setQuery('serek')
        ..setCategory(dairy.id)
        ..setExpiryFilter(ExpiryStatus.soon);

      expect(controller.visibleGroups, [soonDairy]);
    });
  });

  group('item actions', () {
    test('updating an item sends the new date and reloads the list', () async {
      final date = DateTime(2026, 11, 30);

      expect(await controller.updateItem(itemId: 7, expiryDate: date), isTrue);
      expect(repository.updatedItems.single, (itemId: 7, expiryDate: date));
      expect(repository.pantryRequests, hasLength(1));
    });

    test('deleting and closing items reload the list', () async {
      expect(await controller.deleteItem(7), isTrue);
      expect(
        await controller.closeItem(itemId: 8, status: 'wasted', addToShoppingList: true),
        isTrue,
      );

      expect(repository.deletedItemIds, [7]);
      expect(repository.closedItems.single, (itemId: 8, status: 'wasted', addToShoppingList: true));
      expect(repository.pantryRequests, hasLength(2));
    });

    test('updating a product sends its new data and reloads the list', () async {
      expect(
        await controller.updateProduct(productId: 3, name: 'Zupa krem', categoryId: readyMeals.id),
        isTrue,
      );

      expect(repository.updatedProducts.single, (
      productId: 3,
      name: 'Zupa krem',
      brand: null,
      categoryId: readyMeals.id,
      ));
      expect(repository.pantryRequests, hasLength(1));
    });

    test('a failed action shows a message and does not reload', () async {
      final cases = [
        (serverError(400), 'Item cannot be closed in its current state.'),
        (serverError(404), 'Item or household not found.'),
        (serverError(401), 'Your session has expired. Log in again.'),
      ];

      for (final (error, message) in cases) {
        repository.itemActionError = error;

        expect(await controller.closeItem(itemId: 8, status: 'eaten'), isFalse);
        expect(controller.errorMessage, message);
      }
      expect(repository.pantryRequests, isEmpty);
    });
  });
}