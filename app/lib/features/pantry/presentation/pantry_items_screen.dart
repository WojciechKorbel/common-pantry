import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PantryItemsScreen extends StatelessWidget {
  const PantryItemsScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ID = ${household.id}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                Text(
                  'NAME = ${household.name}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),

                Text(
                  'Pantry items - coming soon',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
