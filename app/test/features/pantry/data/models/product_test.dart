import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a global product from the barcode lookup', () {
      final product = Product.fromJson({
        'id': 2,
        'name': 'Nutella',
        'brand': 'Nutella, Ferrero',
        'barcode': '3017620422003',
        'package_size': '400 g',
        'image_url': 'https://images.openfoodfacts.org/images/products/301/762/042/2003/front_en.633.200.jpg',
        'category': {'id': 9, 'name': 'Sweet spreads & honey'},
        'product_type': 'global',
      });

      expect(product.id, 2);
      expect(product.name, 'Nutella');
      expect(product.brand, 'Nutella, Ferrero');
      expect(product.barcode, '3017620422003');
      expect(product.packageSize, '400 g');
      expect(product.imageUrl, contains('openfoodfacts'));
      expect(product.category?.name, 'Sweet spreads & honey');
      expect(product.isCustom, isFalse);
    });

    test('parses a custom product without optional fields', () {
      final product = Product.fromJson({
        'id': 3,
        'name': 'Zupa pomidorowa',
        'brand': null,
        'barcode': null,
        'image_url': null,
        'category': null,
        'product_type': 'custom',
      });

      expect(product.brand, isNull);
      expect(product.barcode, isNull);
      expect(product.imageUrl, isNull);
      expect(product.category, isNull);
      expect(product.packageSize, '');
      expect(product.isCustom, isTrue);
    });

    test('throws FormatException when product_type is missing', () {
      expect(() => Product.fromJson({'id': 3, 'name': 'Zupa'}), throwsFormatException);
    });
  });
}