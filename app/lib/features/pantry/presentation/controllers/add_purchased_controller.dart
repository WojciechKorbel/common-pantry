import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DateEntry {
  DateEntry(this.id);

  final int id;
  DateTime? date;
  int count = 1;
}

class AddPurchasedController extends ChangeNotifier {
  AddPurchasedController(this._repository, {required this.householdId}) {
    _rows.add(DateEntry(_nextRowId++));
  }

  static const minCount = 1;
  static const maxCount = 20;

  final PantryRepository _repository;
  final int householdId;

  String _name = '';
  String _brand = '';
  bool _brandLocked = false;

  List<Product> _candidates = const [];
  Product? _product;
  bool _lookupDone = false;
  bool _isLookingUp = false;
  Future<void>? _pendingLookup;
  int _lookupRequest = 0;

  List<ProductCategory> _categories = const [];
  bool _isLoadingCategories = false;
  String? _categoriesError;
  ProductCategory? _category;

  int _nextRowId = 0;
  final List<DateEntry> _rows = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isLookingUp => _isLookingUp;

  bool get isSubmitting => _isSubmitting;

  bool get hasData =>
      _name.trim().isNotEmpty ||
      _brand.trim().isNotEmpty ||
      _rows.length > 1 ||
      _rows.any((row) => row.date != null || row.count != minCount);

  String get brand => _brand;

  bool get isBrandLocked => _brandLocked;

  List<ProductCategory> get categories => _categories;

  String? get categoriesError => _categoriesError;

  ProductCategory? get category => _category;

  List<DateEntry> get rows => List.unmodifiable(_rows);

  String? get errorMessage => _errorMessage;

  bool get isCategoryLocked => _product != null;

  bool get isCategoryEnabled =>
      _lookupDone && _product == null && !_isLoadingCategories && !_isSubmitting;

  bool get canSubmit =>
      _name.trim().isNotEmpty &&
      _lookupDone &&
      !_isLookingUp &&
      !_isSubmitting &&
      (_product != null || _category != null) &&
      _rows.isNotEmpty &&
      _rows.every((row) => row.date != null);

  void setName(String value) {
    if (value == _name) {
      return;
    }
    _name = value;
    _lookupRequest++;
    _pendingLookup = null;
    _isLookingUp = false;
    _lookupDone = false;
    _candidates = const [];
    if (_product != null) {
      _product = null;
      _category = null;
    }
    if (_brandLocked) {
      _brandLocked = false;
      _brand = '';
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

    List<Product> found;
    try {
      found = await _repository.searchProducts(householdId, name);
    } on DioException {
      found = const [];
    } on FormatException {
      found = const [];
    }

    if (request != _lookupRequest) {
      return;
    }
    final wanted = name.toLowerCase();
    _candidates = found.where((p) => p.name.trim().toLowerCase() == wanted).toList();
    _lookupDone = true;
    _isLookingUp = false;
    _resolve();
    notifyListeners();

    if (_product == null) {
      await loadCategories();
    }
  }

  void setBrand(String value) {
    if (value == _brand) {
      return;
    }
    _brand = value;
    if (_product != null) {
      _product = null;
      _category = null;
    }
    notifyListeners();
  }

  /// Called when the brand field loses focus.
  Future<void> resolveBrand() async {
    if (!_lookupDone || _isSubmitting) {
      return;
    }
    _resolve();
    notifyListeners();
    if (_product == null) {
      await loadCategories();
    }
  }

  /// Decides which existing product (if any) the typed name and brand point to.
  ///  - empty brand and exactly one product with this name: take it, fill and lock the brand
  ///  - otherwise: the product with this name and exactly this brand
  ///  allows creating products with same name but different brands
  void _resolve() {
    Product? match;
    var fillBrand = false;

    if (_brand.trim().isEmpty && _candidates.length == 1) {
      match = _candidates.first;
      fillBrand = true;
    } else {
      final wantedBrand = _brand.trim().toLowerCase();
      final matches = _candidates
          .where((p) => (p.brand ?? '').trim().toLowerCase() == wantedBrand)
          .toList();
      if (matches.isNotEmpty) {
        match = matches.firstWhere((p) => p.isCustom, orElse: () => matches.first);
      }
    }

    _product = match;
    if (match == null) {
      return;
    }
    _category = match.category;
    if (fillBrand) {
      _brand = match.brand ?? '';
      _brandLocked = true;
    }
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

  void addRow() {
    _rows.add(DateEntry(_nextRowId++));
    notifyListeners();
  }

  void removeRow(DateEntry row) {
    if (_rows.length > 1) {
      _rows.remove(row);
      notifyListeners();
    }
  }

  void setRowDate(DateEntry row, DateTime date) {
    row.date = date;
    notifyListeners();
  }

  void incrementRow(DateEntry row) {
    if (row.count < maxCount) {
      row.count++;
      notifyListeners();
    }
  }

  void decrementRow(DateEntry row) {
    if (row.count > minCount) {
      row.count--;
      notifyListeners();
    }
  }

  /// Creates the custom product if needed, then adds every date row. True on success.
  Future<bool> submit() async {
    if (_isSubmitting) {
      return false;
    }
    await lookup();
    if (_lookupDone) {
      _resolve();
      notifyListeners();
    }
    if (!canSubmit) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final done = <DateEntry>[];
    try {
      final product =
          _product ??
          await _repository.createCustomProduct(
            householdId,
            name: _name.trim(),
            brand: _brand.trim(),
            categoryId: _category?.id,
          );
      _product = product;
      for (final row in _rows) {
        await _repository.addItems(
          householdId,
          productId: product.id,
          expiryDate: row.date!,
          count: row.count,
        );
        done.add(row);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _failureMessage(_messageFor(e), done);
    } on FormatException {
      _errorMessage = _failureMessage('Unexpected response from the server.', done);
    }
    _rows.removeWhere(done.contains);
    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  String _failureMessage(String message, List<DateEntry> done) =>
      done.isEmpty ? message : 'Some dates were already added. $message';

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
