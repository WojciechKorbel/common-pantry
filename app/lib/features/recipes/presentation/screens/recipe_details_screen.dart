import 'package:common_pantry/features/recipes/presentation/controllers/recipe_controller.dart';
import 'package:material_ui/material_ui.dart';

class RecipeDetailsScreen extends StatefulWidget {
  const RecipeDetailsScreen({
    super.key,
    required this.mealId,
    required this.controller,
  });

  final String mealId;
  final RecipeController controller;

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.controller.loadMealDetails(widget.mealId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe details'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;

            if (controller.isDetailsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.detailsErrorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.detailsErrorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.loadMealDetails(widget.mealId),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final meal = controller.mealDetails;

            if (meal == null) {
              return const Center(
                child: Text('Recipe not found.'),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth >= 900;

                final mealHeader = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (meal.category.isNotEmpty)
                          Chip(
                            avatar: const Icon(
                              Icons.category,
                              size: 16,
                            ),
                            label: Text(meal.category),
                          ),
                        if (meal.area.isNotEmpty)
                          Chip(
                            avatar: const Icon(
                              Icons.public,
                              size: 16,
                            ),
                            label: Text(meal.area),
                          ),
                      ],
                    ),
                  ],
                );

                final ingredientsSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredients',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...meal.ingredients.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(ingredient.name),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ingredient.measure,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                final instructionsSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      meal.instructions.isNotEmpty
                          ? meal.instructions
                          : 'No instructions available.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ],
                );

                final tagsSection = meal.tags != null && meal.tags!.trim().isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Tags: ${meal.tags}',
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : const SizedBox.shrink();

                if (isLandscape) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: meal.thumbnail.isNotEmpty
                                      ? Image.network(
                                          meal.thumbnail,
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const SizedBox(
                                            height: 180,
                                            child: Center(
                                              child: Icon(
                                                Icons.restaurant,
                                                size: 64,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(
                                          height: 180,
                                          child: Center(
                                            child: Icon(
                                              Icons.restaurant,
                                              size: 64,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                mealHeader,
                                const SizedBox(height: 24),
                                ingredientsSection,
                                tagsSection,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // RIGHT COLUMN
                        Expanded(
                          flex: 6,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: instructionsSection,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (meal.thumbnail.isNotEmpty)
                      Image.network(
                        meal.thumbnail,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 180,
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mealHeader,
                          const SizedBox(height: 24),
                          ingredientsSection,
                          const SizedBox(height: 24),
                          instructionsSection,
                          tagsSection,
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
