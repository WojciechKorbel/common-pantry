import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/features/auth/presentation/forgot_password_screen.dart';
import 'package:common_pantry/features/auth/presentation/login_screen.dart';
import 'package:common_pantry/features/auth/presentation/sign_up_screen.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/create_household_screen.dart';
import 'package:common_pantry/features/households/presentation/household_created_screen.dart';
import 'package:common_pantry/features/households/presentation/households_screen.dart';
import 'package:common_pantry/features/households/presentation/join_household_screen.dart';
import 'package:common_pantry/features/households/presentation/join_household_success_screen.dart';
import 'package:common_pantry/features/pantry/presentation/add_item_screen.dart';
import 'package:common_pantry/features/pantry/presentation/add_manually_item_screen.dart';
import 'package:common_pantry/features/pantry/presentation/household_settings_screen.dart';
import 'package:common_pantry/features/pantry/presentation/pantry_items_screen.dart';
import 'package:common_pantry/features/settings/presentation/settings_screen.dart';
import 'package:common_pantry/features/shopping/presentation/shopping_list_screen.dart';
import 'package:common_pantry/features/stats/presentation/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // For now I left here a basic placeholder - to be replaced with real routes
      GoRoute(
        path: '/items',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Pantry'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/login');
              },
              tooltip: 'Go back to login page',
            ),
          ),
          body: const Center(
            child: Text('Pantry – coming soon'),
          ),
        ),
      ),

      // AUTH
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          controller: Dependencies.loginController,
        ),
      ),

      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // HOUSEHOLD
      GoRoute(
        path: '/households',
        builder: (context, state) => HouseholdsScreen(
          controller: Dependencies.householdController,
        ),
      ),

      GoRoute(
        path: '/join-household',
        builder: (context, state) => const JoinHouseholdScreen(),
      ),
      GoRoute(
        path: '/join-household-success',
        builder: (context, state) => JoinHouseholdSuccessScreen(
          household: state.extra! as Household,
        ),
      ),
      GoRoute(
        path: '/create-household',
        builder: (context, state) => const CreateHouseholdScreen(),
      ),

      GoRoute(
        path: '/household-created',
        builder: (context, state) {
          final household = state.extra! as Household;

          return HouseholdCreatedScreen(
            household: household,
          );
        },
      ),

      GoRoute(
        path: '/pantry-items',
        builder: (context, state) {
          final household = state.extra! as Household;

          return PantryItemsScreen(
            household: household,
            controller: Dependencies.pantryController,
          );
        },
      ),

      GoRoute(
        path: '/shopping-list',
        builder: (context, state) {
          final household = state.extra! as Household;
          return ShoppingListScreen(household: household);
        },
      ),
      GoRoute(
        path: '/add-item',
        builder: (context, state) {
          final household = state.extra! as Household;
          return AddItemScreen(household: household);
        },
      ),
      GoRoute(
        path: '/add-item/manual',
        builder: (context, state) {
          final household = state.extra! as Household;
          return AddManuallyItemScreen(household: household);
        },
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) {
          final household = state.extra! as Household;
          return StatsScreen(household: household);
        },
      ),
      GoRoute(
        path: '/household-settings',
        builder: (context, state) {
          final household = state.extra! as Household;
          return HouseholdSettingsScreen(household: household);
        },
      ),

      // SETTINGS
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
