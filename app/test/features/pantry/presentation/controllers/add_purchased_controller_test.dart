import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_origin.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/add_purchased_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late AddPurchasedController controller;

  final firstDate = DateTime(2026, 11, 10);
  final secondDate = DateTime(2026, 11, 20);
  final thirdDate = DateTime(2026, 12, 1);

  final laciate = aProduct(id: 1, name: 'Mleko', brand: 'Łaciate', category: dairy);
  final mlekovita = aProduct(id: 2, name: 'Mleko', brand: 'Mlekovita', category: dairy);

  setUp(() {
    repository = FakePantryRepository();
    controller = AddPurchasedController(repository, householdId: 1);
  });

  tearDown(() => controller.dispose());

  /// Types [name] and leaves the field, like the user does in the form.
  Future<void> enterName(String name) {
    controller.setName(name);
    return controller.lookup();
  }

  /// Fills the only date row.
  void setDate(DateTime date) => controller.setRowDate(controller.rows.single, date);

  group('scanned product', () {
    test('locks name, brand and category and is added without a lookup', () async {
      controller.initializeWithScannedProduct(laciate);
      controller.setName('Kefir');
      setDate(firstDate);

      expect(controller.name, 'Mleko');
      expect(controller.brand, 'Łaciate');
      expect(controller.isNameLocked, isTrue);
      expect(controller.isBrandLocked, isTrue);
      expect(controller.isCategoryLocked, isTrue);

      expect(await controller.submit(origin: ProductOrigin.purchased), isTrue);
      expect(repository.searchQueries, isEmpty);
      expect(repository.createdProducts, isEmpty);
      expect(repository.addedItems.single.productId, 1);
    });
  });

  group('name and brand', () {
    test('the only product with this name is taken and its brand filled in', () async {
      repository.products = [laciate];

      await enterName('mleko');

      expect(controller.brand, 'Łaciate');
      expect(controller.isBrandLocked, isTrue);
      expect(controller.isCategoryLocked, isTrue);
      expect(controller.category, dairy);
      expect(repository.categoriesCalls, 0);
    });

    test('with several brands the typed brand decides, ignoring case and spaces', () async {
      repository.products = [laciate, mlekovita];
      await enterName('Mleko');

      expect(controller.isBrandLocked, isFalse);
      expect(controller.isCategoryLocked, isFalse);

      controller.setBrand(' MLEKOVITA ');
      await controller.resolveBrand();
      setDate(firstDate);

      expect(controller.isCategoryLocked, isTrue);
      expect(await controller.submit(origin: ProductOrigin.purchased), isTrue);
      expect(repository.addedItems.single.productId, 2);
    });

    test('the household\'s own product wins over a global one with the same brand', () async {
      repository.products = [laciate, aProduct(id: 3, name: 'Mleko', brand: 'Łaciate', custom: true)];
      await enterName('Mleko');
      controller.setBrand('Łaciate');
      await controller.resolveBrand();
      setDate(firstDate);

      expect(await controller.submit(origin: ProductOrigin.purchased), isTrue);
      expect(repository.addedItems.single.productId, 3);
    });

    test('a brand typed before the lookup creates a new brand of a known name', () async {
      repository.products = [laciate];
      controller
        ..setName('Mleko')
        ..setBrand('Mlekovita')
        ..setCategory(dairy);
      setDate(firstDate);

      expect(await controller.submit(origin: ProductOrigin.purchased), isTrue);
      expect(repository.createdProducts.single, (
      name: 'Mleko',
      brand: 'Mlekovita',
      categoryId: dairy.id,
      origin: ProductOrigin.purchased,
      ));
      expect(repository.addedItems.single.productId, 100);
    });

    test('changing the name clears the brand filled in from the previous product', () async {
      repository.products = [laciate];
      await enterName('Mleko');

      controller.setName('Kefir');

      expect(controller.brand, '');
      expect(controller.isBrandLocked, isFalse);
      expect(controller.isCategoryLocked, isFalse);
      expect(controller.category, isNull);
    });

    test('changing the brand drops the matched product', () async {
      repository.products = [laciate, mlekovita];
      await enterName('Mleko');
      controller.setBrand('Mlekovita');
      await controller.resolveBrand();

      controller.setBrand('Mlekovita Bio');

      expect(controller.isCategoryLocked, isFalse);
      expect(controller.category, isNull);
    });

    test('ignores a lookup answered after the name changed', () async {
      final pending = Completer<List<Product>>();
      repository.pendingSearch = pending;
      controller.setName('Mleko');
      final lookup = controller.lookup();

      controller.setName('Kefir');
      pending.complete([laciate]);
      await lookup;

      expect(controller.brand, '');
      expect(controller.isCategoryLocked, isFalse);
      expect(controller.isLookingUp, isFalse);
    });
  });

  group('date rows', () {
    test('every row needs a date before submitting', () async {
      repository.products = [laciate];
      await enterName('Mleko');
      controller.addRow();

      controller.setRowDate(controller.rows.first, firstDate);
      expect(controller.canSubmit, isFalse);

      controller.setRowDate(controller.rows.last, secondDate);
      expect(controller.canSubmit, isTrue);
    });

    test('the last row cannot be removed', () {
      controller.addRow();
      controller.removeRow(controller.rows.first);
      expect(controller.rows, hasLength(1));

      controller.removeRow(controller.rows.single);
      expect(controller.rows, hasLength(1));
    });

    test('row count stays between 1 and 20', () {
      final row = controller.rows.single;

      controller.decrementRow(row);
      expect(row.count, 1);

      for (var i = 0; i < 25; i++) {
        controller.incrementRow(row);
      }
      expect(row.count, 20);
    });

    test('hasData reports anything the user entered', () {
      expect(controller.hasData, isFalse);

      controller.addRow();
      expect(controller.hasData, isTrue);

      controller.removeRow(controller.rows.last);
      expect(controller.hasData, isFalse);

      controller.setBrand('Łaciate');
      expect(controller.hasData, isTrue);
    });
  });

  group('submit', () {
    test('adds every row with its own date and count', () async {
      repository.products = [laciate];
      await enterName('Mleko');
      controller.addRow();
      final [first, second] = controller.rows;
      controller
        ..setRowDate(first, firstDate)
        ..incrementRow(first)
        ..setRowDate(second, secondDate);

      expect(await controller.submit(origin: ProductOrigin.purchased), isTrue);
      expect(repository.addedItems, [
        (productId: 1, expiryDate: firstDate, count: 2, origin: ProductOrigin.purchased),
        (productId: 1, expiryDate: secondDate, count: 1, origin: ProductOrigin.purchased),
      ]);
    });

    test('after a partial failure only the remaining rows are sent again', () async {
      await enterName('Mleko');
      controller
        ..setCategory(dairy)
        ..addRow()
        ..addRow();
      final [first, second, third] = controller.rows;
      controller
        ..setRowDate(first, firstDate)
        ..setRowDate(second, secondDate)
        ..setRowDate(third, thirdDate);
      repository
        ..addItemsError = serverError(500)
        ..failAddItemsOnCall = 2;

      expect(await controller.submit(origin: ProductOrigin.purchased), isFalse);
      expect(
        controller.errorMessage,
        'Some dates were already added. Something went wrong. Try again.',
      );
      expect(controller.rows, [second, third]);

      repository.addItemsError = null;
      expect(await controller.submit(origin: ProductOrigin.purchased), isTrue);
      expect(repository.createdProducts, hasLength(1));
      expect(repository.addedItems.map((items) => items.expiryDate), [
        firstDate,
        secondDate,
        thirdDate,
      ]);
    });

    test('a failure before any row was added keeps all rows', () async {
      await enterName('Mleko');
      controller.setCategory(dairy);
      setDate(firstDate);
      repository.createProductError = connectionError();

      expect(await controller.submit(origin: ProductOrigin.purchased), isFalse);
      expect(
        controller.errorMessage,
        'Cannot reach the server. Check your connection and try again.',
      );
      expect(controller.rows, hasLength(1));
      expect(repository.addedItems, isEmpty);
      expect(controller.isSubmitting, isFalse);
    });
  });
}