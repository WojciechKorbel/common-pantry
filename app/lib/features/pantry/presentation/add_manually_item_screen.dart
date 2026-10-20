import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/purchased_item_form.dart';
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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: DropdownMenu<ItemSource>(
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
            ),
            const SizedBox(height: 24),
            Expanded(
              child: switch (_source) {
                ItemSource.homemade => HomemadeItemForm(household: widget.household),
                ItemSource.purchased => PurchasedItemForm(household: widget.household),
                null => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
