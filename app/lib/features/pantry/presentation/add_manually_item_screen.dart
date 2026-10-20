import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ItemSource { homemade, purchased }

class AddManuallyItemScreen extends StatefulWidget {
  const AddManuallyItemScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  State<AddManuallyItemScreen> createState() => _AddManuallyItemScreenState();
}

class _AddManuallyItemScreenState extends State<AddManuallyItemScreen> {
  ItemSource? _source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Add manually',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownMenu<ItemSource>(
                expandedInsets: EdgeInsets.zero,
                label: const Text('Source'),
                requestFocusOnTap: false,
                inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                menuStyle: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.surface),
                  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
                ),
                onSelected: (value) => setState(() => _source = value),
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
              const SizedBox(height: 24),
              switch (_source) {
                ItemSource.homemade => const _HomemadeForm(),
                ItemSource.purchased => const _PurchasedForm(),
                null => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _HomemadeForm extends StatelessWidget {
  const _HomemadeForm();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _PurchasedForm extends StatelessWidget {
  const _PurchasedForm();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
