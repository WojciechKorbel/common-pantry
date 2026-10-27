import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:flutter/material.dart';

/// One card on the shopping list: checkbox, name, "Added by" and (once checked) "Bought by".
class ShoppingItemTile extends StatelessWidget {
  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final ShoppingItem item;
  final ValueChanged<bool> onToggle;

  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Dismissible(
      key: ValueKey('shopping_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => onDelete(),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: item.isBought,
          onChanged: (value) => onToggle(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: item.isBought ? TextDecoration.lineThrough : null,
              color: item.isBought ? muted : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Added by ${item.addedBy?.username ?? 'Unknown user'}'),
              if (item.isBought) Text('Bought by ${item.boughtBy?.username ?? 'Unknown user'}'),
            ],
          ),
          secondary: item.showQuantity
              ? Text(item.quantityLabel, style: theme.textTheme.titleMedium)
              : null,
        ),
      ),
    );
  }
}
