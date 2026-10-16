import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/foundation.dart';

class HouseholdController extends ChangeNotifier {
  HouseholdController({required Household initial}) : _current = initial;

  Household _current;

  Household get current => _current;

  void select(Household household) {
    if (household.id == _current.id) {
      return;
    }
    _current = household;
    notifyListeners();
  }
}
