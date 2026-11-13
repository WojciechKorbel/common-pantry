import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/purchased_item_form.dart';
import 'package:material_ui/material_ui.dart';

enum ItemSource { homemade, purchased }

Future<void> showAddManuallyDialog(
  BuildContext context,
  Household household, {
  ItemSource? initialSource,
  Product? initialProduct,
  String? initialBarcode,
  PantryRepository? repository,
  PantryController? pantryController,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    barrierDismissible: false,
    builder: (_) => AddManuallyDialog(
      household: household,
      initialSource: initialSource,
      initialProduct: initialProduct,
      initialBarcode: initialBarcode,
      repository: repository,
      pantryController: pantryController,
    ),
  );
}

class AddManuallyDialog extends StatefulWidget {
  const AddManuallyDialog({
    super.key,
    required this.household,
    this.initialSource,
    this.initialProduct,
    this.initialBarcode,
    this.repository,
    this.pantryController,
  });

  final Household household;
  final ItemSource? initialSource;
  final Product? initialProduct;
  final String? initialBarcode;
  final PantryRepository? repository;
  final PantryController? pantryController;

  @override
  State<AddManuallyDialog> createState() => _AddManuallyDialogState();
}

class _AddManuallyDialogState extends State<AddManuallyDialog> {
  late ItemSource? _source;
  bool _hasData = false;

  bool get _isScanned => widget.initialProduct != null || widget.initialBarcode != null;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    if (_isScanned) {
      _source = ItemSource.purchased;
      _hasData = true;
    }
  }

  Future<void> _attemptClose() async {
    if (!_hasData) {
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

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: DropdownMenu<ItemSource>(
            enabled: !_isScanned,
            initialSelection: _source,
            expandedInsets: EdgeInsets.zero,
            label: const Text('Source'),
            requestFocusOnTap: false,
            leadingIcon: _isScanned ? const Icon(Icons.lock_outline) : null,
            helperText: _isScanned ? 'Fixed to purchased for scanned items' : null,
            inputDecorationTheme: theme.inputDecorationTheme,
            menuStyle: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
            onSelected: (value) => setState(() {
              _source = value;
              _hasData = false;
            }),
            dropdownMenuEntries: const [
              DropdownMenuEntry(
                value: ItemSource.homemade,
                label: 'Homemade',
                leadingIcon: Icon(Icons.home_outlined),
              ),
              DropdownMenuEntry(
                value: ItemSource.purchased,
                label: 'Purchased',
                leadingIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: switch (_source) {
            ItemSource.homemade => HomemadeItemForm(
              key: const ValueKey(ItemSource.homemade),
              household: widget.household,
              onHasDataChanged: (value) => _hasData = value,
              repository: widget.repository,
              pantryController: widget.pantryController,
            ),
            ItemSource.purchased => PurchasedItemForm(
              key: const ValueKey(ItemSource.purchased),
              household: widget.household,
              initialProduct: widget.initialProduct,
              initialBarcode: widget.initialBarcode,
              onHasDataChanged: (value) => _hasData = value,
              repository: widget.repository,
              pantryController: widget.pantryController,
            ),
            null => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final title = _isScanned ? 'Add scanned item' : 'Add manually';

    final isCardDialog = size.width >= 550;

    final scaffold = Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: _attemptClose,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _buildContent(theme),
      ),
    );

    final contentWithScope = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _attemptClose();
        }
      },
      child: scaffold,
    );

    if (isCardDialog) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: theme.colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
            maxHeight: 540,
          ),
          child: contentWithScope,
        ),
      );
    }

    return Dialog.fullscreen(
      child: contentWithScope,
    );
  }
}
