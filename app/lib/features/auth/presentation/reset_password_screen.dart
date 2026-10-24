import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
    required this.controller,
  });

  final String resetToken;
  final ResetPasswordController controller;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _resetPassword() async {
    final success = await widget.controller.resetPassword(
      resetToken: widget.resetToken,
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (!success) {
      _showMessage(
        widget.controller.errorMessage ?? 'Could not reset the password.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password has been reset successfully.'),
      ),
    );

    context.go('/login');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isLoading = widget.controller.isLoading;

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
                                    title: 'Create new password',
                                    subtitle: 'Enter your new password and confirm it below.',
                                  ),
                                  const SizedBox(height: 24),

                                  // PASSWORD INPUT
                                  AppInput(
                                    hintText: 'New password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    controller: _passwordController,
                                  ),
                                  const SizedBox(height: 16),

                                  // CONFIRM PASSWORD INPUT
                                  AppInput(
                                    hintText: 'Confirm new password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    controller: _confirmPasswordController,
                                  ),
                                  const SizedBox(height: 24),

                                  // RESET BUTTON
                                  AppButton(
                                    text: isLoading ? 'Resetting password...' : 'Reset password',
                                    onPressed: isLoading ? null : _resetPassword,
                                  ),
                                ],
                              ),
                            ),

                            // BACK TO LOGIN
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
