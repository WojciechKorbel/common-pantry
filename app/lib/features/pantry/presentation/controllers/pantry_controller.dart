import 'dart:async';

import 'package:common_pantry/features/households/presentation/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:common_pantry/features/pantry/domain/pantry_filter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PantryController extends ChangeNotifier {
  PantryController(this._repository, this._households) {
    _households.addListener(_onHouseholdChanged);
  }

  final PantryRepository _repository;
  final HouseholdController _households;

  List<PantryGroup> _groups = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _query = '';
  int? _categoryId;
  int _lastRequest = 0;

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
    final request = ++_lastRequest;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<PantryGroup>? groups;
    String? error;
    try {
      groups = await _repository.getPantry(_households.current.id);
    } on DioException catch (e) {
      error = _messageFor(e);
    } on FormatException {
      error = 'Unexpected response from the server.';
    }

    // A newer load started meanwhile (e.g. after switching household) – its result wins.
    if (request != _lastRequest) {
      return;
    }
    if (groups != null) {
      _groups = groups;
      _hasLoaded = true;
    }
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
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

  void _onHouseholdChanged() {
    _groups = const [];
    _hasLoaded = false;
    _query = '';
    _categoryId = null;
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
      404 => 'Household not found.',
      _ => 'Something went wrong. Try again.',
    },
  };
}
