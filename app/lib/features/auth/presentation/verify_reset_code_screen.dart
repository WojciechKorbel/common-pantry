import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_inline_link.dart';
import 'package:common_pantry/core/widgets/app_page_title.dart';
import 'package:common_pantry/core/widgets/app_text_link.dart';
import 'package:common_pantry/core/widgets/code_input.dart';
import 'package:common_pantry/features/auth/presentation/controllers/verify_reset_code_controller.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  const VerifyResetCodeScreen({
    super.key,
    required this.email,
    required this.controller,
  });

  final String email;
  final VerifyResetCodeController controller;

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  String _code = '';
  bool _hasCodeError = false;

  Future<void> _verifyCode() async {
    if (_code.length != 6) {
      setState(() => _hasCodeError = true);
      _showMessage('Please enter the complete 6-digit code.');
      return;
    }

    setState(() => _hasCodeError = false);

    final token = await widget.controller.verifyCode(
      email: widget.email,
      code: _code,
    );

    if (!mounted) return;

    if (token == null) {
      setState(() => _hasCodeError = true);

      _showMessage(
        widget.controller.errorMessage ?? 'Could not verify the code.',
      );
      return;
    }

    await context.push('/reset-password', extra: token);
  }

  Future<void> _resendCode() async {
    final success = await widget.controller.resendCode(
      email: widget.email,
    );

    if (!mounted) return;

    final message = success ? widget.controller.infoMessage : widget.controller.errorMessage;

    if (message != null) {
      _showMessage(message);
    }

    if (success) {
      setState(() {
        _code = '';
        _hasCodeError = false;
      });
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
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isVerifying = widget.controller.isVerifying;
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
                                    title: 'Verify reset code',
                                    subtitle:
                                        'We sent a 6-digit reset code '
                                        'to your email address.',
                                  ),
                                  const SizedBox(height: 12),

                                  // EMAIL ADDRESS
                                  Text(
                                    widget.email,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),

                                  // VERIFICATION CODE
                                  CodeInput(
                                    key: const ValueKey(
                                      'password-reset-code',
                                    ),
                                    length: 6,
                                    hasError: _hasCodeError,
                                    onChanged: (value) {
                                      setState(() {
                                        _code = value;
                                        _hasCodeError = false;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // VERIFY BUTTON
                                  AppButton(
                                    text: isVerifying ? 'Verifying...' : 'Verify code',
                                    onPressed: isVerifying || isResending ? null : _verifyCode,
                                  ),
                                  const SizedBox(height: 16),

                                  // RESEND CODE
                                  AppTextLink(
                                    text: isResending ? 'Sending code...' : 'Resend code',
                                    alignment: Alignment.center,
                                    onPressed: isResending || isVerifying ? null : _resendCode,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BACK TO LOGIN
                            AppInlineLink(
                              text: 'Go back to',
                              linkText: 'Log in',
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
