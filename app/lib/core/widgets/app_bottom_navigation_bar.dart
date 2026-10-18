import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.household,
  });

  final Household household;

  static const _routes = [
    '/pantry-items',
    '/shopping-list',
    '/add-item',
    '/stats',
    '/household-settings',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    final selectedIndex = switch (location) {
      '/shopping-list' => 1,
      '/add-item' => 2,
      '/stats' => 3,
      '/household-settings' => 4,
      _ => 0,
    };

    return NavigationBar(
      selectedIndex: selectedIndex,
      indicatorColor: selectedIndex == 2 ? Colors.transparent : null,
      onDestinationSelected: (index) {
        context.go(
          _routes[index],
          extra: household,
        );
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: 'Household',
        ),
        const NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Shopping list',
        ),
        NavigationDestination(
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
          ),
          label: '',
        ),
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
