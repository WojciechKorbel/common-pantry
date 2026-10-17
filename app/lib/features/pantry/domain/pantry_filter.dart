import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';

/// Groups whose name or brand contains [query] and which belong to [categoryId] (if given).
List<PantryGroup> filterPantryGroups(
  List<PantryGroup> groups, {
  String query = '',
  int? categoryId,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return groups.where((group) {
    if (categoryId != null && group.category?.id != categoryId) {
      return false;
    }
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return group.name.toLowerCase().contains(normalizedQuery) ||
        (group.brand?.toLowerCase().contains(normalizedQuery) ?? false);
  }).toList();
}

/// Categories that occur in [groups], without duplicates, sorted by name (for filter chips).
List<ProductCategory> categoriesIn(List<PantryGroup> groups) {
  final byId = <int, ProductCategory>{};
  for (final group in groups) {
    final category = group.category;
    if (category != null) {
      byId[category.id] = category;
    }
  }
  return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}
