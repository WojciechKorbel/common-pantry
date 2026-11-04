import 'package:flutter/material.dart';

Future<CloseItemDialogResult?> showClosePantryItemDialog({
  required BuildContext context,
  required String productName,
  required DateTime expiryDate,
  required String status,
  required String origin,
}) {
  return showDialog<CloseItemDialogResult>(
    context: context,
    builder: (_) => ClosePantryItemDialog(
      productName: productName,
      expiryDate: expiryDate,
      status: status,
      origin: origin,
    ),
  );
}

class CloseItemDialogResult {
  const CloseItemDialogResult({
    required this.addToShoppingList,
  });

  final bool addToShoppingList;
}

class ClosePantryItemDialog extends StatefulWidget {
  const ClosePantryItemDialog({
    super.key,
    required this.productName,
    required this.expiryDate,
    required this.status,
    required this.origin,
  });

  final String productName;
  final DateTime expiryDate;
  final String status;
  final String origin;

  @override
  State<ClosePantryItemDialog> createState() => _ClosePantryItemDialogState();
}

class _ClosePantryItemDialogState extends State<ClosePantryItemDialog> {
  bool _addToShoppingList = false;

  String get _actionLabel => widget.status == 'eaten' ? 'eaten' : 'wasted';

  String get _actionTitle => widget.status == 'eaten' ? 'Mark as eaten?' : 'Mark as wasted?';

  Color get _actionColor =>
      widget.status == 'eaten' ? Colors.green.shade700 : Colors.orange.shade800;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  bool get _canAddToShoppingList => widget.origin == 'purchased';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // debugPrint('Pantry item origin: "${widget.origin}"');
    // debugPrint('Can add to shopping list: $_canAddToShoppingList');
    return AlertDialog(
      title: Text(_actionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to mark "${widget.productName}" '
            'expiring on ${_formatDate(widget.expiryDate)} as $_actionLabel?',
          ),

          if (widget.origin == 'homemade') ...[
            const SizedBox(height: 12),
            Text(
              'Homemade products cannot be added to the shopping list.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],

          if (_canAddToShoppingList) ...[
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _addToShoppingList,
              onChanged: (value) {
                setState(() {
                  _addToShoppingList = value ?? false;
                });
              },
              title: const Text(
                'Add to shopping list',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Add this product so you can buy it again.',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              CloseItemDialogResult(
                addToShoppingList: _addToShoppingList,
              ),
            );
          },
          child: Text(
            'Confirm',
            style: TextStyle(
              color: _actionColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
