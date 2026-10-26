import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pinned_action_layout.dart';
import 'package:flutter/material.dart';

Future<void> showEditProductDialog(
  BuildContext context, {
  required PantryGroup product,
  required PantryController controller,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierDismissible: false,
    builder: (_) => EditProductDialog(
      product: product,
      controller: controller,
    ),
  );
}

class EditProductDialog extends StatefulWidget {
  const EditProductDialog({
    super.key,
    required this.product,
    required this.controller,
  });

  final PantryGroup product;
  final PantryController controller;

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late final TextEditingController _nameText;
  late final TextEditingController _brandText;
  late final TextEditingController _categoryController;
  final FocusNode _nameFocus = FocusNode();

  ProductCategory? _selectedCategory;
  List<ProductCategory> _categories = [];
  bool _isLoadingCategories = true;
  bool _isLookingUp = false;
  bool _isSubmitting = false;

  bool get _isPurchased => widget.product.brand != null && widget.product.brand!.trim().isNotEmpty;

  bool get _hasChanges {
    final nameChanged = _nameText.text.trim() != widget.product.name.trim();
    final brandChanged =
        _isPurchased && (_brandText.text.trim() != (widget.product.brand?.trim() ?? ''));
    final categoryChanged = _selectedCategory?.id != widget.product.category?.id;
    return nameChanged || brandChanged || categoryChanged;
  }

  bool get _canSubmit => _hasChanges && !_isSubmitting && _nameText.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameText = TextEditingController(text: widget.product.name);
    _brandText = TextEditingController(text: widget.product.brand ?? '');

    _selectedCategory = widget.product.category;
    _categoryController = TextEditingController(
      text: widget.product.category?.name ?? '',
    );

    _nameText.addListener(_onFieldChanged);
    _brandText.addListener(_onFieldChanged);
    _nameFocus.addListener(_onNameFocusChanged);

    _loadCategories();
  }

  void _onFieldChanged() => setState(() {});

  void _onNameFocusChanged() {
    if (!_nameFocus.hasFocus) {
      _lookupProduct();
    }
  }

  Future<void> _lookupProduct() async {
    final query = _nameText.text.trim();
    if (query.isEmpty || query.toLowerCase() == widget.product.name.trim().toLowerCase()) {
      return;
    }

    setState(() => _isLookingUp = true);

    try {
      final householdId = Dependencies.householdController.current.id;
      final results = await Dependencies.pantryRepository.searchProducts(
        householdId,
        query,
      );

      if (results.isNotEmpty && mounted) {
        final match = results.firstWhere(
          (p) => p.name.trim().toLowerCase() == query.toLowerCase(),
          orElse: () => results.first,
        );

        if (match.category != null) {
          final matchedCategory = _categories.where((c) => c.id == match.category!.id);
          if (matchedCategory.isNotEmpty) {
            setState(() {
              _selectedCategory = matchedCategory.first;
              _categoryController.text = _selectedCategory!.name;
            });
          }
        }

        if (_isPurchased && _brandText.text.trim().isEmpty && match.brand != null) {
          setState(() {
            _brandText.text = match.brand!;
          });
        }
      }
    } catch (_) {
      // Ignorujemy błędy cichego lookupu
    } finally {
      if (mounted) {
        setState(() => _isLookingUp = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await Dependencies.pantryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (_selectedCategory != null) {
          final matched = categories.where((c) => c.id == _selectedCategory!.id);
          if (matched.isNotEmpty) {
            _selectedCategory = matched.first;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocusChanged);
    _nameFocus.dispose();
    _nameText.dispose();
    _brandText.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _attemptClose() async {
    if (!_hasChanges || _isSubmitting) {
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

    final success = await widget.controller.updateProduct(
      productId: widget.product.id,
      name: _nameText.text.trim(),
      brand: _isPurchased ? _brandText.text.trim() : null,
      categoryId: _selectedCategory?.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Product updated')));
    } else if (widget.controller.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage!)),
      );
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
              'Edit product',
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
                    : const Text('Save changes'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameText,
                    focusNode: _nameFocus,
                    onTapOutside: (_) => _nameFocus.unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      suffixIcon: _isLookingUp
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
                  if (_isPurchased) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _brandText,
                      decoration: const InputDecoration(labelText: 'Brand'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownMenu<ProductCategory>(
                    controller: _categoryController,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Category'),
                    enabled: !_isLoadingCategories && !_isSubmitting,
                    requestFocusOnTap: false,
                    menuHeight: 300,
                    inputDecorationTheme: theme.inputDecorationTheme,
                    menuStyle: const MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(AppColors.surface),
                      surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
                    ),
                    initialSelection: _selectedCategory,
                    onSelected: (value) => setState(() {
                      _selectedCategory = value;
                    }),
                    dropdownMenuEntries: [
                      for (final category in _categories)
                        DropdownMenuEntry(
                          value: category,
                          label: category.name,
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
