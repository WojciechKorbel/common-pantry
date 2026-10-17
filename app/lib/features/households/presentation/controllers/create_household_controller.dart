import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:flutter/foundation.dart';

class CreateHouseholdController extends ChangeNotifier {
  CreateHouseholdController(this._repository);

  final HouseholdsRepository _repository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Household? _createdHousehold;

  Household? get createdHousehold => _createdHousehold;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> createHousehold(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = 'Enter a household name.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _createdHousehold = null;
    notifyListeners();

    try {
      _createdHousehold = await _repository.createHousehold(
        name: trimmedName,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create household: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
