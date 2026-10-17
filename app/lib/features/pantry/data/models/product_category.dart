class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    if (json case {'id': final int id, 'name': final String name}) {
      return ProductCategory(id: id, name: name);
    }
    throw const FormatException('Invalid category');
  }
}
