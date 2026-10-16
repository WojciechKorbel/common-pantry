import 'dart:convert';

import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:flutter_test/flutter_test.dart';

// Real response of GET /api/households/1/pantry/ (see server README).
const _pantryResponse = '''
[
  {
    "id": 1,
    "name": "Serek wiejski",
    "brand": "Piątnica",
    "image_url": "https://images.openfoodfacts.org/images/products/590/082/000/0141/front_pl.3.200.jpg",
    "package_size": "200 g",
    "category": {"id": 4, "name": "Dairy"},
    "item_count": 2,
    "earliest_expiry": "2026-10-06",
    "items": [
      {"id": 1, "expiry_date": "2026-10-06", "added_by": {"id": 1, "username": "user1"}, "created_at": "2026-10-16T19:42:36.374415+02:00"},
      {"id": 2, "expiry_date": "2026-10-15", "added_by": {"id": 1, "username": "user1"}, "created_at": "2026-10-16T19:42:36.374756+02:00"}
    ]
  }
]
''';

void main() {
  group('PantryGroup.fromJson', () {
    test('parses a group returned by the pantry endpoint', () {
      final list = jsonDecode(_pantryResponse) as List<dynamic>;
      final group = PantryGroup.fromJson(list.first as Map<String, dynamic>);

      expect(group.id, 1);
      expect(group.name, 'Serek wiejski');
      expect(group.brand, 'Piątnica');
      expect(group.packageSize, '200 g');
      expect(group.category?.name, 'Dairy');
      expect(group.itemCount, 2);
      expect(group.earliestExpiry, DateTime(2026, 10, 6));
      expect(
        group.items.map((item) => item.expiryDate).toList(),
        [DateTime(2026, 10, 6), DateTime(2026, 10, 15)],
      );
      expect(group.items.first.addedBy?.username, 'user1');
    });

    test('accepts a custom product without brand, picture and category', () {
      final group = PantryGroup.fromJson({
        'id': 3,
        'name': 'Zupa pomidorowa',
        'brand': null,
        'image_url': null,
        'package_size': '',
        'category': null,
        'item_count': 1,
        'earliest_expiry': '2026-10-19',
        'items': [
          {
            'id': 7,
            'expiry_date': '2026-10-19',
            'added_by': null,
            'created_at': '2026-10-16T19:42:36+02:00',
          },
        ],
      });

      expect(group.brand, isNull);
      expect(group.imageUrl, isNull);
      expect(group.category, isNull);
      expect(group.items.single.addedBy, isNull);
    });

    test('throws FormatException when required fields are missing', () {
      expect(() => PantryGroup.fromJson({'id': 1, 'name': 'Milk'}), throwsFormatException);
    });
  });
}
