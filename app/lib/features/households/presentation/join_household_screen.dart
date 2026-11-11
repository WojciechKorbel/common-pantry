import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/controllers/join_household_controller.dart';
import 'package:common_pantry/features/households/presentation/widgets/invite_code_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinHouseholdScreen extends StatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  State<JoinHouseholdScreen> createState() => _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends State<JoinHouseholdScreen> {
  late final JoinHouseholdController _controller = Dependencies.joinHouseholdController;

  @override
  void initState() {
    super.initState();
    _controller.clearCode();
  }

  Future<void> _joinHousehold() async {
    FocusScope.of(context).unfocus();

    final success = await _controller.joinHousehold();

    if (!mounted || !success) return;

    final Household? household = _controller.joinedHousehold;

    if (household == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Household data was not returned by the server.'),
        ),
      );
      return;
    }

    await Dependencies.householdController.loadHouseholds();

    if (!mounted) return;

    await context.push(
      '/join-household-success',
      extra: household,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = Responsive.isLandscape(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppAppBar(
            title: 'Join household',
            onBack: () => context.pop(),
            trailing: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/households'),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isLandscape ? 12 : 24,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isLandscape) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: Image.asset(
                                    'assets/images/pantry_logo.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ] else
                                const SizedBox(height: 4),

                              Text(
                                'Join a household',
                                style:
                                    (isLandscape
                                            ? theme.textTheme.titleLarge
                                            : theme.textTheme.headlineMedium)
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter the 6-digit invitation code.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isLandscape ? 14 : 32),

                              InviteCodeInput(
                                controller: _controller,
                                hasError: _controller.hasError,
                              ),

                              if (_controller.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _controller.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Join household',
                        onPressed: _controller.isLoading ? null : _joinHousehold,
                        isLoading: _controller.isLoading,
                      ),
                    ],
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
