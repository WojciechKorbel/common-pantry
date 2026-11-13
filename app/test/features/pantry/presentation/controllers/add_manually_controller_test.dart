import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_origin.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/add_manually_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late AddManuallyController controller;

  setUp(() {
    repository = FakePantryRepository();
    controller = AddManuallyController(repository, householdId: 1);
  });

  tearDown(() => controller.dispose());

  /// Types [name] and leaves the field, like the user does in the form.
  Future<void> enterName(String name) {
    controller.setName(name);
    return controller.lookup();
  }

  group('product lookup', () {
    test('finds an existing product by its full name, ignoring case and spaces', () async {
      repository.products = [aProduct(name: 'Serek wiejski', category: dairy)];

      await enterName(' serek WIEJSKI ');

      expect(repository.searchQueries, ['serek WIEJSKI']);
      expect(controller.isCategoryLocked, isTrue);
      expect(controller.category, dairy);
      expect(repository.categoriesCalls, 0);
    });

    test('a partial match is a new product, so categories are loaded', () async {
      repository.products = [aProduct(name: 'Serek wiejski light')];

      await enterName('Serek wiejski');

      expect(controller.isCategoryLocked, isFalse);
      expect(controller.isCategoryEnabled, isTrue);
      expect(controller.categories, [dairy, readyMeals]);
    });

    test('a failed lookup still lets the user create the product', () async {
      repository.searchError = connectionError();

      await enterName('Mleko');

      expect(controller.isLookingUp, isFalse);
      expect(controller.isCategoryEnabled, isTrue);
    });

    test('changing the name drops the found product and its category', () async {
      repository.products = [aProduct(name: 'Serek wiejski', category: dairy)];
      await enterName('Serek wiejski');

      controller.setName('Mleko');

      expect(controller.isCategoryLocked, isFalse);
      expect(controller.category, isNull);
      expect(controller.isCategoryEnabled, isFalse);
    });

    test('ignores a lookup answered after the name changed', () async {
      final pending = Completer<List<Product>>();
      repository.pendingSearch = pending;
      controller.setName('Ser');
      final lookup = controller.lookup();
      expect(controller.isLookingUp, isTrue);

      controller.setName('Serek');
      pending.complete([aProduct(name: 'Ser')]);
      await lookup;

      expect(controller.isCategoryLocked, isFalse);
      expect(controller.isLookingUp, isFalse);
    });

    test('shows a message when categories cannot be loaded', () async {
      repository.categoriesError = connectionError();

      await enterName('Mleko');

      expect(controller.categories, isEmpty);
      expect(controller.categoriesError, 'Could not load categories.');
    });
  });

  group('form state', () {
    test('count stays between 1 and 20', () {
      controller.decrement();
      expect(controller.count, 1);

      for (var i = 0; i < 25; i++) {
        controller.increment();
      }
      expect(controller.count, 20);
    });

    test('hasData reports anything the user entered', () {
      expect(controller.hasData, isFalse);

      controller.increment();
      expect(controller.hasData, isTrue);

      controller.decrement();
      expect(controller.hasData, isFalse);

      controller.setName('Mleko');
      expect(controller.hasData, isTrue);
    });
  });

  group('submit', () {
    final expiry = DateTime(2026, 11, 10);

    test('creates a new product with the chosen category and adds the items', () async {
      await enterName('Zupa pomidorowa');
      controller
        ..setCategory(readyMeals)
        ..setExpiryDate(expiry)
        ..increment()
        ..increment();

      final added = await controller.submit(origin: ProductOrigin.homemade);

      expect(added, isTrue);
      expect(repository.createdProducts.single, (
      name: 'Zupa pomidorowa',
      brand: null,
      categoryId: readyMeals.id,
      origin: ProductOrigin.homemade,
      ));
      expect(repository.addedItems.single, (
      productId: 100,
      expiryDate: expiry,
      count: 3,
      origin: ProductOrigin.homemade,
      ));
      expect(controller.isSubmitting, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('reuses an existing product and prefers the household\'s own one', () async {
      repository.products = [
        aProduct(id: 1, name: 'Mleko'),
        aProduct(id: 2, name: 'Mleko', custom: true),
      ];
      controller
        ..setName('Mleko')
        ..setExpiryDate(expiry);

      final added = await controller.submit(origin: ProductOrigin.purchased);

      expect(added, isTrue);
      expect(repository.createdProducts, isEmpty);
      expect(repository.addedItems.single.productId, 2);
    });

    test('does not submit a new product without a category', () async {
      await enterName('Zupa pomidorowa');
      controller.setExpiryDate(expiry);

      expect(controller.canSubmit, isFalse);
      expect(await controller.submit(origin: ProductOrigin.homemade), isFalse);
      expect(repository.createdProducts, isEmpty);
      expect(repository.addedItems, isEmpty);
    });

    test('does not submit without an expiry date', () async {
      repository.products = [aProduct(name: 'Mleko')];
      await enterName('Mleko');

      expect(await controller.submit(origin: ProductOrigin.purchased), isFalse);
      expect(repository.addedItems, isEmpty);
    });

    test('shows a message for each kind of server error', () async {
      repository.products = [aProduct(name: 'Mleko')];
      await enterName('Mleko');
      controller.setExpiryDate(expiry);

      final cases = [
        (serverError(400), 'Please check the entered data.'),
        (serverError(500), 'Something went wrong. Try again.'),
        (connectionError(), 'Cannot reach the server. Check your connection and try again.'),
      ];
      for (final (error, message) in cases) {
        repository.addItemsError = error;

        expect(await controller.submit(origin: ProductOrigin.purchased), isFalse);
        expect(controller.errorMessage, message);
        expect(controller.isSubmitting, isFalse);
      }
    });
  });
}