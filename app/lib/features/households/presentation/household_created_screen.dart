import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_outlined_button.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/widgets/invite_code_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class HouseholdCreatedScreen extends StatelessWidget {
  const HouseholdCreatedScreen({
    super.key,
    required this.household,
  });

  final Household household;

  Future<void> _copyInviteCode(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: household.inviteCode ?? ''),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Invite code copied!'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = Responsive.isLandscape(context);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Household created',
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

                          // SUCCESS BOLD TEXT
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

                          // INFO TEXTS
                          Text(
                            'Your household has been successfully created! Here’s your invitation code to share with your household members so they can join.',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isLandscape ? 16 : 36),

                          Text(
                            'HOUSEHOLD INVITE CODE',
                            style: theme.textTheme.labelLarge,
                          ),

                          const SizedBox(height: 12),

                          // CODE COPY CARD
                          InviteCodeCard(
                            inviteCode: household.inviteCode ?? '',
                            onCopy: () => _copyInviteCode(context),
                          ),

                          const SizedBox(height: 16),

                          // INFO TEXTS
                          const Text(
                            'This code will also be available in your household settings, so there’s no need to save it anywhere.',
                            textAlign: TextAlign.center,
                          ),

                          if (!isLandscape) const Spacer(),
                          SizedBox(height: isLandscape ? 20 : 0),

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
