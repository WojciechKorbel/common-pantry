import 'package:common_pantry/features/shopping/data/models/shopping_move.dart';
import 'package:common_pantry/features/shopping/data/repositories/shopping_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http.dart';

void main() {
  late FakeHttpAdapter server;
  late ShoppingRepository repository;

  setUp(() {
    server = FakeHttpAdapter();
    repository = ShoppingRepository(fakeApiClient(server));
  });

  FakeRequest lastRequest() => server.requests.last;

  test('loads and parses the shopping list', () async {
    server.answer = (_) => (
      status: 200,
      body: [
        {
          'id': 5,
          'name': 'Mleko',
          'quantity': '2.00',
          'unit': 'pcs',
          'is_bought': false,
          'added_by': null,
          'bought_by': null,
        },
      ],
    );

    final items = await repository.getItems(1);

    expect(server.calls, [('GET', '/api/households/1/shopping/')]);
    expect(items.single.quantity, 2.0);
  });

  test('adding an item sends the category only when chosen', () async {
    await repository.addItem(1, name: 'Chleb', quantity: 2);
    expect(lastRequest().data, {'name': 'Chleb', 'quantity': 2});

    await repository.addItem(1, name: 'Ser', quantity: 1, categoryId: 4);
    expect(lastRequest().data, {'name': 'Ser', 'quantity': 1, 'category': 4});

    expect(server.calls.last, ('POST', '/api/households/1/shopping/'));
  });

  test('checking off and deleting use the item path', () async {
    await repository.setBought(1, itemId: 5, isBought: true);
    await repository.deleteItem(1, itemId: 5);

    expect(server.calls, [
      ('PATCH', '/api/households/1/shopping/5/'),
      ('DELETE', '/api/households/1/shopping/5/'),
    ]);
    expect(server.requests.first.data, {'is_bought': true});
  });

  test('moving to the pantry sends every date and the brand only when known', () async {
    await repository.moveToPantry(1, [
      ShoppingMove(
        itemId: 2,
        expiryDates: [DateTime(2026, 11, 10), DateTime(2026, 11, 12)],
        brand: 'Łaciate',
      ),
      ShoppingMove(itemId: 3, expiryDates: [DateTime(2026, 12, 1)]),
    ]);

    expect(server.calls, [('POST', '/api/households/1/shopping/move-to-pantry/')]);
    expect(lastRequest().data, {
      'items': [
        {
          'id': 2,
          'expiry_dates': ['2026-11-10', '2026-11-12'],
          'brand': 'Łaciate',
        },
        {
          'id': 3,
          'expiry_dates': ['2026-12-01'],
        },
      ],
    });
  });
}
