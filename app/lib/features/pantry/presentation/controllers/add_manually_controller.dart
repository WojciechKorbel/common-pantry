import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AddManuallyController extends ChangeNotifier {
  AddManuallyController(this._repository, {required this.householdId});

  static const minCount = 1;
  static const maxCount = 20;

  final PantryRepository _repository;
  final int householdId;

  String _name = '';
  Product? _product;
  bool _lookupDone = false;
  bool _isLookingUp = false;
  Future<void>? _pendingLookup;
  int _lookupRequest = 0;

  List<ProductCategory> _categories = const [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  ProductCategory? _category;
  DateTime? _expiryDate;
  int _count = minCount;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isLookingUp => _isLookingUp;

  bool get isSubmitting => _isSubmitting;

  bool get hasData => _name.trim().isNotEmpty || _expiryDate != null || _count != minCount;

  List<ProductCategory> get categories => _categories;

  String? get categoriesError => _categoriesError;

  ProductCategory? get category => _category;

  DateTime? get expiryDate => _expiryDate;

  int get count => _count;

  String? get errorMessage => _errorMessage;

  /// The product exists already, so its category cannot be changed, maybe can get change after edit endpoint gets created.
  bool get isCategoryLocked => _product != null;

  /// The user can pick a category only for a name that was checked and does not exist yet - when he creates new product.
  bool get isCategoryEnabled =>
      _lookupDone && _product == null && !_isLoadingCategories && !_isSubmitting;

  bool get canSubmit =>
      _name.trim().isNotEmpty &&
      _expiryDate != null &&
      _lookupDone &&
      !_isLookingUp &&
      !_isSubmitting &&
      (_product != null || _category != null);

  /// Called on every change of the name field.
  void setName(String value) {
    if (value == _name) {
      return;
    }
    _name = value;
    _lookupRequest++;
    _pendingLookup = null;
    _isLookingUp = false;
    _lookupDone = false;
    if (_product != null) {
      _product = null;
      _category = null;
    }
    notifyListeners();
  }

  /// Called when the name field loses focus.
  Future<void> lookup() {
    if (_lookupDone || _name.trim().isEmpty) {
      return Future.value();
    }
    final pending = _pendingLookup;
    if (pending != null) {
      return pending;
    }
    final future = _runLookup();
    _pendingLookup = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_pendingLookup, future)) {
          _pendingLookup = null;
        }
      }),
    );
    return future;
  }

  Future<void> _runLookup() async {
    final name = _name.trim();
    final request = ++_lookupRequest;
    _isLookingUp = true;
    notifyListeners();

    Product? match;
    try {
      final products = await _repository.searchProducts(householdId, name);
      match = _exactMatch(products, name);
    } on DioException {
      match = null;
    } on FormatException {
      match = null;
    }

    if (request != _lookupRequest) {
      return;
    }
    _product = match;
    if (match != null) {
      _category = match.category;
    }
    _lookupDone = true;
    _isLookingUp = false;
    notifyListeners();

    if (match == null) {
      await loadCategories();
    }
  }

  /// Full name match, ignoring case; the household's own product wins over a global one.
  Product? _exactMatch(List<Product> products, String name) {
    final wanted = name.toLowerCase();
    final matches = products.where((p) => p.name.trim().toLowerCase() == wanted).toList();
    if (matches.isEmpty) {
      return null;
    }
    return matches.firstWhere((p) => p.isCustom, orElse: () => matches.first);
  }

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty || _isLoadingCategories) {
      return;
    }
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      _categories = await _repository.getCategories();
    } on DioException {
      _categoriesError = 'Could not load categories.';
    } on FormatException {
      _categoriesError = 'Could not load categories.';
    }
    _isLoadingCategories = false;
    notifyListeners();
  }

  void setCategory(ProductCategory? category) {
    _category = category;
    notifyListeners();
  }

  void setExpiryDate(DateTime date) {
    _expiryDate = date;
    notifyListeners();
  }

  void increment() {
    if (_count < maxCount) {
      _count++;
      notifyListeners();
    }
  }

  void decrement() {
    if (_count > minCount) {
      _count--;
      notifyListeners();
    }
  }

  /// Creates the custom product if needed, then adds the items. True on success.
  Future<bool> submit() async {
    if (_isSubmitting) {
      return false;
    }
    await lookup();
    if (!canSubmit) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product =
          _product ??
          await _repository.createCustomProduct(
            householdId,
            name: _name.trim(),
            categoryId: _category?.id,
          );
      await _repository.addItems(
        householdId,
        productId: product.id,
        expiryDate: _expiryDate!,
        count: _count,
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _messageFor(e);
    } on FormatException {
      _errorMessage = 'Unexpected response from the server.';
    }
    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  String _messageFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'Cannot reach the server. Check your connection and try again.',
    _ => switch (e.response?.statusCode) {
      400 => 'Please check the entered data.',
      401 => 'Your session has expired. Log in again.',
      404 => 'Household not found.',
      _ => 'Something went wrong. Try again.',
    },
  };
}
