import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/features/auth/presentation/controllers/sign_up_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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

  Future<void> _signUp() async {
    final success = await widget.controller.signUp(
      email: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await context.push('/verify-account', extra: _emailController.text.trim());
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isLoading = widget.controller.isLoading;

        final fields = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInput(
              hintText: 'email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            SizedBox(height: isLandscape ? 8 : 16),
            AppInput(
              hintText: 'username',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              controller: _usernameController,
            ),
            SizedBox(height: isLandscape ? 8 : 16),
            AppInput(
              hintText: 'password',
              icon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
            ),
            SizedBox(height: isLandscape ? 12 : 24),
            AppButton(
              text: isLoading ? 'Creating account...' : 'Create account',
              onPressed: isLoading ? null : _signUp,
            ),
          ],
        );

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
                                      title: 'Create account',
                                      subtitle: 'Join Pantry!',
                                    ),
                                    const SizedBox(height: 16),
                                    AppInlineLink(
                                      text: 'Already have an account?',
                                      linkText: 'Sign in',
                                      alignment: MainAxisAlignment.center,
                                      onPressed: () => context.go('/login'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 5,
                                child: fields,
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
                                title: 'Create account',
                                subtitle: 'Join Pantry!',
                              ),
                              const SizedBox(height: 24),
                              fields,
                              const SizedBox(height: 24),
                              AppInlineLink(
                                text: 'Already have an account?',
                                linkText: 'Sign in',
                                alignment: MainAxisAlignment.center,
                                onPressed: () => context.go('/login'),
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
