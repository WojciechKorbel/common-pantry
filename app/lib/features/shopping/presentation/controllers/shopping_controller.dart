import 'dart:async';

import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_move.dart';
import 'package:common_pantry/features/shopping/data/repositories/shopping_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ShoppingController extends ChangeNotifier {
  ShoppingController(this._repository, this._households) {
    _households.addListener(_onHouseholdChanged);
  }

  final ShoppingRepository _repository;
  final HouseholdController _households;

  List<ShoppingItem> _items = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  int _lastRequest = 0;

  bool get isLoading => _isLoading;

  bool get hasLoaded => _hasLoaded;

  String? get errorMessage => _errorMessage;

  List<ShoppingItem> get items => _items;

  List<ShoppingItem> get toBuy => _items.where((item) => !item.isBought).toList();

  List<ShoppingItem> get bought => _items.where((item) => item.isBought).toList();

  Future<void> load() async {
    final request = ++_lastRequest;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<ShoppingItem>? items;
    String? error;
    try {
      items = await _repository.getItems(_households.current.id);
    } on DioException catch (e) {
      error = _messageFor(e);
    } on FormatException {
      error = 'Unexpected response from the server.';
    }

    if (request != _lastRequest) {
      return;
    }
    if (items != null) {
      _items = items;
      _hasLoaded = true;
    }
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addItem({
    required String name,
    required int quantity,
    int? categoryId,
  }) {
    return _run(
      () => _repository.addItem(
        _households.current.id,
        name: name,
        quantity: quantity,
        categoryId: categoryId,
      ),
    );
  }

  Future<bool> setBought(int itemId, bool isBought) {
    return _run(
      () => _repository.setBought(
        _households.current.id,
        itemId: itemId,
        isBought: isBought,
      ),
    );
  }

  Future<bool> deleteItem(int itemId) {
    return _run(
      () => _repository.deleteItem(
        _households.current.id,
        itemId: itemId,
      ),
    );
  }

  /// Moves the given bought items to the pantry.
  Future<bool> moveToPantry(List<ShoppingMove> moves) async {
    _errorMessage = null;
    try {
      await _repository.moveToPantry(_households.current.id, moves);
      await load();
      return true;
    } on DioException catch (e) {
      final isStale = e.response?.statusCode == 400;
      final message = isStale
          ? 'The list was changed by someone else. Close this window and try again.'
          : _messageFor(e);
      if (isStale) {
        await load();
      }
      _errorMessage = message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    _errorMessage = null;
    try {
      await action();
      await load();
      return true;
    } on DioException catch (e) {
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    }
  }

  void _onHouseholdChanged() {
    _items = const [];
    _hasLoaded = false;
    unawaited(load());
  }

  @override
  void dispose() {
    _households.removeListener(_onHouseholdChanged);
    super.dispose();
  }

  String _messageFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'Cannot reach the server. Check your connection and try again.',
    _ => switch (e.response?.statusCode) {
      401 => 'Your session has expired. Log in again.',
      404 => 'Item or household not found.',
      _ => 'Something went wrong. Try again.',
    },
  };
}
