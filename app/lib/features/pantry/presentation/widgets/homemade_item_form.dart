import 'dart:async';

import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/add_manually_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pinned_action_layout.dart';
import 'package:flutter/material.dart';

class HomemadeItemForm extends StatefulWidget {
  const HomemadeItemForm({
    super.key,
    required this.household,
    required this.onHasDataChanged,
  });

  final Household household;

  final ValueChanged<bool> onHasDataChanged;

  @override
  State<HomemadeItemForm> createState() => _HomemadeItemFormState();
}

class _HomemadeItemFormState extends State<HomemadeItemForm> {
  late final AddManuallyController _controller;
  final _nameText = TextEditingController();
  final _nameFocus = FocusNode();
  final _categoryText = TextEditingController();
  final _dateText = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AddManuallyController(
      Dependencies.pantryRepository,
      householdId: widget.household.id,
    )..addListener(_syncTexts);
    _nameFocus.addListener(_onNameFocusChanged);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocusChanged);
    _controller
      ..removeListener(_syncTexts)
      ..dispose();
    _nameText.dispose();
    _nameFocus.dispose();
    _categoryText.dispose();
    _dateText.dispose();
    super.dispose();
  }

  void _onNameFocusChanged() {
    if (!_nameFocus.hasFocus) {
      _controller.lookup();
    }
  }

  void _syncTexts() {
    final categoryName = _controller.category?.name ?? '';
    if (_categoryText.text != categoryName) {
      _categoryText.text = categoryName;
    }
    final date = _controller.expiryDate;
    final dateText = date == null ? '' : _formatDate(date);
    if (_dateText.text != dateText) {
      _dateText.text = dateText;
    }
    widget.onHasDataChanged(_controller.hasData);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.expiryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      _controller.setExpiryDate(picked);
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
      messenger.showSnackBar(const SnackBar(content: Text('Item added to the pantry')));
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
                textInputAction: TextInputAction.done,
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
              DropdownMenu<ProductCategory>(
                controller: _categoryText,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Category'),
                enabled: c.isCategoryEnabled,
                requestFocusOnTap: false,
                menuHeight: 300,
                leadingIcon: c.isCategoryLocked ? const Icon(Icons.lock_outline) : null,
                helperText: c.isCategoryLocked ? 'Taken from an existing product' : null,
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
              const SizedBox(height: 16),
              TextField(
                controller: _dateText,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Expiry date',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Amount:', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: c.count > AddManuallyController.minCount ? c.decrement : null,
                    icon: const Icon(Icons.remove),
                    tooltip: 'Decrease',
                  ),
                  Container(
                    width: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${c.count}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: c.count < AddManuallyController.maxCount ? c.increment : null,
                    icon: const Icon(Icons.add),
                    tooltip: 'Increase',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}
