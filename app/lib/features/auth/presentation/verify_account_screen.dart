import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/features/auth/presentation/controllers/verify_email_controller.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({
    super.key,
    required this.controller,
  });

  final VerifyEmailController controller;

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _emailController = TextEditingController();

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@'
      r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );

    return emailRegex.hasMatch(email);
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    final success = await widget.controller.resendCode(
      email: email,
    );

    if (!mounted) return;

    if (success) {
      await context.push(
        '/verify-email',
        extra: email,
      );
      return;
    }

    final message = widget.controller.errorMessage;
    if (message != null) {
      _showMessage(message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isResending = widget.controller.isResending;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // LOGO
                                  Image.asset(
                                    'assets/images/pantry_logo.png',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 20),

                                  // TITLE
                                  const AppPageTitle(
                                    title: 'Verify your account',
                                    subtitle:
                                        'Enter the email address you used '
                                        'to create your Pantry account. '
                                        'We will send you a verification code.',
                                  ),
                                  const SizedBox(height: 24),

                                  // EMAIL
                                  AppInput(
                                    hintText: 'email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    controller: _emailController,
                                  ),
                                  const SizedBox(height: 32),

                                  // SEND CODE
                                  AppButton(
                                    text: isResending
                                        ? 'Sending code...'
                                        : 'Send verification code',
                                    onPressed: isResending ? null : _sendCode,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BACK TO LOGIN
                            AppInlineLink(
                              text: 'Already verified?',
                              linkText: 'Sign in',
                              alignment: MainAxisAlignment.center,
                              onPressed: () {
                                context.go('/login');
                              },
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
        );
      },
    );
  }
}
