import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/features/recipes/data/models/meal_details.dart';
import 'package:common_pantry/features/recipes/data/models/recipe_match_response.dart';
import 'package:dio/dio.dart';

class RecipeRepository {
  RecipeRepository(this.api);

  final ApiClient api;

  final Dio _mealDbApi = Dio(
    BaseOptions(
      baseUrl: 'https://www.themealdb.com/api/json/v1/1/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<RecipeMatchResponse> getRecipes(String productName) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/recipe-match/',
      data: {'name': productName},
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('Empty recipe response');
    }

    return RecipeMatchResponse.fromJson(data);
  }

  Future<MealDetails> getMealDetails(String mealId) async {
    final response = await _mealDbApi.get<Map<String, dynamic>>(
      'lookup.php',
      queryParameters: {'i': mealId},
    );

    final meals = response.data?['meals'] as List<dynamic>?;

    if (meals == null || meals.isEmpty) {
      throw const FormatException('Recipe not found');
    }

    final meal = meals.first;

    if (meal is! Map<String, dynamic>) {
      throw const FormatException('Invalid meal response');
    }

    return MealDetails.fromJson(meal);
  }
}
