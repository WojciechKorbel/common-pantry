import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_manually_dialog.dart';
import 'package:flutter/material.dart';

enum AddItemChoice { manually }

/// Opens the "Scan barcode / Add manually" dialog on top of the current screen.
/// "Add manually" continues in a full-screen dialog.
Future<void> showAddItemDialog(BuildContext context, Household household) async {
  final choice = await showDialog<AddItemChoice>(
    context: context,
    builder: (_) => const _AddItemChoiceDialog(),
  );
  if (choice == AddItemChoice.manually && context.mounted) {
    await showAddManuallyDialog(context, household);
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
              onTap: () {
                // TODO: barcode scanning
              },
            ),
            const Divider(),
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
