import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:flutter/foundation.dart';

class HouseholdDetailsController extends ChangeNotifier {
  HouseholdDetailsController({
    required this._repository,
    required this._householdId,
  });

  final PantryRepository _repository;
  final int _householdId;

  HouseholdDetails? _details;

  HouseholdDetails? get details => _details;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _details = await _repository.getHouseholdDetails(_householdId);
    } catch (e) {
      _errorMessage = 'Failed to load household details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isUpdating = false;

  bool get isUpdating => _isUpdating;

  Future<bool> promoteMember(int userId) {
    return _performMemberAction(
      () => _repository.promoteMember(_householdId, userId),
    );
  }

  Future<bool> demoteMember(int userId) {
    return _performMemberAction(
      () => _repository.demoteMember(_householdId, userId),
    );
  }

  Future<bool> removeMember(int userId) {
    return _performMemberAction(
      () => _repository.removeMember(_householdId, userId),
    );
  }

  Future<bool> _performMemberAction(
    Future<void> Function() action,
  ) async {
    if (_isUpdating) return false;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _details = await _repository.getHouseholdDetails(_householdId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update household members.';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> updateHouseholdName(String name) async {
    if (_isUpdating) return false;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateHouseholdName(
        _householdId,
        name: name.trim(),
      );

      final updatedDetails = await _repository.getHouseholdDetails(_householdId);

      _details = updatedDetails;
      return true;
    } catch (_) {
      _errorMessage = 'Failed to update household name.';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> leaveHousehold() async {
    try {
      await _repository.leaveHousehold(_householdId);
      return true;
    } catch (_) {
      _errorMessage = 'Failed to leave household.';
      notifyListeners();
      return false;
    }
  }
}
