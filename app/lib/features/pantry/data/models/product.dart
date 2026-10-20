import 'package:common_pantry/features/pantry/data/models/product_category.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.packageSize,
    required this.imageUrl,
    required this.category,
    required this.productType,
  });

  final int id;
  final String name;
  final String? brand;
  final String? barcode;
  final String packageSize;
  final String? imageUrl;
  final ProductCategory? category;
  final String productType;

  bool get isCustom => productType == 'custom';

  factory Product.fromJson(Map<String, dynamic> json) {
    if (json case {
      'id': final int id,
      'name': final String name,
      'product_type': final String productType,
    }) {
      return Product(
        id: id,
        name: name,
        brand: json['brand'] as String?,
        barcode: json['barcode'] as String?,
        packageSize: json['package_size'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        category: switch (json['category']) {
          final Map<String, dynamic> category => ProductCategory.fromJson(category),
          _ => null,
        },
        productType: productType,
      );
    }
    throw const FormatException('Invalid product');
  }
}
