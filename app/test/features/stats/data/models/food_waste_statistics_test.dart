import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape of GET /api/households/{id}/statistics/?period=30d.
Map<String, dynamic> _json() => {
  'period': '30d',
  'summary': {'active_count': 12, 'eaten_count': 7, 'wasted_count': 3, 'waste_percentage': 30.0},
  'timeline': [
    {'date': '2026-10-16', 'wasted': 1, 'eaten': 2},
    {'date': '2026-10-17', 'wasted': 0, 'eaten': 1},
  ],
  'categories': [
    {'name': 'Dairy', 'wasted': 2},
    {'name': 'Uncategorized', 'wasted': 1},
  ],
  'top_wasted_products': [
    {'name': 'Serek wiejski', 'brand': 'Piątnica', 'count': 2},
    {'name': 'Zupa pomidorowa', 'brand': null, 'count': 1},
  ],
  'expiry': {'expired': 2, 'not_expired': 1},
};

void main() {
  group('FoodWasteStatistics.fromJson', () {
    test('parses all sections of the statistics response', () {
      final statistics = FoodWasteStatistics.fromJson(_json());

      expect(statistics.period, '30d');

      expect(statistics.summary.activeCount, 12);
      expect(statistics.summary.eatenCount, 7);
      expect(statistics.summary.wastedCount, 3);
      expect(statistics.summary.wastePercentage, 30.0);
      expect(statistics.summary.closedCount, 10);

      expect(statistics.timeline.map((entry) => entry.date), [
        DateTime(2026, 10, 16),
        DateTime(2026, 10, 17),
      ]);
      expect(statistics.timeline.first.eaten, 2);
      expect(statistics.timeline.first.wasted, 1);

      expect(statistics.categories.map((category) => category.name), ['Dairy', 'Uncategorized']);
      expect(statistics.categories.first.wasted, 2);

      expect(statistics.topWastedProducts.first.brand, 'Piątnica');
      expect(statistics.topWastedProducts.last.brand, isNull);
      expect(statistics.topWastedProducts.last.count, 1);

      expect(statistics.expiry.expired, 2);
      expect(statistics.expiry.notExpired, 1);
      expect(statistics.expiry.total, 3);
    });

    test('reads monthly timeline dates sent with time and time zone', () {
      final statistics = FoodWasteStatistics.fromJson({
        ..._json(),
        'period': '12m',
        'timeline': [
          {'date': '2026-10-01T00:00:00+02:00', 'wasted': 3, 'eaten': 7},
        ],
      });

      expect(statistics.timeline.single.date, DateTime(2026, 10));
    });

    test('handles a period without closed items', () {
      final statistics = FoodWasteStatistics.fromJson({
        ..._json(),
        'summary': {'active_count': 4, 'eaten_count': 0, 'wasted_count': 0, 'waste_percentage': 0},
        'timeline': <dynamic>[],
        'categories': <dynamic>[],
        'top_wasted_products': <dynamic>[],
        'expiry': {'expired': 0, 'not_expired': 0},
      });

      expect(statistics.summary.wastePercentage, 0.0);
      expect(statistics.summary.closedCount, 0);
      expect(statistics.timeline, isEmpty);
      expect(statistics.topWastedProducts, isEmpty);
      expect(statistics.expiry.total, 0);
    });

    test('throws when a section is missing', () {
      final json = _json()..remove('summary');

      expect(() => FoodWasteStatistics.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}