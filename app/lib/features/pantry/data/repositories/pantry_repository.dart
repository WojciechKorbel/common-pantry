import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:dio/dio.dart';

class PantryRepository {
  PantryRepository(this.api);

  final ApiClient api;

  /// Active pantry items grouped by product, soonest expiry first.
  Future<List<PantryGroup>> getPantry(int householdId) async {
    final response = await api.dio.get<List<dynamic>>('/api/households/$householdId/pantry/');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty pantry response');
    }
    return data
        .map(
          (group) => switch (group) {
            final Map<String, dynamic> json => PantryGroup.fromJson(json),
            _ => throw const FormatException('Invalid pantry group'),
          },
        )
        .toList();
  }

  Future<List<ProductCategory>> getCategories() async {
    final response = await api.dio.get<List<dynamic>>('/api/categories/');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty categories response');
    }
    return data
        .map(
          (category) => switch (category) {
            final Map<String, dynamic> json => ProductCategory.fromJson(json),
            _ => throw const FormatException('Invalid category'),
          },
        )
        .toList();
  }

  /// Products known to the household whose name or brand contains [search].
  Future<List<Product>> searchProducts(int householdId, String search) async {
    final response = await api.dio.get<List<dynamic>>(
      '/api/households/$householdId/products/',
      queryParameters: {'search': search},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty products response');
    }
    return data
        .map(
          (product) => switch (product) {
            final Map<String, dynamic> json => Product.fromJson(json),
            _ => throw const FormatException('Invalid product'),
          },
        )
        .toList();
  }

  /// Finds a product by barcode in the household or via Open Food Facts.
  /// Returns null when product is not found (404).
  Future<Product?> getProductByBarcode(int householdId, String barcode) async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>(
        '/api/households/$householdId/products/barcode/$barcode/',
      );
      final data = response.data;
      if (data == null) return null;
      return Product.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Returns the existing product when the household already has one with this name and brand (200).
  Future<Product> createCustomProduct(
    int householdId, {
    required String name,
    String? brand,
    int? categoryId,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/households/$householdId/products/',
      data: {
        'name': name,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        'category': ?categoryId,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty product response');
    }
    return Product.fromJson(data);
  }

  Future<void> addItems(
    int householdId, {
    required int productId,
    required DateTime expiryDate,
    required int count,
  }) async {
    await api.dio.post<List<dynamic>>(
      '/api/households/$householdId/items/',
      data: {
        'product': productId,
        'expiry_date': _isoDate(expiryDate),
        'count': count,
      },
    );
  }

  Future<void> updateItem(
    int householdId, {
    required int itemId,
    required DateTime expiryDate,
  }) async {
    await api.dio.patch<Map<String, dynamic>>(
      '/api/households/$householdId/items/$itemId/',
      data: {
        'expiry_date': _isoDate(expiryDate),
      },
    );
  }

  Future<void> deleteItem(
    int householdId, {
    required int itemId,
  }) async {
    await api.dio.delete<void>(
      '/api/households/$householdId/items/$itemId/',
    );
  }

  Future<void> updateProduct(
    int householdId, {
    required int productId,
    required String name,
    String? brand,
    int? categoryId,
  }) async {
    await api.dio.patch<void>(
      '/api/households/$householdId/products/$productId/',
      data: {
        'name': name,
        'brand': ?brand,
        'category': ?categoryId,
      },
    );
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Household details
  Future<HouseholdDetails> getHouseholdDetails(int householdId) async {
    final response = await api.dio.get<dynamic>(
      '/api/households/$householdId/details/',
    );

    return HouseholdDetails.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Member -> Owner
  Future<void> promoteMember(int householdId, int userId) async {
    await api.dio.post<void>(
      '/api/households/$householdId/members/$userId/promote/',
    );
  }

  /// Owner -> Member
  Future<void> demoteMember(int householdId, int userId) async {
    await api.dio.post<void>(
      '/api/households/$householdId/members/$userId/demote/',
    );
  }

  /// Remove member from household.
  Future<void> removeMember(int householdId, int userId) async {
    await api.dio.delete<void>(
      '/api/households/$householdId/members/$userId/',
    );
  }

  /// Leave a household.
  Future<void> leaveHousehold(int householdId) async {
    await api.dio.post<void>(
      '/api/households/$householdId/leave/',
    );
  }

  /// Update household name (owner only).
  Future<void> updateHouseholdName(
    int householdId, {
    required String name,
  }) async {
    await api.dio.patch<void>(
      '/api/households/$householdId/settings/',
      data: {'name': name},
    );
  }
}
