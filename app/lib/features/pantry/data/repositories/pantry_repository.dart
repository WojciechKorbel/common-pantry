import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';

class PantryRepository {
  PantryRepository(this.api);

  final ApiClient api;

  /// Active pantry items grouped by product, soonest expiry first.
  Future<List<PantryGroup>> getPantry(int householdId) async {
    final response = await api.dio.get<List<dynamic>>('/api/households/$householdId/pantry/');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty pantry response');
    }
    return data
        .map(
          (group) => switch (group) {
            final Map<String, dynamic> json => PantryGroup.fromJson(json),
            _ => throw const FormatException('Invalid pantry group'),
          },
        )
        .toList();
  }
}
