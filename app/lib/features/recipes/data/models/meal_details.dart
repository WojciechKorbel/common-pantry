class MealDetails {
  const MealDetails({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.category,
    required this.area,
    required this.instructions,
    required this.ingredients,
    this.tags,
    this.youtube,
    this.source,
  });

  final String id;
  final String name;
  final String thumbnail;
  final String category;
  final String area;
  final String instructions;
  final List<MealIngredient> ingredients;
  final String? tags;
  final String? youtube;
  final String? source;

  factory MealDetails.fromJson(Map<String, dynamic> json) {
    final ingredients = <MealIngredient>[];

    for (var i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i']?.toString().trim() ?? '';
      final measure = json['strMeasure$i']?.toString().trim() ?? '';

      if (ingredient.isNotEmpty) {
        ingredients.add(
          MealIngredient(
            name: ingredient,
            measure: measure,
          ),
        );
      }
    }

    return MealDetails(
      id: json['idMeal']?.toString() ?? '',
      name: json['strMeal']?.toString() ?? '',
      thumbnail: json['strMealThumb']?.toString() ?? '',
      category: json['strCategory']?.toString() ?? '',
      area: json['strArea']?.toString() ?? '',
      instructions: json['strInstructions']?.toString() ?? '',
      ingredients: ingredients,
      tags: json['strTags']?.toString(),
      youtube: json['strYoutube']?.toString(),
      source: json['strSource']?.toString(),
    );
  }
}

class MealIngredient {
  const MealIngredient({
    required this.name,
    required this.measure,
  });

  final String name;
  final String measure;
}
