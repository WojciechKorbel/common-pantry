import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:flutter/foundation.dart';

class HouseholdController extends ChangeNotifier {
  HouseholdController({
    required HouseholdsRepository repository,
    required Household initial,
  }) : _repository = repository,
       _current = initial;

  final HouseholdsRepository _repository;

  Household _current;

  Household get current => _current;

  List<Household> _households = [];

  List<Household> get households => List.unmodifiable(_households);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> loadHouseholds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _households = await _repository.getHouseholds();

      if (_households.isNotEmpty && !_households.any((h) => h.id == _current.id)) {
        _current = _households.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void select(Household household) {
    if (_current.id == household.id) return;

    _current = household;
    notifyListeners();
  }
}
