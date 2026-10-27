import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_bottom_navigation_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:common_pantry/features/shopping/presentation/controllers/shopping_controller.dart';
import 'package:common_pantry/features/shopping/presentation/widgets/add_shopping_item_dialog.dart';
import 'package:common_pantry/features/shopping/presentation/widgets/empty_shopping_state.dart';
import 'package:common_pantry/features/shopping/presentation/widgets/move_to_pantry_dialog.dart';
import 'package:common_pantry/features/shopping/presentation/widgets/shopping_item_tile.dart';
import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key, required this.household});

  final Household household;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  ShoppingController get _controller => Dependencies.shoppingController;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _errorOrDefault => _controller.errorMessage ?? 'Something went wrong. Try again.';

  Future<void> _toggle(ShoppingItem item, bool isBought) async {
    final success = await _controller.setBought(item.id, isBought);
    if (!success && mounted) {
      _showMessage(_errorOrDefault);
    }
  }

  Future<bool> _delete(ShoppingItem item) async {
    final success = await _controller.deleteItem(item.id);
    if (!mounted) return success;
    _showMessage(success ? 'Item removed' : _errorOrDefault);
    return success;
  }

  Future<void> _refresh() async {
    await _controller.load();
    if (mounted && _controller.errorMessage != null) {
      _showMessage(_controller.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Shopping list'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final controller = _controller;

            if (controller.isLoading && !controller.hasLoaded) {
              return const Center(child: CircularProgressIndicator());
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

            if (controller.items.isEmpty) {
              return const EmptyShoppingState();
            }

            final toBuy = controller.toBuy;
            final bought = controller.bought;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                children: [
                  const _SectionHeader(title: 'To buy'),
                  if (toBuy.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Nothing left to buy.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final item in toBuy) _buildTile(item),
                  if (bought.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Bought (${bought.length})',
                      action: FilledButton.tonal(
                        onPressed: () => showMoveToPantryDialog(context, bought),
                        child: const Text('Add all to pantry'),
                      ),
                    ),
                    for (final item in bought) _buildTile(item),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddShoppingItemDialog(context),
        tooltip: 'Add to shopping list',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AppBottomNavigationBar(household: widget.household),
    );
  }

  Widget _buildTile(ShoppingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShoppingItemTile(
        item: item,
        onToggle: (value) => _toggle(item, value),
        onDelete: () => _delete(item),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
