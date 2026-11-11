import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/builders.dart';

void main() {
  late Object? lastExtra;

  setUp(() => lastExtra = null);

  Future<void> showScaffold(
    WidgetTester tester, {
    required String location,
    Size size = const Size(400, 800), // Domyślnie ekran telefonu w pionie
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              return ResponsiveScaffold(
                household: home,
                body: Text('page $path'),
              );
            },
          ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  int selectedNavIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  int selectedRailIndex(WidgetTester tester) =>
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;

  group('Mobile layout (NavigationBar)', () {
    testWidgets('shows destinations and add button', (tester) async {
      await showScaffold(tester, location: '/pantry-items');

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      for (final label in ['Household', 'Shopping list', 'Stats', 'Settings']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    for (final (location, index) in [
      ('/pantry-items', 0),
      ('/shopping-list', 1),
      ('/stats', 3),
      ('/household-settings', 4),
      ('/unknown', 0),
    ]) {
      testWidgets('$location selects destination $index', (tester) async {
        await showScaffold(tester, location: location);

        expect(selectedNavIndex(tester), index);
      });
    }

    for (final (label, path, index) in [
      ('Shopping list', '/shopping-list', 1),
      ('Stats', '/stats', 3),
      ('Settings', '/household-settings', 4),
    ]) {
      testWidgets('tapping "$label" opens $path with the household', (tester) async {
        await showScaffold(tester, location: '/pantry-items');

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text('page $path'), findsOneWidget);
        expect(lastExtra, same(home));
        expect(selectedNavIndex(tester), index);
      });
    }

    testWidgets('tapping "Household" goes back to the pantry', (tester) async {
      await showScaffold(tester, location: '/stats');

      await tester.tap(find.text('Household'));
      await tester.pumpAndSettle();

      expect(find.text('page /pantry-items'), findsOneWidget);
      expect(selectedNavIndex(tester), 0);
    });
  });

  group('Tablet / Landscape layout (NavigationRail)', () {
    const tabletSize = Size(1024, 768);

    testWidgets('shows NavigationRail instead of NavigationBar on wide screens', (tester) async {
      await showScaffold(tester, location: '/pantry-items', size: tabletSize);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget); // Przycisk '+' w NavigationRail
      for (final label in ['Household', 'Shopping', 'Stats', 'Settings']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('tapping destination in NavigationRail navigates properly', (tester) async {
      await showScaffold(tester, location: '/pantry-items', size: tabletSize);

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();

      expect(find.text('page /shopping-list'), findsOneWidget);
      expect(lastExtra, same(home));
      expect(selectedRailIndex(tester), 1);
    });
  });
}
