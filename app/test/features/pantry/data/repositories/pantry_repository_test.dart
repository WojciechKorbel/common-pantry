import 'package:common_pantry/features/pantry/data/models/product_origin.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http.dart';

const _nutella = {'id': 2, 'name': 'Nutella', 'product_type': 'global'};

void main() {
  late FakeHttpAdapter server;
  late PantryRepository repository;

  setUp(() {
    server = FakeHttpAdapter();
    repository = PantryRepository(fakeApiClient(server));
  });

  FakeRequest lastRequest() => server.requests.last;

  void answer(Object? body, {int status = 200}) {
    server.answer = (_) => (status: status, body: body);
  }

  group('pantry', () {
    test('loads the pantry of the household and parses the groups', () async {
      answer([
        {
          'id': 1,
          'name': 'Serek wiejski',
          'item_count': 2,
          'earliest_expiry': '2026-11-10',
          'items': <dynamic>[],
        },
      ]);

      final groups = await repository.getPantry(1);

      expect(server.calls, [('GET', '/api/households/1/pantry/')]);
      expect(lastRequest().query, isEmpty);
      expect(groups.single.name, 'Serek wiejski');
    });

    test('sends a trimmed search and skips a blank one', () async {
      answer(<dynamic>[]);

      await repository.getPantry(1, search: '  ser ');
      expect(lastRequest().query, {'search': 'ser'});

      await repository.getPantry(1, search: '   ');
      expect(lastRequest().query, isEmpty);
    });

    test('an invalid response throws FormatException', () async {
      answer([1]);
      await expectLater(repository.getPantry(1), throwsFormatException);

      answer(null);
      await expectLater(repository.getPantry(1), throwsFormatException);
    });
  });

  group('products', () {
    test('loads categories', () async {
      answer([
        {'id': 4, 'name': 'Dairy'},
      ]);

      final categories = await repository.getCategories();

      expect(server.calls, [('GET', '/api/categories/')]);
      expect(categories.single.name, 'Dairy');
    });

    test('searches products of the household', () async {
      answer([_nutella]);

      final products = await repository.searchProducts(1, 'Nutella');

      expect(server.calls, [('GET', '/api/households/1/products/')]);
      expect(lastRequest().query, {'search': 'Nutella'});
      expect(products.single.id, 2);
    });

    test('barcode lookup returns the product, or null for an unknown barcode', () async {
      answer(_nutella);
      final product = await repository.getProductByBarcode(1, '3017620422003');

      expect(lastRequest().path, '/api/households/1/products/barcode/3017620422003/');
      expect(product?.name, 'Nutella');

      answer({'detail': 'Product not found.'}, status: 404);
      expect(await repository.getProductByBarcode(1, '2999999999995'), isNull);
    });

    test('barcode lookup passes on other errors', () async {
      answer({'detail': 'Product database is unavailable.'}, status: 503);

      await expectLater(
        repository.getProductByBarcode(1, '3017620422003'),
        throwsA(isA<DioException>()),
      );
    });

    test('a custom product sends only the filled fields', () async {
      answer({'id': 3, 'name': 'Zupa', 'product_type': 'custom'});

      await repository.createCustomProduct(
        1,
        name: 'Zupa',
        brand: '',
        origin: ProductOrigin.homemade,
      );
      expect(server.calls.last, ('POST', '/api/households/1/products/'));
      expect(lastRequest().data, {'name': 'Zupa', 'origin': 'homemade'});

      await repository.createCustomProduct(
        1,
        name: 'Mleko',
        brand: 'Łaciate',
        categoryId: 4,
        origin: ProductOrigin.purchased,
      );
      expect(lastRequest().data, {
        'name': 'Mleko',
        'brand': 'Łaciate',
        'category': 4,
        'origin': 'purchased',
      });
    });
  });

  group('pantry items', () {
    test('adding items sends the date as YYYY-MM-DD', () async {
      answer(<dynamic>[]);

      await repository.addItems(
        1,
        productId: 2,
        expiryDate: DateTime(2026, 3, 7),
        count: 3,
        origin: ProductOrigin.purchased,
      );

      expect(server.calls, [('POST', '/api/households/1/items/')]);
      expect(lastRequest().data, {
        'product': 2,
        'expiry_date': '2026-03-07',
        'count': 3,
        'origin': 'purchased',
      });
    });

    test('item and product actions use the right method, path and body', () async {
      answer(null);

      await repository.updateItem(1, itemId: 7, expiryDate: DateTime(2026, 12, 24));
      await repository.deleteItem(1, itemId: 7);
      await repository.closeItem(1, itemId: 8, status: 'wasted', addToShoppingList: true);
      await repository.updateProduct(1, productId: 3, name: 'Zupa krem');

      expect(server.calls, [
        ('PATCH', '/api/households/1/items/7/'),
        ('DELETE', '/api/households/1/items/7/'),
        ('POST', '/api/households/1/items/8/close/'),
        ('PATCH', '/api/households/1/products/3/'),
      ]);
      expect(server.requests.map((request) => request.data), [
        {'expiry_date': '2026-12-24'},
        null,
        {'status': 'wasted', 'add_to_shopping_list': true},
        {'name': 'Zupa krem'},
      ]);
    });
  });

  group('household', () {
    test('loads household details', () async {
      answer({'id': 1, 'name': 'Akademik', 'members': <dynamic>[]});

      final details = await repository.getHouseholdDetails(1);

      expect(server.calls, [('GET', '/api/households/1/details/')]);
      expect(details.name, 'Akademik');
    });

    test('member and settings actions use the right method and path', () async {
      answer(null);

      await repository.promoteMember(1, 2);
      await repository.demoteMember(1, 2);
      await repository.removeMember(1, 3);
      await repository.updateHouseholdName(1, name: 'Dom');
      await repository.leaveHousehold(1);

      expect(server.calls, [
        ('POST', '/api/households/1/members/2/promote/'),
        ('POST', '/api/households/1/members/2/demote/'),
        ('DELETE', '/api/households/1/members/3/'),
        ('PATCH', '/api/households/1/settings/'),
        ('POST', '/api/households/1/leave/'),
      ]);
      expect(server.requests[3].data, {'name': 'Dom'});
    });
  });
}
