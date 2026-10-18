import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/empty_pantry_state.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pantry_product_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                      return const EmptyPantryState();
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
