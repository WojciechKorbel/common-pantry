import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_empty_state.dart';
import 'package:flutter/material.dart';

class TopWastedProductsList extends StatelessWidget {
  const TopWastedProductsList({
    super.key,
    required this.products,
  });

  final List<TopWastedProduct> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (products.isEmpty) {
      return const StatisticsEmptyState(
        title: 'No wasted products',
        message:
            'There are no wasted products in this period. '
            'Products marked as wasted will appear here.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text('${index + 1}'),
          ),
          title: Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: product.brand?.isNotEmpty == true ? Text(product.brand!) : null,
          trailing: Text(
            '${product.count}×',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
