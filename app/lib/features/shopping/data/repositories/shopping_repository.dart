import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_move.dart';

class ShoppingRepository {
  ShoppingRepository(this.api);

  final ApiClient api;

  Future<List<ShoppingItem>> getItems(int householdId) async {
    final response = await api.dio.get<List<dynamic>>(
      '/api/households/$householdId/shopping/',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty shopping list response');
    }
    return data
        .map(
          (item) => switch (item) {
            final Map<String, dynamic> json => ShoppingItem.fromJson(json),
            _ => throw const FormatException('Invalid shopping item'),
          },
        )
        .toList();
  }

  Future<void> addItem(
    int householdId, {
    required String name,
    required int quantity,
    int? categoryId,
  }) async {
    await api.dio.post<Map<String, dynamic>>(
      '/api/households/$householdId/shopping/',
      data: {
        'name': name,
        'quantity': quantity,
        'category': ?categoryId,
      },
    );
  }

  Future<void> setBought(
    int householdId, {
    required int itemId,
    required bool isBought,
  }) async {
    await api.dio.patch<Map<String, dynamic>>(
      '/api/households/$householdId/shopping/$itemId/',
      data: {'is_bought': isBought},
    );
  }

  Future<void> deleteItem(
    int householdId, {
    required int itemId,
  }) async {
    await api.dio.delete<void>(
      '/api/households/$householdId/shopping/$itemId/',
    );
  }

  Future<void> moveToPantry(int householdId, List<ShoppingMove> moves) async {
    await api.dio.post<Map<String, dynamic>>(
      '/api/households/$householdId/shopping/move-to-pantry/',
      data: {
        'items': [
          for (final move in moves)
            {
              'id': move.itemId,
              'expiry_dates': [for (final date in move.expiryDates) _isoDate(date)],
              'brand': ?move.brand,
            },
        ],
      },
    );
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
