import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/purchased_item_form.dart';
import 'package:flutter/material.dart';

enum ItemSource { homemade, purchased }

Future<void> showAddManuallyDialog(
  BuildContext context,
  Household household, {
  ItemSource? initialSource,
  Product? initialProduct,
  String? initialBarcode,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierDismissible: false,
    builder: (_) => AddManuallyDialog(
      household: household,
      initialSource: initialSource,
      initialProduct: initialProduct,
      initialBarcode: initialBarcode,
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
  });

  final Household household;
  final ItemSource? initialSource;
  final Product? initialProduct;
  final String? initialBarcode;

  @override
  State<AddManuallyDialog> createState() => _AddManuallyDialogState();
}

class _AddManuallyDialogState extends State<AddManuallyDialog> {
  late ItemSource? _source;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    if (widget.initialProduct != null || widget.initialBarcode != null) {
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
            title: Text(
              widget.initialProduct != null || widget.initialBarcode != null
                  ? 'Add scanned item'
                  : 'Add manually',
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: DropdownMenu<ItemSource>(
                    initialSelection: _source,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Source'),
                    requestFocusOnTap: false,
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
                const SizedBox(height: 24),
                Expanded(
                  child: switch (_source) {
                    ItemSource.homemade => HomemadeItemForm(
                      key: const ValueKey(ItemSource.homemade),
                      household: widget.household,
                      onHasDataChanged: (value) => _hasData = value,
                    ),
                    ItemSource.purchased => PurchasedItemForm(
                      key: const ValueKey(ItemSource.purchased),
                      household: widget.household,
                      initialProduct: widget.initialProduct,
                      initialBarcode: widget.initialBarcode,
                      onHasDataChanged: (value) => _hasData = value,
                    ),
                    null => const SizedBox.shrink(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
