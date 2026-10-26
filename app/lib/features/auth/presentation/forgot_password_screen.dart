import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.controller,
  });

  final ForgotPasswordController controller;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    final success = await widget.controller.requestCode(email: email);

    if (!mounted) return;

    if (!success) {
      _showMessage(
        widget.controller.errorMessage ?? 'Could not send reset code.',
      );
      return;
    }

    await context.push('/verify-reset-code', extra: email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                                    title: 'Forgot password',
                                    subtitle: 'Enter your email address to receive a reset code.',
                                  ),
                                  const SizedBox(height: 24),

                                  // EMAIL INPUT
                                  AppInput(
                                    hintText: 'Email address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    controller: _emailController,
                                  ),
                                  const SizedBox(height: 24),

                                  // SEND BUTTON
                                  AppButton(
                                    text: widget.controller.isLoading
                                        ? 'Sending...'
                                        : 'Send reset code',
                                    onPressed: widget.controller.isLoading ? null : _sendCode,
                                  ),
                                ],
                              ),
                            ),

                            // LOGIN BACK
                            AppInlineLink(
                              text: 'Go back to',
                              linkText: 'Log in',
                              alignment: MainAxisAlignment.center,
                              onPressed: () => context.go('/login'),
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
