import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_button.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:common_pantry/features/households/presentation/controllers/create_household_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateHouseholdScreen extends StatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  State<CreateHouseholdScreen> createState() => _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends State<CreateHouseholdScreen> {
  final _nameController = TextEditingController();

  late final CreateHouseholdController _controller = Dependencies.createHouseholdController;

  @override
  void initState() {
    super.initState();
    _controller.clearError();
  }

  Future<void> _createHousehold() async {
    FocusScope.of(context).unfocus();

    final success = await _controller.createHousehold(
      _nameController.text,
    );

    if (!mounted || !success) return;

    final household = _controller.createdHousehold;

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

    context.pushReplacement(
      '/household-created',
      extra: household,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isLoading = _controller.isLoading;

        return Scaffold(
          appBar: AppAppBar(
            title: 'Create household',
            onBack: () => context.pop(),
            trailing: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/settings'),
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
                              SizedBox(height: isLandscape ? 8 : 16),

                              // LOGO
                              Center(
                                child: Image.asset(
                                  'assets/images/pantry_logo.png',
                                  width: isLandscape ? 60 : 96,
                                  height: isLandscape ? 60 : 96,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              SizedBox(height: isLandscape ? 12 : 24),

                              // BOLD INFO TEXT
                              Text(
                                'Create a new household',
                                style:
                                    (isLandscape
                                            ? theme.textTheme.headlineSmall
                                            : theme.textTheme.headlineMedium)
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: isLandscape ? 6 : 12),

                              // INFO TEXT
                              Text(
                                'Give your household a name.',
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: isLandscape ? 18 : 36),

                              // HOUSEHOLD NAME TEXT FIELD
                              AppInput(
                                hintText: 'Household name',
                                icon: Icons.home_outlined,
                                keyboardType: TextInputType.name,
                                controller: _nameController,
                              ),

                              // EMPTY FIELD ERROR
                              if (_controller.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _controller.errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // CREATE BUTTON
                      AppButton(
                        text: 'Create household',
                        onPressed: _createHousehold,
                        isLoading: isLoading,
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
