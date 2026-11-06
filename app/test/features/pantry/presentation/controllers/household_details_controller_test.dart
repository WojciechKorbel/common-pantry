import 'package:common_pantry/features/pantry/presentation/controllers/household_details_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdDetailsController controller;

  setUp(() {
    repository = FakePantryRepository();
    controller = HouseholdDetailsController(repository: repository, householdId: 1);
  });

  tearDown(() => controller.dispose());

  group('load', () {
    test('stores the household details', () async {
      await controller.load();

      expect(controller.details, homeDetails);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('shows a message when details cannot be loaded', () async {
      repository.detailsError = connectionError();

      await controller.load();

      expect(controller.details, isNull);
      expect(controller.errorMessage, 'Failed to load household details.');
      expect(controller.isLoading, isFalse);
    });
  });

  group('members', () {
    test('each member action is sent and the details are reloaded', () async {
      expect(await controller.promoteMember(2), isTrue);
      expect(await controller.demoteMember(2), isTrue);
      expect(await controller.removeMember(3), isTrue);

      expect(repository.householdActions, ['promote 2', 'demote 2', 'remove 3']);
      expect(repository.detailsRequests, 3);
      expect(controller.details, homeDetails);
    });

    test('a failed member action shows a message and does not reload', () async {
      repository.householdActionError = serverError(403);

      expect(await controller.removeMember(3), isFalse);

      expect(controller.errorMessage, 'Failed to update household members.');
      expect(controller.isUpdating, isFalse);
      expect(repository.detailsRequests, 0);
    });
  });

  group('household', () {
    test('renaming trims the name and reloads the details', () async {
      expect(await controller.updateHouseholdName('  Dom  '), isTrue);

      expect(repository.householdActions, ['rename Dom']);
      expect(repository.detailsRequests, 1);
      expect(controller.isUpdating, isFalse);
    });

    test('a failed rename shows a message', () async {
      repository.householdActionError = serverError(400);

      expect(await controller.updateHouseholdName('Dom'), isFalse);
      expect(controller.errorMessage, 'Failed to update household name.');
    });

    test('leaving the household', () async {
      expect(await controller.leaveHousehold(), isTrue);
      expect(repository.householdActions, ['leave']);

      repository.householdActionError = connectionError();
      expect(await controller.leaveHousehold(), isFalse);
      expect(controller.errorMessage, 'Failed to leave household.');
    });
  });
}
