import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/empty_pantry_state.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/no_matching_products_state.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pantry_product_tile.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pantry_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ExpiryFilterOption {
  all,
  fresh,
  soon,
  expired,
}

class PantryItemsScreen extends StatefulWidget {
  const PantryItemsScreen({
    super.key,
    required this.household,
    required this.controller,
  });

  final Household household;
  final PantryController controller;

  @override
  State<PantryItemsScreen> createState() => _PantryItemsScreenState();
}

class _PantryItemsScreenState extends State<PantryItemsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: widget.household.name,
        onBack: () => context.go('/households'),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              PantrySearchBar(
                controller: widget.controller,
                searchController: _searchController,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),

              Expanded(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, child) {
                    final controller = widget.controller;

                    if (controller.isLoading && !controller.hasLoaded) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (controller.errorMessage != null && !controller.hasLoaded) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: controller.load,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.visibleGroups.isEmpty) {
                      if (controller.groups.isEmpty) {
                        return const EmptyPantryState();
                      }

                      final hasActiveFilters =
                          controller.query.trim().isNotEmpty ||
                          controller.categoryId != null ||
                          controller.expiryFilter != null;

                      if (!hasActiveFilters) {
                        return const EmptyPantryState();
                      }

                      return NoMatchingProductsState(
                        onClearFilters: () {
                          _searchController.clear();
                          controller.setQuery('');
                          controller.setCategory(null);
                          controller.setExpiryFilter(null);
                        },
                      );
                    }

                    return ListView.separated(
                      itemCount: controller.visibleGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = controller.visibleGroups[index];
                        return PantryProductTile(
                          product: product,
                          onItemAction: null, // TODO: handle button click
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
