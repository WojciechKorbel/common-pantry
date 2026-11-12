class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.matchScore,
    required this.matchedIngredients,
  });

  final String id;
  final String name;
  final String thumbnail;
  final double matchScore;
  final List<String> matchedIngredients;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
      matchedIngredients: (json['matched_ingredients'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
