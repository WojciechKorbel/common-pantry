import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:common_pantry/features/pantry/domain/pantry_filter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PantryController extends ChangeNotifier {
  PantryController(this._repository, {required this.householdId});

  final PantryRepository _repository;
  final int householdId;

  List<PantryGroup> _groups = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _query = '';
  int? _categoryId;

  bool get isLoading => _isLoading;

  /// True after the first successful load ("empty pantry" != "not loaded yet").
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  int? get categoryId => _categoryId;

  /// All groups in the pantry, ignoring search and filter.
  List<PantryGroup> get groups => _groups;

  /// Groups shown on the screen (after search and category filter).
  List<PantryGroup> get visibleGroups =>
      filterPantryGroups(_groups, query: _query, categoryId: _categoryId);

  List<ProductCategory> get categories => categoriesIn(_groups);

  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _repository.getPantry(householdId);
      _hasLoaded = true;
    } on DioException catch (e) {
      _errorMessage = _messageFor(e);
    } on FormatException {
      _errorMessage = 'Unexpected response from the server.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  /// null = all categories.
  void setCategory(int? categoryId) {
    _categoryId = categoryId;
    notifyListeners();
  }

  String _messageFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'Cannot reach the server. Check your connection and try again.',
    _ => switch (e.response?.statusCode) {
      401 => 'Your session has expired. Log in again.',
      404 => 'Household not found.',
      _ => 'Something went wrong. Try again.',
    },
  };
}
