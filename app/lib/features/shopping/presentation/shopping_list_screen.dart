import 'package:common_pantry/core/widgets/placeholder_screen.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';

// TODO: ONLY PLACEHOLDER
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  Widget build(BuildContext context) {
    return HouseholdPlaceholderScreen(
      household: household,
      title: 'Shopping list',
      icon: Icons.shopping_cart_outlined,
    );
  }
}
