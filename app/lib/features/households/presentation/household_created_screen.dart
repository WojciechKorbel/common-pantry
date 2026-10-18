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

    // SNACKBAR - COPY INFO
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

              // SUCCESS BOLD TEXT
              Text(
                'Success!',
                style: theme.textTheme.headlineMedium?.copyWith(
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

              const SizedBox(height: 36),

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

              const Spacer(),

              // BUTTONS
              AppButton(
                text: 'Go to ${household.name}',
                onPressed: () => context.go('/fridge-items'),
              ),

              const SizedBox(height: 16),

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
