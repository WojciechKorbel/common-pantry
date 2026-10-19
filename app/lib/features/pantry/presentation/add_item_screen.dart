import 'package:common_pantry/core/widgets/placeholder_screen.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';

// TODO: ONLY PLACEHOLDER
class AddItemScreen extends StatelessWidget {
  const AddItemScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  Widget build(BuildContext context) {
    return HouseholdPlaceholderScreen(
      household: household,
      title: 'Add item',
      icon: Icons.add_box_outlined,
    );
  }
}
