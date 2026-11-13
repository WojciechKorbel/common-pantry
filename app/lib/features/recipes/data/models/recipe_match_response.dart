import 'package:common_pantry/features/recipes/data/models/recipe.dart';

class RecipeMatchResponse {
  const RecipeMatchResponse({
    required this.query,
    required this.ingredients,
    required this.recipesCount,
    required this.recipes,
  });

  final String query;
  final List<Map<String, dynamic>> ingredients;
  final int recipesCount;
  final List<Recipe> recipes;

  factory RecipeMatchResponse.fromJson(Map<String, dynamic> json) {
    return RecipeMatchResponse(
      query: json['query'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      recipesCount: json['recipes_count'] as int? ?? 0,
      recipes: (json['recipes'] as List<dynamic>? ?? [])
          .map(
            (e) => Recipe.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}
