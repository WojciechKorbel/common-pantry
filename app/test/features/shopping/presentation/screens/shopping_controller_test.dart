import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_move.dart';
import 'package:common_pantry/features/shopping/presentation/controllers/shopping_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_shopping_repository.dart';

void main() {
  late FakeShoppingRepository repository;
  late HouseholdController households;
  late ShoppingController controller;

  final mleko = aShoppingItem(id: 1, name: 'Mleko');
  final chleb = aShoppingItem(id: 2, name: 'Chleb', bought: true);
  final jajka = aShoppingItem(id: 3, name: 'Jajka', quantity: 10);

  setUp(() {
    repository = FakeShoppingRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    controller = ShoppingController(repository, households);
  });

  tearDown(() {
    controller.dispose();
    households.dispose();
  });

  group('load', () {
    test('splits the list into items to buy and bought items', () async {
      repository.items = [mleko, chleb, jajka];

      await controller.load();

      expect(repository.itemRequests, [home.id]);
      expect(controller.toBuy, [mleko, jajka]);
      expect(controller.bought, [chleb]);
      expect(controller.hasLoaded, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('a failed refresh keeps the previous list and shows a message', () async {
      repository.items = [mleko];
      await controller.load();

      repository.itemsError = connectionError();
      await controller.load();

      expect(controller.items, [mleko]);
      expect(
        controller.errorMessage,
        'Cannot reach the server. Check your connection and try again.',
      );
    });

    test('switching household clears the list and loads the new one', () async {
      repository.items = [mleko];
      await controller.load();

      households.select(const Household(id: 2, name: 'Dom'));

      expect(controller.items, isEmpty);
      expect(controller.hasLoaded, isFalse);

      await Future<void>.delayed(Duration.zero);
      expect(repository.itemRequests, [home.id, 2]);
      expect(controller.hasLoaded, isTrue);
    });

    test(
      'reloading the households list keeps the shopping list',
      () async {
        repository.items = [mleko];
        await controller.load();

        await households.loadHouseholds();
        await Future<void>.delayed(Duration.zero);

        expect(repository.itemRequests, hasLength(1));
        expect(controller.items, [mleko]);
      },
    );
  });

  group('list actions', () {
    test('adding an item sends its data and reloads the list', () async {
      expect(
        await controller.addItem(name: 'Chleb', quantity: 2, categoryId: readyMeals.id),
        isTrue,
      );

      expect(repository.addedItems.single, (name: 'Chleb', quantity: 2, categoryId: readyMeals.id));
      expect(repository.itemRequests, hasLength(1));
    });

    test('checking off and deleting items reload the list', () async {
      expect(await controller.setBought(5, true), isTrue);
      expect(await controller.deleteItem(6), isTrue);

      expect(repository.boughtChanges.single, (itemId: 5, isBought: true));
      expect(repository.deletedItemIds, [6]);
      expect(repository.itemRequests, hasLength(2));
    });

    test('a failed action shows a message and does not reload', () async {
      final cases = [
        (serverError(404), 'Item or household not found.'),
        (serverError(401), 'Your session has expired. Log in again.'),
        (serverError(500), 'Something went wrong. Try again.'),
        (connectionError(), 'Cannot reach the server. Check your connection and try again.'),
      ];

      for (final (error, message) in cases) {
        repository.actionError = error;

        expect(await controller.setBought(5, true), isFalse);
        expect(controller.errorMessage, message);
      }
      expect(repository.itemRequests, isEmpty);
    });
  });

  group('move to pantry', () {
    final moves = [
      ShoppingMove(itemId: 2, expiryDates: [DateTime(2026, 11, 10), DateTime(2026, 11, 12)]),
    ];

    test('sends the moves and reloads the list', () async {
      expect(await controller.moveToPantry(moves), isTrue);

      expect(repository.moves.single, same(moves));
      expect(repository.itemRequests, hasLength(1));
    });

    test('an outdated list is reloaded and the message survives the reload', () async {
      repository
        ..actionError = serverError(400)
        ..items = [mleko];

      expect(await controller.moveToPantry(moves), isFalse);

      expect(repository.itemRequests, hasLength(1));
      expect(controller.items, [mleko]);
      expect(
        controller.errorMessage,
        'The list was changed by someone else. Close this window and try again.',
      );
    });

    test('other errors show the usual message without reloading', () async {
      repository.actionError = serverError(500);

      expect(await controller.moveToPantry(moves), isFalse);

      expect(controller.errorMessage, 'Something went wrong. Try again.');
      expect(repository.itemRequests, isEmpty);
    });
  });
}
