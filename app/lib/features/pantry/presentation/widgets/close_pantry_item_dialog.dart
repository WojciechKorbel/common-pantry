import 'package:flutter/material.dart';

Future<CloseItemDialogResult?> showClosePantryItemDialog({
  required BuildContext context,
  required String productName,
  required DateTime expiryDate,
  required String status,
}) {
  return showDialog<CloseItemDialogResult>(
    context: context,
    builder: (_) => ClosePantryItemDialog(
      productName: productName,
      expiryDate: expiryDate,
      status: status,
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
  });

  final String productName;
  final DateTime expiryDate;
  final String status;

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

  @override
  Widget build(BuildContext context) {
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
