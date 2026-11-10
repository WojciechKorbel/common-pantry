import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/core/widgets/app_text_link.dart';
import 'package:common_pantry/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
  });

  final LoginController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final success = await widget.controller.login(
      username: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/households');
      return;
    }

    final message = widget.controller.errorMessage;
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _loginWithGoogle() async {
    final success = await widget.controller.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      context.go('/households');
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isLoading = widget.controller.isLoading;
        final isGoogleLoading = widget.controller.isGoogleLoading;
        final isAnyBusy = isLoading || isGoogleLoading;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isLandscape ? 12 : 24,
                  ),
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
                                      // ICON
                                      Image.asset(
                                        'assets/images/pantry_logo.png',
                                        width: isLandscape ? 56 : 96,
                                        height: isLandscape ? 56 : 96,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(height: isLandscape ? 12 : 20),

                                      // TITLE
                                      const AppPageTitle(
                                        title: 'Sign in',
                                        subtitle: 'Welcome to Pantry!',
                                      ),

                                      // EMAIL FIELD
                                      AppInput(
                                        hintText: 'username',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        controller: _emailController,
                                      ),
                                      const SizedBox(height: 16),

                                      // PASSWORD FIELD
                                      AppInput(
                                        hintText: 'password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        controller: _passwordController,
                                      ),
                                      const SizedBox(height: 8),

                                      // FORGOT PASSWORD LINK
                                      AppTextLink(
                                        text: 'Forgot password?',
                                        alignment: Alignment.centerRight,
                                        onPressed: () {
                                          context.push('/forgot-password');
                                        },
                                      ),
                                      SizedBox(height: isLandscape ? 16 : 24),

                                      // LOGIN BUTTON
                                      AppButton(
                                        text: isLoading ? 'Logging in...' : 'Login',
                                        onPressed: isAnyBusy ? null : _login,
                                      ),
                                      SizedBox(height: isLandscape ? 12 : 20),

                                      // DIVIDER WITH TEXT
                                      Row(
                                        children: [
                                          Expanded(child: Divider(color: Colors.grey.shade400)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              'or',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(child: Divider(color: Colors.grey.shade400)),
                                        ],
                                      ),
                                      SizedBox(height: isLandscape ? 12 : 20),

                                      // GOOGLE SIGN IN BUTTON
                                      OutlinedButton.icon(
                                        icon: isGoogleLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.g_mobiledata, size: 28),
                                        label: Text(
                                          isGoogleLoading
                                              ? 'Connecting to Google...'
                                              : 'Continue with Google',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          side: BorderSide(color: Colors.grey.shade400),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: isAnyBusy ? null : _loginWithGoogle,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isLandscape ? 12 : 16),

                                // SIGN UP LINK
                                AppInlineLink(
                                  text: "Don't have an account?",
                                  linkText: 'Sign up',
                                  alignment: MainAxisAlignment.center,
                                  onPressed: () {
                                    context.push('/sign-up');
                                  },
                                ),

                                SizedBox(height: isLandscape ? 8 : 16),

                                // VERIFY ACCOUNT LINK
                                AppInlineLink(
                                  text: "Didn't verify your email?",
                                  linkText: 'Verify account',
                                  alignment: MainAxisAlignment.center,
                                  onPressed: () {
                                    context.push('/verify-account');
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
            ),
          ),
        );
      },
    );
  }
}
