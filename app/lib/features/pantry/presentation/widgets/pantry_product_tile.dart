import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group_item.dart';
import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:flutter/material.dart';

class PantryProductTile extends StatefulWidget {
  const PantryProductTile({
    super.key,
    required this.product,
    this.onItemAction,
    this.onDeleteItem,
    this.onCloseItem,
  });

  final PantryGroup product;
  final ValueChanged<PantryGroupItem>? onItemAction;
  final Future<bool> Function(PantryGroupItem item)? onDeleteItem;
  final void Function(PantryGroupItem item, String status)? onCloseItem;

  @override
  State<PantryProductTile> createState() => _PantryProductTileState();
}

class _PantryProductTileState extends State<PantryProductTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final items = [...product.items]..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        leading: SizedBox(
          width: 56,
          height: 56,
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.fastfood,
                      size: 32,
                    ),
                  ),
                )
              : const Icon(
                  Icons.fastfood,
                  size: 32,
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (!_isExpanded) ...[
                    const SizedBox(height: 6),
                    _buildExpiryChip(context, product.earliestExpiry),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.itemCount}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Quantity', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          ...items.map(
            (item) => _buildDismissibleItemRow(context, item),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleItemRow(BuildContext context, PantryGroupItem item) {
    final row = _buildItemRow(
      context,
      item,
      widget.onItemAction != null ? () => widget.onItemAction!(item) : null,
    );

    if (widget.onDeleteItem == null) {
      return row;
    }

    return Dismissible(
      key: ValueKey('pantry_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => widget.onDeleteItem!(item),
      child: row,
    );
  }

  Widget _buildExpiryChip(BuildContext context, DateTime date) {
    final status = expiryStatusOf(date, DateTime.now());
    final colors = Theme.of(context).extension<ExpiryColors>()!;

    final (foreground, background) = switch (status) {
      ExpiryStatus.expired => (colors.onExpired, colors.expired),
      ExpiryStatus.soon => (colors.onSoon, colors.soon),
      ExpiryStatus.fresh => (colors.onFresh, colors.fresh),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    PantryGroupItem item,
    VoidCallback? onItemAction,
  ) {
    final expiryDate = item.expiryDate;
    final addedBy = item.addedBy?.username;
    final status = expiryStatusOf(expiryDate, DateTime.now());
    final colors = Theme.of(context).extension<ExpiryColors>()!;

    final (foreground, background) = switch (status) {
      ExpiryStatus.expired => (colors.onExpired, colors.expired),
      ExpiryStatus.soon => (colors.onSoon, colors.soon),
      ExpiryStatus.fresh => (colors.onFresh, colors.fresh),
    };

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 4,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 14, color: foreground),
                const SizedBox(width: 4),
                Text(
                  _formatDate(expiryDate),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.freshContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      addedBy ?? 'Unknown user',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onCloseItem != null ? () => widget.onCloseItem!(item, 'eaten') : null,
            icon: const Icon(Icons.restaurant_outlined),
            color: Colors.green.shade700,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'Mark as eaten',
          ),
          IconButton(
            onPressed: widget.onCloseItem != null
                ? () => widget.onCloseItem!(item, 'wasted')
                : null,
            icon: const Icon(Icons.cancel_outlined),
            color: Colors.orange.shade800,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'Mark as wasted',
          ),
          IconButton(
            onPressed: onItemAction,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.textSecondary,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit item',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}
