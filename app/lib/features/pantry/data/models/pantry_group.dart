import 'package:common_pantry/features/pantry/data/models/pantry_group_item.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';

/// A product with all its packages in the pantry
class PantryGroup {
  const PantryGroup({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.packageSize,
    required this.category,
    required this.itemCount,
    required this.earliestExpiry,
    required this.items,
  });

  final int id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String packageSize;
  final ProductCategory? category;
  final int itemCount;
  final DateTime earliestExpiry;

  /// Sorted by expiry date, soonest first
  final List<PantryGroupItem> items;

  factory PantryGroup.fromJson(Map<String, dynamic> json) {
    if (json case {
      'id': final int id,
      'name': final String name,
      'item_count': final int itemCount,
      'earliest_expiry': final String earliestExpiry,
      'items': final List<dynamic> items,
    }) {
      return PantryGroup(
        id: id,
        name: name,
        brand: json['brand'] as String?,
        imageUrl: json['image_url'] as String?,
        packageSize: json['package_size'] as String? ?? '',
        category: switch (json['category']) {
          final Map<String, dynamic> category => ProductCategory.fromJson(category),
          _ => null,
        },
        itemCount: itemCount,
        earliestExpiry: DateTime.parse(earliestExpiry),
        items: items
            .map(
              (item) => switch (item) {
                final Map<String, dynamic> map => PantryGroupItem.fromJson(map),
                _ => throw const FormatException('Invalid pantry item'),
              },
            )
            .toList(),
      );
    }
    throw const FormatException('Invalid pantry group');
  }
}
