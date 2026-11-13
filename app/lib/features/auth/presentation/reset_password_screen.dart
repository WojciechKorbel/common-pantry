import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
    final isLandscape = Responsive.isLandscape(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isLoading = widget.controller.isLoading;

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
                                      // LOGO
                                      Image.asset(
                                        'assets/images/pantry_logo.png',
                                        width: isLandscape ? 56 : 96,
                                        height: isLandscape ? 56 : 96,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(height: isLandscape ? 10 : 20),

                                      // TITLE
                                      const AppPageTitle(
                                        title: 'Create new password',
                                        subtitle: 'Enter your new password and confirm it below.',
                                      ),
                                      SizedBox(height: isLandscape ? 16 : 24),

                                      // PASSWORD INPUT
                                      AppInput(
                                        hintText: 'New password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        controller: _passwordController,
                                      ),
                                      SizedBox(height: isLandscape ? 10 : 16),

                                      // CONFIRM PASSWORD INPUT
                                      AppInput(
                                        hintText: 'Confirm new password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        controller: _confirmPasswordController,
                                      ),
                                      SizedBox(height: isLandscape ? 16 : 24),

                                      // RESET BUTTON
                                      AppButton(
                                        text: isLoading
                                            ? 'Resetting password...'
                                            : 'Reset password',
                                        onPressed: isLoading ? null : _resetPassword,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isLandscape ? 12 : 24),

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
            ),
          ),
        );
      },
    );
  }
}
