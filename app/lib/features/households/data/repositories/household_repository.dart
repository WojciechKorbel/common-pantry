import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/features/households/data/models/household.dart';

class HouseholdsRepository {
  HouseholdsRepository(this.api);

  final ApiClient api;

  Future<List<Household>> getHouseholds() async {
    final response = await api.dio.get<dynamic>('/api/households/');

    final data = response.data as List<dynamic>;

    return data.map((item) {
      return Household.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<Household> createHousehold({
    required String name,
  }) async {
    final response = await api.dio.post<dynamic>(
      '/api/households/',
      data: {'name': name},
    );

    return Household.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
