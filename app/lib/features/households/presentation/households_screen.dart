import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/households/presentation/widgets/app_household_button.dart';
import 'package:common_pantry/features/households/presentation/widgets/app_household_expandable_fab.dart';
import 'package:common_pantry/features/households/presentation/widgets/empty_households_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HouseholdsScreen extends StatefulWidget {
  const HouseholdsScreen({
    super.key,
    required this.controller,
  });

  final HouseholdController controller;

  @override
  State<HouseholdsScreen> createState() => _HouseholdsScreenState();
}

class _HouseholdsScreenState extends State<HouseholdsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadHouseholds();
  }

  Future<void> _openAndRefresh(String route) async {
    await context.push(route);

    if (!mounted) return;

    await widget.controller.loadHouseholds();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final controller = widget.controller;

        return Scaffold(
          appBar: AppAppBar(
            title: 'Households',
            onBack: () => context.pop(),
            trailing: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/settings'),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: _buildBody(controller),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          floatingActionButton: AppHouseholdExpandableFab(
            onJoinHousehold: () {
              _openAndRefresh('/join-household');
            },
            onCreateHousehold: () {
              _openAndRefresh('/create-household');
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildBody(HouseholdController controller) {
    if (controller.isLoading && controller.households.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage != null && controller.households.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadHouseholds,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 250,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.isLoading ? null : controller.loadHouseholds,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.households.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadHouseholds,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 300,
              child: Center(
                child: EmptyHouseholdsView(),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadHouseholds,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.households.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final household = controller.households[index];

          return AppHouseholdButton(
            householdName: household.name,
            onPressed: () {
              controller.select(household);
              context.push('/fridge-items');
            },
          );
        },
      ),
    );
  }
}
