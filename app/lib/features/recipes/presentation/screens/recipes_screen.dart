import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/recipes/data/models/recipe.dart';
import 'package:common_pantry/features/recipes/presentation/controllers/recipe_controller.dart';
import 'package:common_pantry/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:common_pantry/features/recipes/presentation/widgets/recipes_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({
    super.key,
    required this.household,
    required this.productName,
    required this.controller,
  });

  final Household household;
  final String productName;
  final RecipeController controller;

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.productName);
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return RecipeCard(
      recipe: recipe,
      onTap: () {
        context.push('/recipes/${recipe.id}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Recipes',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;

            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.errorMessage!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => controller.load(widget.productName),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }

            if (controller.recipes.isEmpty) {
              return RecipesEmptyState(
                productName: widget.productName,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMultiColumn = constraints.maxWidth >= 900;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1200,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMultiColumn) ...[
                            Text(
                              'Recipes with ${widget.productName}',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Expanded(
                            child: isMultiColumn
                                ? GridView.builder(
                                    padding: const EdgeInsets.only(
                                      bottom: 16,
                                    ),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.0,
                                    ),
                                    itemCount: controller.recipes.length,
                                    itemBuilder: (context, index) {
                                      final recipe = controller.recipes[index];

                                      return _buildRecipeCard(recipe);
                                    },
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(
                                      bottom: 16,
                                    ),
                                    itemCount: controller.recipes.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final recipe = controller.recipes[index];

                                      return _buildRecipeCard(recipe);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
