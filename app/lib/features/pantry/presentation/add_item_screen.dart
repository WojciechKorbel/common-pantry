import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_bottom_navigation_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({
    super.key,
    required this.household,
  });

  final Household household;

  void _onScanBarcode() {
    // TODO: barcode scanning
  }

  void _onAddManually(BuildContext context) {
    context.push('/add-item/manual', extra: household);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: household.name,
        onBack: () => context.go('/households'),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AddOption(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan barcode',
                      onTap: _onScanBarcode,
                    ),
                    const Divider(),
                    _AddOption(
                      icon: Icons.edit_outlined,
                      label: 'Add manually',
                      onTap: () => _onAddManually(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(household: household),
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
        height: 160,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
