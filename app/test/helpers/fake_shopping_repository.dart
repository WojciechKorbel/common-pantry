import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_move.dart';
import 'package:common_pantry/features/shopping/data/repositories/shopping_repository.dart';

/// In-memory [ShoppingRepository]: returns the configured items, records calls
/// and throws the configured errors.
class FakeShoppingRepository implements ShoppingRepository {
  List<ShoppingItem> items = [];
  Object? itemsError;

  /// Thrown by addItem, setBought, deleteItem and moveToPantry.
  Object? actionError;

  final itemRequests = <int>[];
  final addedItems = <({String name, int quantity, int? categoryId})>[];
  final boughtChanges = <({int itemId, bool isBought})>[];
  final deletedItemIds = <int>[];
  final moves = <List<ShoppingMove>>[];

  @override
  Future<List<ShoppingItem>> getItems(int householdId) async {
    itemRequests.add(householdId);
    if (itemsError case final Object error) {
      throw error;
    }
    return items;
  }

  @override
  Future<void> addItem(
    int householdId, {
    required String name,
    required int quantity,
    int? categoryId,
  }) async {
    _throwActionError();
    addedItems.add((name: name, quantity: quantity, categoryId: categoryId));
  }

  @override
  Future<void> setBought(int householdId, {required int itemId, required bool isBought}) async {
    _throwActionError();
    boughtChanges.add((itemId: itemId, isBought: isBought));
  }

  @override
  Future<void> deleteItem(int householdId, {required int itemId}) async {
    _throwActionError();
    deletedItemIds.add(itemId);
  }

  @override
  Future<void> moveToPantry(int householdId, List<ShoppingMove> moves) async {
    _throwActionError();
    this.moves.add(moves);
  }

  void _throwActionError() {
    if (actionError case final Object error) {
      throw error;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
