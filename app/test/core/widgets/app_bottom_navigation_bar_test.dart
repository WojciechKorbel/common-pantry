import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/core/widgets/app_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/builders.dart';

void main() {
  late Object? lastExtra;

  setUp(() => lastExtra = null);

  Future<void> showBar(WidgetTester tester, {required String location}) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        for (final path in [
          '/pantry-items',
          '/shopping-list',
          '/stats',
          '/household-settings',
          '/unknown',
        ])
          GoRoute(
            path: path,
            builder: (_, state) {
              lastExtra = state.extra;
              return Scaffold(
                body: Text('page $path'),
                bottomNavigationBar: AppBottomNavigationBar(household: home),
              );
            },
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pumpAndSettle();
  }

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('shows the four destinations and the add button', (tester) async {
    await showBar(tester, location: '/pantry-items');

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['Household', 'Shopping list', 'Stats', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  group('selected destination', () {
    for (final (location, index) in [
      ('/pantry-items', 0),
      ('/shopping-list', 1),
      ('/stats', 3),
      ('/household-settings', 4),
      ('/unknown', 0),
    ]) {
      testWidgets('$location selects destination $index', (tester) async {
        await showBar(tester, location: location);

        expect(selectedIndex(tester), index);
      });
    }
  });

  group('navigation', () {
    for (final (label, path, index) in [
      ('Shopping list', '/shopping-list', 1),
      ('Stats', '/stats', 3),
      ('Settings', '/household-settings', 4),
    ]) {
      testWidgets('tapping "$label" opens $path with the household', (tester) async {
        await showBar(tester, location: '/pantry-items');

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text('page $path'), findsOneWidget);
        expect(lastExtra, same(home));
        expect(selectedIndex(tester), index);
      });
    }

    testWidgets('tapping "Household" goes back to the pantry', (tester) async {
      await showBar(tester, location: '/stats');

      await tester.tap(find.text('Household'));
      await tester.pumpAndSettle();

      expect(find.text('page /pantry-items'), findsOneWidget);
      expect(selectedIndex(tester), 0);
    });
  });
}
