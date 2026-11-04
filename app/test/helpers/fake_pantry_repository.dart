import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
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
  List<PantryGroup> pantry = [];
  Object? pantryError;

  /// When set, the next pantry load waits until the test completes it.
  Completer<List<PantryGroup>>? pendingPantry;
  final pantryRequests = <({int householdId, String? search})>[];

  /// Thrown by updateItem, deleteItem, closeItem and updateProduct.
  Object? itemActionError;
  final updatedItems = <({int itemId, DateTime expiryDate})>[];
  final deletedItemIds = <int>[];
  final closedItems = <({int itemId, String status, bool addToShoppingList})>[];
  final updatedProducts = <({int productId, String name, String? brand, int? categoryId})>[];

  List<Product> products = []; // existing line
  List<ProductCategory> categories = [dairy, readyMeals];

  /// When set, product search waits until the test completes it.
  Completer<List<Product>>? pendingSearch;

  Object? searchError;
  Object? categoriesError;
  Object? createProductError;
  Object? addItemsError;

  int? failAddItemsOnCall;
  int _addItemsCalls = 0;

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
    _addItemsCalls++;
    final failThisCall = failAddItemsOnCall == null || failAddItemsOnCall == _addItemsCalls;
    if (addItemsError case final Object error when failThisCall) {
      throw error;
    }
    addedItems.add((productId: productId, expiryDate: expiryDate, count: count, origin: origin));
  }

  @override
  Future<List<PantryGroup>> getPantry(int householdId, {String? search}) async {
    pantryRequests.add((householdId: householdId, search: search));
    if (pantryError case final Object error) {
      throw error;
    }
    final pending = pendingPantry;
    if (pending != null) {
      pendingPantry = null;
      return pending.future;
    }
    return pantry;
  }

  @override
  Future<void> updateItem(
    int householdId, {
    required int itemId,
    required DateTime expiryDate,
  }) async {
    _throwItemActionError();
    updatedItems.add((itemId: itemId, expiryDate: expiryDate));
  }

  @override
  Future<void> deleteItem(int householdId, {required int itemId}) async {
    _throwItemActionError();
    deletedItemIds.add(itemId);
  }

  @override
  Future<void> closeItem(
    int householdId, {
    required int itemId,
    required String status,
    bool addToShoppingList = false,
  }) async {
    _throwItemActionError();
    closedItems.add((itemId: itemId, status: status, addToShoppingList: addToShoppingList));
  }

  @override
  Future<void> updateProduct(
    int householdId, {
    required int productId,
    required String name,
    String? brand,
    int? categoryId,
  }) async {
    _throwItemActionError();
    updatedProducts.add((productId: productId, name: name, brand: brand, categoryId: categoryId));
  }

  void _throwItemActionError() {
    if (itemActionError case final Object error) {
      throw error;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
