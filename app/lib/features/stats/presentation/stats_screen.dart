import 'package:common_pantry/core/widgets/placeholder_screen.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';

// TODO: ONLY PLACEHOLDER
class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  Widget build(BuildContext context) {
    return HouseholdPlaceholderScreen(
      household: household,
      title: 'Statistics',
      icon: Icons.bar_chart_outlined,
    );
  }
}
