import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_bottom_navigation_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group_item.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/edit_item_dialog.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/edit_product_dialog.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  Future<void> _closeItem(
    PantryGroup product,
    PantryGroupItem item,
    String status,
  ) async {
    final actionLabel = status == 'eaten' ? 'eaten' : 'wasted';
    final actionTitle = status == 'eaten' ? 'Mark as eaten?' : 'Mark as wasted?';
    final actionColor = status == 'eaten' ? Colors.green.shade700 : Colors.orange.shade800;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionTitle),
        content: Text(
          'Are you sure you want to mark "${product.name}" '
          'expiring on ${_formatDate(item.expiryDate)} as $actionLabel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await widget.controller.closeItem(
      itemId: item.id,
      status: status,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked "${product.name}" as $actionLabel.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Something went wrong. Try again.',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmAndDeleteItem(
    PantryGroup product,
    PantryGroupItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(
          'Are you sure you want to delete "${product.name}" '
          'expiring on ${_formatDate(item.expiryDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return false;
    }

    final success = await widget.controller.deleteItem(item.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Something went wrong. Try again.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> _confirmAndDeleteGroup(PantryGroup product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Are you sure you want to delete all entries for "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete all',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return false;
    }

    for (final item in product.items) {
      await widget.controller.deleteItem(item.id);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        return Dismissible(
                          key: ValueKey('group_${product.id}_${product.items.length}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Delete all',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) => _confirmAndDeleteGroup(product),
                          child: GestureDetector(
                            onLongPress: () => showEditProductDialog(
                              context,
                              product: product,
                              controller: controller,
                            ),
                            child: PantryProductTile(
                              product: product,
                              onItemAction: (item) => showEditItemDialog(
                                context,
                                product: product,
                                item: item,
                                controller: controller,
                              ),
                              onDeleteItem: (item) => _confirmAndDeleteItem(product, item),
                              onCloseItem: (item, status) => _closeItem(product, item, status),
                            ),
                          ),
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
      bottomNavigationBar: AppBottomNavigationBar(household: widget.household),
    );
  }
}
