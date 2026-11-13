import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_item_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class ResponsiveNavigationScaffold extends StatelessWidget {
  const ResponsiveNavigationScaffold({
    super.key,
    required this.household,
    required this.child,
  });

  final Household household;
  final Widget child;

  static const _addIndex = 2;

  static const _routes = {
    0: '/pantry-items',
    1: '/shopping-list',
    3: '/stats',
    4: '/household-settings',
  };

  void _onItemTapped(BuildContext context, int index) {
    if (index == _addIndex) {
      showAddItemDialog(context, household);
      return;
    }
    context.go(_routes[index]!, extra: household);
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return switch (location) {
      '/shopping-list' => 1,
      '/stats' => 3,
      '/household-settings' => 4,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final useNavRail =
        Responsive.isTablet(context) ||
        Responsive.isDesktop(context) ||
        Responsive.isLandscape(context);

    final selectedIndex = _calculateSelectedIndex(context);

    if (useNavRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex == _addIndex ? 0 : selectedIndex,
              onDestinationSelected: (index) {
                _onItemTapped(context, index);
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: FloatingActionButton(
                  elevation: 0,
                  onPressed: () => showAddItemDialog(context, household),
                  child: const Icon(Icons.add),
                ),
              ),
              labelType: NavigationRailLabelType.all,
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
                  icon: SizedBox.shrink(),
                  label: SizedBox.shrink(),
                  disabled: true,
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
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
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
