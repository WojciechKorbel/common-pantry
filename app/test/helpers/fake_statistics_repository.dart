import 'dart:async';

import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:common_pantry/features/stats/data/repositories/statistics_repository.dart';

import 'builders.dart';

/// In-memory [StatisticsRepository]. Answers with statistics for the requested
/// period, or holds the answers until the test completes them.
class FakeStatisticsRepository implements StatisticsRepository {
  Object? error;
  bool holdResponses = false;

  final requestedPeriods = <String>[];

  /// Answers waiting for the test, in request order (only with [holdResponses]).
  final pending = <Completer<FoodWasteStatistics>>[];

  @override
  Future<FoodWasteStatistics> getFoodWasteStatistics(
    int householdId, {
    String period = '30d',
  }) async {
    requestedPeriods.add(period);
    if (error case final Object error) {
      throw error;
    }
    if (holdResponses) {
      final completer = Completer<FoodWasteStatistics>();
      pending.add(completer);
      return completer.future;
    }
    return aStatistics(period: period);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
