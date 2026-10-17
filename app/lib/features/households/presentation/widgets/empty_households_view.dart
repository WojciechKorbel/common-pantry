import 'package:flutter/material.dart';

class EmptyHouseholdsView extends StatelessWidget {
  const EmptyHouseholdsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.holiday_village_outlined,
            size: 96,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No households yet',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Join a household or create a new one.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}