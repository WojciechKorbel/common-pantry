import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:flutter/material.dart';

enum ExpiryFilterOption {
  all,
  fresh,
  soon,
  expired,
}

class PantrySearchBar extends StatelessWidget {
  const PantrySearchBar({
    super.key,
    required this.controller,
    required this.searchController,
  });

  final PantryController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: controller.setQuery,
            decoration: InputDecoration(
              hintText: 'Search for a product or brand...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            final selectedFilter = controller.expiryFilter;

            return PopupMenuButton<ExpiryFilterOption>(
              tooltip: 'Filter by expiry date',
              icon: Badge(
                isLabelVisible: selectedFilter != null,
                smallSize: 8,
                child: Icon(
                  Icons.tune,
                  color: selectedFilter != null ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (option) {
                controller.setExpiryFilter(
                  switch (option) {
                    ExpiryFilterOption.all => null,
                    ExpiryFilterOption.fresh => ExpiryStatus.fresh,
                    ExpiryFilterOption.soon => ExpiryStatus.soon,
                    ExpiryFilterOption.expired => ExpiryStatus.expired,
                  },
                );
              },
              itemBuilder: (context) => [
                _buildMenuItem(
                  ExpiryFilterOption.all,
                  'All',
                  selectedFilter == null,
                ),
                _buildMenuItem(
                  ExpiryFilterOption.fresh,
                  'Fresh',
                  selectedFilter == ExpiryStatus.fresh,
                ),
                _buildMenuItem(
                  ExpiryFilterOption.soon,
                  'Expiring soon',
                  selectedFilter == ExpiryStatus.soon,
                ),
                _buildMenuItem(
                  ExpiryFilterOption.expired,
                  'Expired',
                  selectedFilter == ExpiryStatus.expired,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  PopupMenuItem<ExpiryFilterOption> _buildMenuItem(
    ExpiryFilterOption value,
    String label,
    bool selected,
  ) {
    return PopupMenuItem<ExpiryFilterOption>(
      value: value,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (selected) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }
}
