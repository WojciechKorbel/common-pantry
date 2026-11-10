import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/utils/responsive.dart';
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
    final isLandscape = Responsive.isLandscape(context);

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isLandscape ? 16 : 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (isLandscape ? 32 : 48),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          if (!isLandscape) const Spacer(),

                          // LOGO
                          Image.asset(
                            'assets/images/pantry_logo.png',
                            width: isLandscape ? 60 : 96,
                            height: isLandscape ? 60 : 96,
                            fit: BoxFit.contain,
                          ),

                          SizedBox(height: isLandscape ? 12 : 24),

                          // SUCCESS TEXT
                          Text(
                            'Success!',
                            style:
                                (isLandscape
                                        ? theme.textTheme.headlineSmall
                                        : theme.textTheme.headlineMedium)
                                    ?.copyWith(
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

                          if (!isLandscape) const Spacer(),
                          SizedBox(height: isLandscape ? 24 : 0),

                          // BUTTONS
                          AppButton(
                            text: 'Go to ${household.name}',
                            onPressed: () {
                              Dependencies.householdController.select(household);

                              context.go(
                                '/pantry-items',
                                extra: household,
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          AppOutlinedButton(
                            text: 'Back to households',
                            onPressed: () => context.go('/households'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
