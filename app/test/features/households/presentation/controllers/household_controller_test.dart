import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHouseholdsRepository implements HouseholdsRepository {
  List<Household> households = [];
  Object? error;

  @override
  Future<List<Household>> getHouseholds() async {
    if (error != null) throw error!;
    return households;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const home = Household(id: 1, name: 'Home');
  const work = Household(id: 2, name: 'Work');

  late _FakeHouseholdsRepository repository;
  late HouseholdController controller;

  setUp(() {
    repository = _FakeHouseholdsRepository();
    controller = HouseholdController(
      repository: repository,
      initial: home,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('loads households and keeps current household if present', () async {
    repository.households = [home, work];

    await controller.loadHouseholds();

    expect(controller.households, [home, work]);
    expect(controller.current, home);
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('selects the first household if current household is absent', () async {
    repository.households = [work];

    await controller.loadHouseholds();

    expect(controller.current, work);
  });

  test('select changes current household and notifies listeners', () {
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.select(work);

    expect(controller.current, work);
    expect(notifications, 1);
  });
}
