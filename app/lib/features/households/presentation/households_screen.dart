import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/features/households/presentation/widgets/app_household_button.dart';
import 'package:common_pantry/features/households/presentation/widgets/app_household_expandable_fab.dart';
import 'package:common_pantry/features/households/presentation/widgets/empty_households_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HouseholdsScreen extends StatefulWidget {
  const HouseholdsScreen({super.key});

  @override
  State<HouseholdsScreen> createState() => _HouseholdsScreenState();
}

class _HouseholdsScreenState extends State<HouseholdsScreen> {
  bool showOptions = false;

  @override
  Widget build(BuildContext context) {
    final households = List.generate(
      5,
          (index) => 'Household ${index + 1}',
    );

    // final households = <String>[];

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
                child: households.isEmpty
                // EMPTY HOUSEHOLD LIST
                    ? const EmptyHouseholdsView()
                // HOUSEHOLDS LIST
                    : ListView.separated(
                  itemCount: households.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return AppHouseholdButton(
                      householdName: households[index],
                      onPressed: () {
                        context.push('/fridge-items');
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // FAB
      floatingActionButton: AppHouseholdExpandableFab(
        onJoinHousehold: () {
          context.push('/join-household');
        },
        onCreateHousehold: () {
          context.push('/create-household');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}