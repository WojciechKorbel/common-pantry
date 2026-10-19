import 'package:common_pantry/core/widgets/placeholder_screen.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';

// TODO: ONLY PLACEHOLDER
class HouseholdSettingsScreen extends StatelessWidget {
  const HouseholdSettingsScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  Widget build(BuildContext context) {
    return HouseholdPlaceholderScreen(
      household: household,
      title: 'Household Settings',
      icon: Icons.settings_outlined,
    );
  }
}
