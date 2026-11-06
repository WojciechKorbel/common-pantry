import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/domain/pantry_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _dairy = ProductCategory(id: 4, name: 'Dairy');
const _spreads = ProductCategory(id: 9, name: 'Sweet spreads & honey');

PantryGroup _group(int id, String name, {String? brand, ProductCategory? category}) => PantryGroup(
  id: id,
  name: name,
  brand: brand,
  imageUrl: null,
  packageSize: '',
  category: category,
  itemCount: 1,
  earliestExpiry: DateTime(2026, 10, 20),
  items: const [],
);

void main() {
  final groups = [
    _group(1, 'Serek wiejski', brand: 'Piątnica', category: _dairy),
    _group(2, 'Nutella', brand: 'Nutella, Ferrero', category: _spreads),
    _group(3, 'Zupa pomidorowa'),
  ];

  List<int> ids(List<PantryGroup> result) => result.map((group) => group.id).toList();

  group('filterPantryGroups', () {
    test('returns everything without search and filter', () {
      expect(ids(filterPantryGroups(groups)), [1, 2, 3]);
    });

    test('searches name and brand, ignoring case and spaces', () {
      expect(ids(filterPantryGroups(groups, query: '  SEREK ')), [1]);
      expect(ids(filterPantryGroups(groups, query: 'ferrero')), [2]);
    });

    test('filters by category and combines it with search', () {
      expect(ids(filterPantryGroups(groups, categoryId: _dairy.id)), [1]);
      expect(ids(filterPantryGroups(groups, query: 'nutella', categoryId: _dairy.id)), isEmpty);
    });
  });

  test('categoriesIn returns each category once, sorted by name', () {
    final result = categoriesIn([...groups, _group(4, 'Mleko', category: _dairy)]);
    expect(result.map((category) => category.name), ['Dairy', 'Sweet spreads & honey']);
  });
}
