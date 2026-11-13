import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/core/widgets/app_text_link.dart';
import 'package:common_pantry/features/auth/presentation/controllers/login_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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

  Widget _buildGoogleButton(bool isGoogleLoading, bool isAnyBusy) {
    return OutlinedButton.icon(
      icon: isGoogleLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata, size: 26),
      label: Text(
        isGoogleLoading ? 'Connecting...' : 'Continue with Google',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isAnyBusy ? null : _loginWithGoogle,
    );
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
                constraints: BoxConstraints(maxWidth: isLandscape ? 820 : 460),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isLandscape ? 12 : 24,
                  ),
                  child: SingleChildScrollView(
                    child: isLandscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/pantry_logo.png',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 12),
                                    const AppPageTitle(
                                      title: 'Sign in',
                                      subtitle: 'Welcome to Pantry!',
                                    ),
                                    const SizedBox(height: 16),
                                    AppInlineLink(
                                      text: "Don't have an account?",
                                      linkText: 'Sign up',
                                      alignment: MainAxisAlignment.center,
                                      onPressed: () => context.push('/sign-up'),
                                    ),
                                    const SizedBox(height: 8),
                                    AppInlineLink(
                                      text: "Didn't verify email?",
                                      linkText: 'Verify account',
                                      alignment: MainAxisAlignment.center,
                                      onPressed: () => context.push('/verify-account'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AppInput(
                                      hintText: 'username',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      controller: _emailController,
                                    ),
                                    const SizedBox(height: 10),
                                    AppInput(
                                      hintText: 'password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      controller: _passwordController,
                                    ),
                                    const SizedBox(height: 4),
                                    AppTextLink(
                                      text: 'Forgot password?',
                                      alignment: Alignment.centerRight,
                                      onPressed: () => context.push('/forgot-password'),
                                    ),
                                    const SizedBox(height: 12),
                                    AppButton(
                                      text: isLoading ? 'Logging in...' : 'Login',
                                      onPressed: isAnyBusy ? null : _login,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildGoogleButton(isGoogleLoading, isAnyBusy),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                'assets/images/pantry_logo.png',
                                width: 96,
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 20),
                              const AppPageTitle(
                                title: 'Sign in',
                                subtitle: 'Welcome to Pantry!',
                              ),
                              const SizedBox(height: 16),
                              AppInput(
                                hintText: 'username',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                              ),
                              const SizedBox(height: 16),
                              AppInput(
                                hintText: 'password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: _passwordController,
                              ),
                              const SizedBox(height: 8),
                              AppTextLink(
                                text: 'Forgot password?',
                                alignment: Alignment.centerRight,
                                onPressed: () {
                                  context.push('/forgot-password');
                                },
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: isLoading ? 'Logging in...' : 'Login',
                                onPressed: isAnyBusy ? null : _login,
                              ),
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 20),
                              _buildGoogleButton(isGoogleLoading, isAnyBusy),
                              const SizedBox(height: 24),
                              AppInlineLink(
                                text: "Don't have an account?",
                                linkText: 'Sign up',
                                alignment: MainAxisAlignment.center,
                                onPressed: () {
                                  context.push('/sign-up');
                                },
                              ),
                              const SizedBox(height: 16),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
