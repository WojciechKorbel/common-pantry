import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_item_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.household,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  final Household household;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  static const _routes = {
    0: '/pantry-items',
    1: '/shopping-list',
    2: '/stats',
    3: '/household-settings',
  };

  void _onNavigate(BuildContext context, int index) {
    final targetRoute = _routes[index];
    if (targetRoute != null) {
      context.go(targetRoute, extra: household);
    }
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return switch (location) {
      '/shopping-list' => 1,
      '/stats' => 2,
      '/household-settings' => 3,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Używamy NavigationRail na tabletach lub gdy w poziomie mamy wystarczająco miejsca
    final isExpanded =
        Responsive.isTablet(context) ||
        Responsive.isDesktop(context) ||
        Responsive.isLandscape(context);

    // Na niskich ekranach (np. telefon w landscape, wys. < 450) ukrywamy napisy pod ikonami
    final isShortScreen = size.height < 450;
    final selectedIndex = _getSelectedIndex(context);

    if (isExpanded) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      size.height -
                      (appBar?.preferredSize.height ?? 0) -
                      MediaQuery.paddingOf(context).top,
                ),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _onNavigate(context, index),
                    labelType: isShortScreen
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: IconButton.filled(
                        iconSize: 22,
                        tooltip: 'Add item',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => showAddItemDialog(context, household),
                        icon: const Icon(Icons.add),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.location_on_outlined),
                        selectedIcon: Icon(Icons.location_on),
                        label: Text('Household'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.shopping_cart_outlined),
                        selectedIcon: Icon(Icons.shopping_cart),
                        label: Text('Shopping'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart),
                        label: Text('Stats'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_getSelectedIndex(context)) {
          1 => 1,
          2 => 3,
          3 => 4,
          _ => 0,
        },
        onDestinationSelected: (index) {
          if (index == 2) {
            showAddItemDialog(context, household);
            return;
          }
          final routeMap = {
            0: '/pantry-items',
            1: '/shopping-list',
            3: '/stats',
            4: '/household-settings',
          };
          context.go(routeMap[index]!, extra: household);
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
      ),
    );
  }
}
