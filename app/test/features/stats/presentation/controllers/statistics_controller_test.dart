import 'package:common_pantry/features/stats/presentation/controllers/statistics_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_statistics_repository.dart';

void main() {
  late FakeStatisticsRepository repository;
  late StatisticsController controller;

  setUp(() {
    repository = FakeStatisticsRepository();
    controller = StatisticsController(repository, householdId: 1);
  });

  tearDown(() => controller.dispose());

  test('loads the last 30 days by default', () async {
    await controller.load();

    expect(repository.requestedPeriods, ['30d']);
    expect(controller.statistics?.period, '30d');
    expect(controller.hasLoaded, isTrue);
    expect(controller.isLoading, isFalse);
  });

  test('choosing another period loads its statistics', () async {
    await controller.setPeriod('7d');

    expect(controller.period, '7d');
    expect(repository.requestedPeriods, ['7d']);
    expect(controller.statistics?.period, '7d');
  });

  test('ignores an unknown period and the period already shown', () async {
    await controller.setPeriod('1y');
    await controller.setPeriod('30d');

    expect(controller.period, '30d');
    expect(repository.requestedPeriods, isEmpty);
  });

  test('shows a message for each kind of error', () async {
    final cases = <(Object, String)>[
      (connectionError(), 'Cannot reach the server. Check your connection.'),
      (serverError(400), 'Invalid statistics period.'),
      (serverError(403), 'You do not have access to this household.'),
      (serverError(404), 'Household not found.'),
      (const FormatException('Empty statistics response.'), 'Invalid statistics response.'),
      (StateError('unexpected'), 'Something went wrong. Try again.'),
    ];

    for (final (error, message) in cases) {
      repository.error = error;

      await controller.load();

      expect(controller.errorMessage, message);
      expect(controller.hasLoaded, isFalse);
      expect(controller.isLoading, isFalse);
    }
  });

  test('a failed refresh keeps the previous statistics', () async {
    await controller.load();

    repository.error = serverError(500);
    await controller.refresh();

    expect(controller.statistics, isNotNull);
    expect(controller.errorMessage, 'Something went wrong. Try again.');
  });

  test(
    'changing the period during a load shows the statistics of the new period',
    () async {
      repository.holdResponses = true;

      final firstLoad = controller.load();
      final periodChange = controller.setPeriod('7d');
      for (final (index, answer) in repository.pending.indexed) {
        answer.complete(aStatistics(period: repository.requestedPeriods[index]));
      }
      await Future.wait([firstLoad, periodChange]);

      expect(controller.period, '7d');
      expect(controller.statistics?.period, '7d');
    },
    // TODO: remove when fixed
    skip: 'Known bug: a period chosen during a load is never fetched',
  );
}
