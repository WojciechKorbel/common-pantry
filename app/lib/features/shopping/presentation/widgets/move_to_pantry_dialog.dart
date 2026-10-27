import 'dart:async';

import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pinned_action_layout.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_move.dart';
import 'package:flutter/material.dart';

/// Asks for the expiry dates of the given bought items one item at a time,
/// then moves them all to the pantry in a single request.
Future<void> showMoveToPantryDialog(
  BuildContext context,
  List<ShoppingItem> items,
) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierDismissible: false,
    builder: (_) => MoveToPantryDialog(items: items),
  );
}

class MoveToPantryDialog extends StatefulWidget {
  const MoveToPantryDialog({super.key, required this.items});

  final List<ShoppingItem> items;

  @override
  State<MoveToPantryDialog> createState() => _MoveToPantryDialogState();
}

class _MoveToPantryDialogState extends State<MoveToPantryDialog> {
  static const _maxRows = 20;

  late final List<List<DateTime?>> _dates;

  late final List<TextEditingController> _brands;
  int _index = 0;
  bool _isSubmitting = false;

  ShoppingItem get _item => widget.items[_index];

  List<DateTime?> get _rows => _dates[_index];

  bool get _isLast => _index == widget.items.length - 1;

  bool get _stepComplete => _rows.every((date) => date != null);

  bool get _hasData =>
      _dates.any((rows) => rows.any((date) => date != null)) ||
      _brands.any((controller) => controller.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _dates = [
      for (final item in widget.items)
        List<DateTime?>.filled(item.packageCount, null, growable: true),
    ];
    _brands = [for (final _ in widget.items) TextEditingController()];
  }

  @override
  void dispose() {
    for (final controller in _brands) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _attemptClose() async {
    if (!_hasData || _isSubmitting) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Nothing has been added to the pantry yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate(int row) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _rows[row] ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _rows[row] = picked);
    }
  }

  void _next() {
    if (_isLast) {
      _submit();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final moves = [
      for (var i = 0; i < widget.items.length; i++)
        ShoppingMove(
          itemId: widget.items[i].id,
          expiryDates: _dates[i].whereType<DateTime>().toList(),
          brand: _brands[i].text.trim().isEmpty ? null : _brands[i].text.trim(),
        ),
    ];

    final controller = Dependencies.shoppingController;
    final success = await controller.moveToPantry(moves);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      final navigator = Navigator.of(context);
      unawaited(Dependencies.pantryController.load());
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Items added to the pantry')),
      );
    } else if (controller.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _rows;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _attemptClose();
        }
      },
      child: Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: _attemptClose,
            ),
            title: Text(
              'Item ${_index + 1} of ${widget.items.length}',
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (_index + 1) / widget.items.length,
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: PinnedActionLayout(
              action: Row(
                children: [
                  if (_index > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => setState(() => _index--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _stepComplete && !_isSubmitting ? _next : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLast ? 'Add to pantry' : 'Next'),
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(_item.name, style: theme.textTheme.headlineSmall),
                  if (_item.showQuantity) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bought: ${_item.quantityLabel}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    key: ValueKey('brand_$_index'),
                    controller: _brands[_index],
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      labelText: 'Brand (optional)',
                      helperText: 'Used to match a product that already exists',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Set an expiry date for each package.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < rows.length; i++) ...[
                    _DateRow(
                      index: i,
                      date: rows[i],
                      canRemove: rows.length > 1 && !_isSubmitting,
                      onPickDate: () => _pickDate(i),
                      onRemove: () => setState(() => rows.removeAt(i)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: rows.length >= _maxRows || _isSubmitting
                        ? null
                        : () => setState(() => rows.add(null)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add another date'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.index,
    required this.date,
    required this.canRemove,
    required this.onPickDate,
    required this.onRemove,
  });

  final int index;
  final DateTime? date;
  final bool canRemove;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = this.date;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPickDate,
            child: InputDecorator(
              isEmpty: date == null,
              decoration: InputDecoration(
                labelText: 'Package ${index + 1} · expiry date',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(date == null ? '' : _formatDate(date)),
            ),
          ),
        ),
        IconButton(
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.delete_outline),
          color: theme.colorScheme.error,
          tooltip: 'Remove package',
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year}';
