import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/core/widgets/app_text_link.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();

  void _verifyCode() {
    final code = _codeController.text.trim();

    if (code.length != 6 || int.tryParse(code) == null) {
      _showMessage('Please enter a valid 6-digit code.');
      return;
    }

    // TODO: API
    if (!mounted) return;

    context.go('/verify-email-success');
  }

  void _resendCode() {
    // TODO: API
    _showMessage('TODO: Resend verification code.');
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
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                title: 'Verify your email',
                                subtitle:
                                    'We sent a 6-digit verification code '
                                    'to your email address.',
                              ),
                              const SizedBox(height: 24),

                              // VERIFICATION CODE
                              AppInput(
                                hintText: '6-digit code',
                                icon: Icons.mark_email_read_outlined,
                                keyboardType: TextInputType.number,
                                controller: _codeController,
                              ),
                              const SizedBox(height: 24),

                              // VERIFY BUTTON
                              AppButton(
                                text: 'Verify email',
                                onPressed: _verifyCode,
                              ),
                              const SizedBox(height: 16),

                              // RESEND CODE
                              AppTextLink(
                                text: 'Resend code',
                                alignment: Alignment.center,
                                onPressed: _resendCode,
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
  }
}
