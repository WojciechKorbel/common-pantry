import 'dart:async';

import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/presentation/barcode_scanner_screen.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_manually_dialog.dart';
import 'package:flutter/material.dart';

enum AddItemChoice { scanBarcode, manually }

Future<void> showAddItemDialog(BuildContext context, Household household) async {
  final choice = await showDialog<AddItemChoice>(
    context: context,
    builder: (_) => const _AddItemChoiceDialog(),
  );

  if (choice == null || !context.mounted) return;

  if (choice == AddItemChoice.manually) {
    await showAddManuallyDialog(context, household);
    return;
  }

  if (choice == AddItemChoice.scanBarcode) {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.trim().isEmpty || !context.mounted) return;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    Product? product;
    try {
      product = await Dependencies.pantryRepository.getProductByBarcode(
        household.id,
        barcode.trim(),
      );
    } catch (_) {
      // Ignore
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (product != null) {
      await showAddManuallyDialog(
        context,
        household,
        initialProduct: product,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product $barcode not found. Enter details manually.'),
        ),
      );
      await showAddManuallyDialog(
        context,
        household,
        initialBarcode: barcode.trim(),
      );
    }
  }
}

class _AddItemChoiceDialog extends StatelessWidget {
  const _AddItemChoiceDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AddOption(
              icon: Icons.qr_code_scanner,
              label: 'Scan barcode',
              onTap: () => Navigator.of(context).pop(AddItemChoice.scanBarcode),
            ),
            const Divider(height: 1),
            _AddOption(
              icon: Icons.edit_outlined,
              label: 'Add manually',
              onTap: () => Navigator.of(context).pop(AddItemChoice.manually),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
