import 'package:common_pantry/features/stats/data/repositories/statistics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http.dart';

void main() {
  late FakeHttpAdapter server;
  late StatisticsRepository repository;

  setUp(() {
    server = FakeHttpAdapter();
    repository = StatisticsRepository(fakeApiClient(server));
  });

  test('loads statistics for the chosen period', () async {
    server.answer = (_) => (
      status: 200,
      body: {
        'period': '7d',
        'summary': {'active_count': 3, 'eaten_count': 1, 'wasted_count': 1, 'waste_percentage': 50},
        'timeline': <dynamic>[],
        'categories': <dynamic>[],
        'top_wasted_products': <dynamic>[],
        'expiry': {'expired': 1, 'not_expired': 0},
      },
    );

    final statistics = await repository.getFoodWasteStatistics(1, period: '7d');

    expect(server.calls, [('GET', '/api/households/1/statistics/food-waste/')]);
    expect(server.requests.single.query, {'period': '7d'});
    expect(statistics.summary.wastePercentage, 50.0);
  });

  test('an empty response throws FormatException', () async {
    server.answer = (_) => (status: 200, body: null);

    await expectLater(repository.getFoodWasteStatistics(1), throwsFormatException);
  });
}
