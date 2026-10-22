import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/features/auth/presentation/controllers/sign_up_controller.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.controller,
  });

  final SignUpController controller;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _signUp() async {
    final success = await widget.controller.signUp(
      email: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      await context.push(
        '/verify-email',
        extra: _emailController.text.trim().toLowerCase(),
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
    _usernameController.dispose();
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
                                    title: 'Create account',
                                    subtitle: 'Join Pantry!',
                                  ),
                                  const SizedBox(height: 8),

                                  // EMAIL
                                  AppInput(
                                    hintText: 'email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    controller: _emailController,
                                  ),
                                  const SizedBox(height: 16),

                                  // USERNAME
                                  AppInput(
                                    hintText: 'username',
                                    icon: Icons.person_outline,
                                    controller: _usernameController,
                                  ),
                                  const SizedBox(height: 16),

                                  // PASSWORD
                                  AppInput(
                                    hintText: 'password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    controller: _passwordController,
                                  ),
                                  const SizedBox(height: 16),

                                  // CONFIRM PASSWORD
                                  AppInput(
                                    hintText: 'confirm password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    controller: _confirmPasswordController,
                                  ),
                                  const SizedBox(height: 32),

                                  // CREATE ACCOUNT BUTTON
                                  AppButton(
                                    text: isLoading ? 'Creating account...' : 'Create account',
                                    onPressed: isLoading ? null : _signUp,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BACK TO LOGIN
                            AppInlineLink(
                              text: 'Already have an account?',
                              linkText: 'Sign in',
                              alignment: MainAxisAlignment.center,
                              onPressed: () {
                                context.push('/login');
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
