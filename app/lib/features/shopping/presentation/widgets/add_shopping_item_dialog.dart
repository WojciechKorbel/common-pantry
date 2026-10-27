import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pinned_action_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showAddShoppingItemDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierDismissible: false,
    builder: (_) => const AddShoppingItemDialog(),
  );
}

class AddShoppingItemDialog extends StatefulWidget {
  const AddShoppingItemDialog({super.key});

  @override
  State<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<AddShoppingItemDialog> {
  static const _minCount = 1;
  static const _maxCount = 20;

  final _nameText = TextEditingController();
  final _categoryText = TextEditingController();

  ProductCategory? _category;
  List<ProductCategory> _categories = const [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  int _count = 1;

  bool get _hasData => _nameText.text.trim().isNotEmpty;

  bool get _canSubmit => _hasData && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _nameText.addListener(_onNameChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _nameText.dispose();
    _categoryText.dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  Future<void> _loadCategories() async {
    try {
      final categories = await Dependencies.pantryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
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
        content: const Text('The data you entered will be lost.'),
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final controller = Dependencies.shoppingController;
    final success = await controller.addItem(
      name: _nameText.text.trim(),
      quantity: _count,
      categoryId: _category?.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Item added to the shopping list')),
      );
    } else if (controller.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            title: const Text(
              'Add to shopping list',
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: PinnedActionLayout(
              action: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameText,
                    autofocus: true,
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(255)],
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<ProductCategory>(
                    controller: _categoryText,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Category (optional)'),
                    enabled: !_isLoadingCategories && !_isSubmitting,
                    requestFocusOnTap: false,
                    menuHeight: 300,
                    inputDecorationTheme: theme.inputDecorationTheme,
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
                      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                    ),
                    onSelected: (value) => setState(() => _category = value),
                    dropdownMenuEntries: [
                      for (final category in _categories)
                        DropdownMenuEntry(value: category, label: category.name),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Amount:', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: _count > _minCount && !_isSubmitting
                            ? () => setState(() => _count--)
                            : null,
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
                          '$_count',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _count < _maxCount && !_isSubmitting
                            ? () => setState(() => _count++)
                            : null,
                        icon: const Icon(Icons.add),
                        tooltip: 'Increase',
                      ),
                    ],
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
