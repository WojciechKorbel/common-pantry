import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class VerifyEmailSuccessScreen extends StatelessWidget {
  const VerifyEmailSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = Responsive.isLandscape(context);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Email verified',
        onBack: () => context.go('/login'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isLandscape ? 16 : 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (isLandscape ? 32 : 48),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isLandscape) const Spacer(),

                          // LOGO
                          Image.asset(
                            'assets/images/pantry_logo.png',
                            width: isLandscape ? 64 : 96,
                            height: isLandscape ? 64 : 96,
                            fit: BoxFit.contain,
                          ),

                          SizedBox(height: isLandscape ? 16 : 24),

                          // SUCCESS TEXT
                          Text(
                            'Success!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          // INFO TEXT
                          Text(
                            'Your email address has been successfully verified.',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'You can now sign in to your Pantry account.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),

                          if (!isLandscape) const Spacer(),
                          SizedBox(height: isLandscape ? 24 : 0),

                          // GO TO LOGIN
                          AppButton(
                            text: 'Go to login',
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
    );
  }
}
