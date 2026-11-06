import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';

/// In-memory [HouseholdsRepository]. Methods are added as tests need them.
class FakeHouseholdsRepository implements HouseholdsRepository {
  List<Household> households = [];

  @override
  Future<List<Household>> getHouseholds() async => households;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}