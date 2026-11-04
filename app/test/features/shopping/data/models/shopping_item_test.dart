import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape of one item returned by GET /api/households/{id}/shopping/.
Map<String, dynamic> _json({Object? quantity = '1.00', String unit = 'pcs'}) => {
  'id': 5,
  'product': null,
  'name': 'Mleko',
  'quantity': quantity,
  'unit': unit,
  'category': null,
  'is_bought': false,
  'added_by': {'id': 1, 'username': 'user1'},
  'bought_by': null,
  'created_at': '2026-11-04T20:00:00+01:00',
  'bought_at': null,
};

ShoppingItem _item(double quantity, String unit) => ShoppingItem(
  id: 1,
  name: 'Mleko',
  quantity: quantity,
  unit: unit,
  isBought: false,
  addedBy: null,
  boughtBy: null,
);

void main() {
  group('ShoppingItem.fromJson', () {
    test('parses an item returned by the server', () {
      final item = ShoppingItem.fromJson(_json(quantity: '2.50', unit: 'kg'));

      expect(item.id, 5);
      expect(item.name, 'Mleko');
      expect(item.quantity, 2.5);
      expect(item.unit, 'kg');
      expect(item.isBought, isFalse);
      expect(item.addedBy?.username, 'user1');
      expect(item.boughtBy, isNull);
    });

    test('reads quantity sent as a number', () {
      expect(ShoppingItem.fromJson(_json(quantity: 3)).quantity, 3.0);
    });

    test('uses quantity 1 when it is missing or not a number', () {
      expect(ShoppingItem.fromJson(_json(quantity: null)).quantity, 1.0);
      expect(ShoppingItem.fromJson(_json(quantity: 'abc')).quantity, 1.0);
    });

    test('parses who bought the item', () {
      final item = ShoppingItem.fromJson({
        ..._json(),
        'is_bought': true,
        'bought_by': {'id': 2, 'username': 'user2'},
      });

      expect(item.isBought, isTrue);
      expect(item.boughtBy?.username, 'user2');
    });

    test('throws FormatException when required fields are missing', () {
      expect(() => ShoppingItem.fromJson({'id': 1, 'name': 'Mleko'}), throwsFormatException);
    });
  });

  group('quantity helpers', () {
    test('quantityLabel hides ".0" for whole quantities', () {
      expect(_item(2, 'pcs').quantityLabel, '2 pcs');
      expect(_item(1.5, 'kg').quantityLabel, '1.5 kg');
    });

    test('showQuantity hides only the default "1 pcs"', () {
      expect(_item(1, 'pcs').showQuantity, isFalse);
      expect(_item(2, 'pcs').showQuantity, isTrue);
      expect(_item(1, 'kg').showQuantity, isTrue);
    });

    test('packageCount is the number of whole pieces, limited to 1–20', () {
      expect(_item(3, 'pcs').packageCount, 3);
      expect(_item(50, 'pcs').packageCount, 20);
      expect(_item(0, 'pcs').packageCount, 1);
      expect(_item(1.5, 'pcs').packageCount, 1);
      expect(_item(2, 'kg').packageCount, 1);
    });
  });
}