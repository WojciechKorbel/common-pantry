import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';

class StatisticsRepository {
  StatisticsRepository(this.api);

  final ApiClient api;

  Future<FoodWasteStatistics> getFoodWasteStatistics(int householdId, {
    String period = '30d',
  }) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/api/households/$householdId/statistics/food-waste/',
      queryParameters: {'period': period},
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('Empty statistics response.');
    }

    return FoodWasteStatistics.fromJson(data);
  }
}
