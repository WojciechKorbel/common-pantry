import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailSuccessScreen extends StatelessWidget {
  const VerifyEmailSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Email verified',
        onBack: () => context.go('/login'),
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
              Text(
                'Your email address has been successfully verified.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'You can now sign in to your Pantry account.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // GO TO LOGIN
              AppButton(
                text: 'Go to login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
