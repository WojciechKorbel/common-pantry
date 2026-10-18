import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_outlined_button.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinHouseholdSuccessScreen extends StatelessWidget {
  const JoinHouseholdSuccessScreen({
    super.key,
    required this.household,
  });

  final Household household;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Household joined',
        onBack: () => context.go('/households'),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // LOGO
              Image.asset(
                'assets/images/pantry_logo.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              // SUCCESS TEXT
              Text(
                'Success!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // INFO TEXT
              Column(
                children: [
                  Text(
                    'You are now a member of the household',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    household.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const Spacer(),

              // BUTTONS
              AppButton(
                text: 'Go to ${household.name}',
                onPressed: () => context.go('/households'), // TODO: handle it !!!
              ),

              const SizedBox(height: 16),

              // BUTTON
              AppOutlinedButton(
                text: 'Back to households',
                onPressed: () => context.go('/households'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
