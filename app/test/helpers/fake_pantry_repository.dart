import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/models/product_origin.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';

import 'builders.dart';

typedef CreatedProduct = ({String name, String? brand, int? categoryId, ProductOrigin origin});
typedef AddedItems = ({int productId, DateTime expiryDate, int count, ProductOrigin origin});

/// In-memory [PantryRepository]: returns the configured data, records calls
/// and throws the configured errors. Methods are added as tests need them.
class FakePantryRepository implements PantryRepository {
  List<Product> products = [];
  List<ProductCategory> categories = [dairy, readyMeals];

  /// When set, product search waits until the test completes it.
  Completer<List<Product>>? pendingSearch;

  Object? searchError;
  Object? categoriesError;
  Object? createProductError;
  Object? addItemsError;

  final searchQueries = <String>[];
  int categoriesCalls = 0;
  final createdProducts = <CreatedProduct>[];
  final addedItems = <AddedItems>[];

  @override
  Future<List<Product>> searchProducts(int householdId, String search) async {
    searchQueries.add(search);
    if (searchError case final Object error) {
      throw error;
    }
    final pending = pendingSearch;
    if (pending != null) {
      return pending.future;
    }
    return products;
  }

  @override
  Future<List<ProductCategory>> getCategories() async {
    categoriesCalls++;
    if (categoriesError case final Object error) {
      throw error;
    }
    return categories;
  }

  @override
  Future<Product> createCustomProduct(
      int householdId, {
        required String name,
        String? brand,
        int? categoryId,
        required ProductOrigin origin,
      }) async {
    if (createProductError case final Object error) {
      throw error;
    }
    createdProducts.add((name: name, brand: brand, categoryId: categoryId, origin: origin));
    return aProduct(id: 100, name: name, brand: brand, custom: true);
  }

  @override
  Future<void> addItems(
      int householdId, {
        required int productId,
        required DateTime expiryDate,
        required int count,
        required ProductOrigin origin,
      }) async {
    if (addItemsError case final Object error) {
      throw error;
    }
    addedItems.add((productId: productId, expiryDate: expiryDate, count: count, origin: origin));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}