import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/core/widgets/app_text_link.dart';
import 'package:common_pantry/core/widgets/code_input.dart';
import 'package:common_pantry/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.controller,
  });

  final String email;
  final VerifyEmailController controller;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _code = '';
  bool _hasCodeError = false;

  Future<void> _verifyCode() async {
    if (_code.length != 6) {
      setState(() => _hasCodeError = true);
      _showMessage('Please enter the complete 6-digit code.');
      return;
    }

    setState(() => _hasCodeError = false);

    final success = await widget.controller.verifyCode(
      email: widget.email,
      code: _code,
    );

    if (!mounted) return;

    if (success) {
      context.go('/verify-email-success');
      return;
    }

    setState(() => _hasCodeError = true);

    final message = widget.controller.errorMessage;
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _resendCode() async {
    final success = await widget.controller.resendCode(
      email: widget.email,
    );

    if (!mounted) return;

    final message = success ? widget.controller.successMessage : widget.controller.errorMessage;

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
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isLoading = widget.controller.isLoading;
        final isResending = widget.controller.isResending;

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
                                        title: 'Verify your email',
                                        subtitle:
                                            'We sent a 6-digit verification code '
                                            'to your email address.',
                                      ),
                                      SizedBox(height: isLandscape ? 16 : 24),

                                      // VERIFICATION CODE
                                      CodeInput(
                                        key: const ValueKey('verification-code'),
                                        length: 6,
                                        hasError: _hasCodeError,
                                        onChanged: (value) {
                                          setState(() {
                                            _code = value;
                                            _hasCodeError = false;
                                          });
                                        },
                                      ),
                                      SizedBox(height: isLandscape ? 16 : 24),

                                      // VERIFY BUTTON
                                      AppButton(
                                        text: isLoading ? 'Verifying...' : 'Verify email',
                                        onPressed: isLoading ? null : _verifyCode,
                                      ),
                                      SizedBox(height: isLandscape ? 10 : 16),

                                      // RESEND CODE
                                      AppTextLink(
                                        text: isResending ? 'Sending code...' : 'Resend code',
                                        alignment: Alignment.center,
                                        onPressed: isResending || isLoading ? null : _resendCode,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isLandscape ? 12 : 24),

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
            ),
          ),
        );
      },
    );
  }
}
