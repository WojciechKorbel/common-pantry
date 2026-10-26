import 'dart:async';

import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/add_purchased_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pinned_action_layout.dart';
import 'package:flutter/material.dart';

class PurchasedItemForm extends StatefulWidget {
  const PurchasedItemForm({
    super.key,
    required this.household,
    required this.onHasDataChanged,
    this.initialProduct,
    this.initialBarcode,
  });

  final Household household;
  final ValueChanged<bool> onHasDataChanged;
  final Product? initialProduct;
  final String? initialBarcode;

  @override
  State<PurchasedItemForm> createState() => _PurchasedItemFormState();
}

class _PurchasedItemFormState extends State<PurchasedItemForm> {
  late final AddPurchasedController _controller;
  final _nameText = TextEditingController();
  final _brandText = TextEditingController();
  final _categoryText = TextEditingController();
  final _nameFocus = FocusNode();
  final _brandFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AddPurchasedController(
      Dependencies.pantryRepository,
      householdId: widget.household.id,
    )..addListener(_syncTexts);

    _nameFocus.addListener(_onNameFocusChanged);
    _brandFocus.addListener(_onBrandFocusChanged);

    if (widget.initialProduct != null) {
      final p = widget.initialProduct!;
      _controller.initializeWithScannedProduct(p);
      _nameText.text = p.name;
      _brandText.text = p.brand ?? '';
      _categoryText.text = p.category?.name ?? '';
    } else if (widget.initialBarcode != null) {
      _controller.loadCategories();
    }
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocusChanged);
    _brandFocus.removeListener(_onBrandFocusChanged);
    _controller
      ..removeListener(_syncTexts)
      ..dispose();
    _nameText.dispose();
    _brandText.dispose();
    _categoryText.dispose();
    _nameFocus.dispose();
    _brandFocus.dispose();
    super.dispose();
  }

  void _onNameFocusChanged() {
    if (!_nameFocus.hasFocus && widget.initialProduct == null) {
      _controller.lookup();
    }
  }

  void _onBrandFocusChanged() {
    if (!_brandFocus.hasFocus && widget.initialProduct == null) {
      _controller.resolveBrand();
    }
  }

  void _syncTexts() {
    if (_brandText.text != _controller.brand) {
      _brandText.text = _controller.brand;
    }
    final categoryName = _controller.category?.name ?? '';
    if (_categoryText.text != categoryName) {
      _categoryText.text = categoryName;
    }
    widget.onHasDataChanged(_controller.hasData);
  }

  Future<void> _pickDate(DateEntry row) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: row.date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      _controller.setRowDate(row, picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final success = await _controller.submit();
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      final navigator = Navigator.of(context);
      unawaited(Dependencies.pantryController.load());
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Items added to the pantry')));
    } else if (_controller.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final c = _controller;
        final rows = c.rows;

        return PinnedActionLayout(
          action: ElevatedButton(
            onPressed: c.canSubmit ? _submit : null,
            child: c.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameText,
                focusNode: _nameFocus,
                onChanged: c.setName,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onTapOutside: (_) => _nameFocus.unfocus(),
                decoration: InputDecoration(
                  labelText: 'Name',
                  suffixIcon: c.isLookingUp
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _brandText,
                focusNode: _brandFocus,
                enabled: !c.isBrandLocked && !c.isSubmitting,
                onChanged: c.setBrand,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onTapOutside: (_) => _brandFocus.unfocus(),
                decoration: InputDecoration(
                  labelText: 'Brand',
                  helperText: c.isBrandLocked ? 'Taken from an existing product' : null,
                  suffixIcon: c.isBrandLocked ? const Icon(Icons.lock_outline) : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownMenu<ProductCategory>(
                controller: _categoryText,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Category'),
                enabled: c.isCategoryEnabled,
                requestFocusOnTap: false,
                menuHeight: 300,
                leadingIcon: c.isCategoryLocked ? const Icon(Icons.lock_outline) : null,
                errorText: c.categoriesError,
                inputDecorationTheme: theme.inputDecorationTheme,
                menuStyle: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.surface),
                  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
                ),
                onSelected: c.setCategory,
                dropdownMenuEntries: [
                  for (final category in c.categories)
                    DropdownMenuEntry(value: category, label: category.name),
                ],
              ),
              const SizedBox(height: 24),
              for (final row in rows) ...[
                _DateRow(
                  key: ValueKey(row.id),
                  entry: row,
                  canRemove: rows.length > 1 && !c.isSubmitting,
                  onPickDate: () => _pickDate(row),
                  onDecrement: () => c.decrementRow(row),
                  onIncrement: () => c.incrementRow(row),
                  onRemove: () => c.removeRow(row),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: c.isSubmitting ? null : c.addRow,
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
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    super.key,
    required this.entry,
    required this.canRemove,
    required this.onPickDate,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  final DateEntry entry;
  final bool canRemove;
  final VoidCallback onPickDate;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = entry.date;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPickDate,
            child: InputDecorator(
              isEmpty: date == null,
              decoration: const InputDecoration(labelText: 'Expiry date'),
              child: Text(date == null ? '' : _formatDate(date)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: entry.count > AddPurchasedController.minCount ? onDecrement : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease',
        ),
        Container(
          width: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.count}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: entry.count < AddPurchasedController.maxCount ? onIncrement : null,
          icon: const Icon(Icons.add),
          tooltip: 'Increase',
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.delete_outline),
          color: theme.colorScheme.error,
          tooltip: 'Remove date',
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year}';
