import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
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

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Recipes with ${widget.productName}',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ...controller.recipes.map(
                  (recipe) => RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      context.push('/recipes/${recipe.id}');
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
