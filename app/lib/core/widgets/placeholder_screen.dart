import 'package:common_pantry/core/widgets/app_bottom_navigation_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';

// TODO: REMOVE LATER
class HouseholdPlaceholderScreen extends StatelessWidget {
  const HouseholdPlaceholderScreen({
    super.key,
    required this.household,
    required this.title,
    required this.icon,
  });

  final Household household;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                household.name,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Household ID: ${household.id}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                '$title coming soon',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(household: household),
    );
  }
}
