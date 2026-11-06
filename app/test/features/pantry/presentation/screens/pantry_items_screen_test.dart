import 'dart:async';

import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/pantry_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController controller;

  // The tile builds its labels from the real clock, so test dates are relative to today.
  final now = DateTime.now();
  DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);
  String formatted(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  final jogurt = aPantryGroup(
    id: 1,
    name: 'Jogurt',
    category: dairy,
    itemCount: 2,
    earliestExpiry: inDays(-1),
    expiryStatus: 'expired',
  );
  final mleko = aPantryGroup(
    id: 2,
    name: 'Mleko',
    category: dairy,
    earliestExpiry: inDays(1),
    expiryStatus: 'soon',
  );
  final ryz = aPantryGroup(
    id: 3,
    name: 'Ryż',
    category: readyMeals,
    earliestExpiry: inDays(30),
    expiryStatus: 'fresh',
  );

  setUp(() {
    repository = FakePantryRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    controller = PantryController(
      repository,
      households,
      syncWidget: ({required String householdName, required List<PantryGroup> groups}) async {},
    );
  });

  tearDown(() {
    controller.dispose();
    households.dispose();
  });

  Future<void> showPantry(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/pantry-items',
      routes: [
        GoRoute(
          path: '/pantry-items',
          builder: (_, _) => PantryItemsScreen(household: home, controller: controller),
        ),
        for (final path in ['/households', '/settings'])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('page $path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
  }

  group('states', () {
    testWidgets('shows a spinner until the pantry is loaded', (tester) async {
      final pending = Completer<List<PantryGroup>>();
      repository.pendingPantry = pending;

      await showPantry(tester);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete([mleko]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Mleko'), findsOneWidget);
    });

    testWidgets('a failed first load shows the error and can be retried', (tester) async {
      repository.pantryError = connectionError();

      await showPantry(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Cannot reach the server. Check your connection and try again.'),
        findsOneWidget,
      );

      repository
        ..pantryError = null
        ..pantry = [mleko];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Mleko'), findsOneWidget);
    });

    testWidgets('an empty pantry shows the empty state', (tester) async {
      await showPantry(tester);
      await tester.pumpAndSettle();

      expect(find.text('Your pantry is waiting!'), findsOneWidget);
    });
  });

  group('product tiles', () {
    testWidgets('each product shows its quantity and nearest expiry', (tester) async {
      repository.pantry = [jogurt, mleko, ryz];

      await showPantry(tester);
      await tester.pumpAndSettle();

      expect(find.text('Jogurt'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Expired yesterday'), findsOneWidget);
      expect(find.text('Expires tomorrow'), findsOneWidget);
      expect(find.text(formatted(inDays(30))), findsOneWidget);
    });

    testWidgets('expiry chips use the colours of the theme', (tester) async {
      repository.pantry = [jogurt, mleko, ryz];
      await showPantry(tester);
      await tester.pumpAndSettle();

      Color chipColor(String label) {
        final chip = tester.widget<Container>(
          find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
        );
        return (chip.decoration! as BoxDecoration).color!;
      }

      const colors = ExpiryColors.light;
      expect(chipColor('Expired yesterday'), colors.expired);
      expect(chipColor('Expires tomorrow'), colors.soon);
      expect(chipColor(formatted(inDays(30))), colors.fresh);
    });

    testWidgets('expanding a tile shows its packages and who added them', (tester) async {
      repository.pantry = [
        aPantryGroup(
          id: 4,
          name: 'Serek',
          itemCount: 2,
          earliestExpiry: inDays(5),
          expiryStatus: 'fresh',
          items: [
            aPantryGroupItem(id: 7, expiryDate: inDays(5)),
            aPantryGroupItem(id: 8, expiryDate: inDays(9), addedBy: null),
          ],
        ),
      ];
      await showPantry(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Serek'));
      await tester.pumpAndSettle();

      expect(find.text(formatted(inDays(5))), findsOneWidget);
      expect(find.text(formatted(inDays(9))), findsOneWidget);
      expect(find.text('user1'), findsOneWidget);
      expect(find.text('Unknown user'), findsOneWidget);
    });
  });

  group('search and filters', () {
    testWidgets('a search without results can be cleared', (tester) async {
      repository.pantry = [jogurt, mleko];
      await showPantry(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'czekolada');
      await tester.pump();
      expect(find.text('No products match your filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Jogurt'), findsOneWidget);
      expect(find.text('Mleko'), findsOneWidget);
    });

    testWidgets('a category chip shows only its products', (tester) async {
      repository.pantry = [jogurt, ryz];
      await showPantry(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dairy'));
      await tester.pumpAndSettle();

      expect(find.text('Jogurt'), findsOneWidget);
      expect(find.text('Ryż'), findsNothing);
    });
  });

  testWidgets('deleting a package asks for confirmation first', (tester) async {
    final first = aPantryGroupItem(id: 7, expiryDate: inDays(5));
    final second = aPantryGroupItem(id: 8, expiryDate: inDays(9));
    repository.pantry = [
      aPantryGroup(id: 4, name: 'Serek', itemCount: 2, items: [first, second]),
    ];
    await showPantry(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serek'));
    await tester.pumpAndSettle();

    Future<void> swipeFirstPackage() async {
      await tester.drag(find.byKey(const ValueKey('pantry_item_7')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete item?'), findsOneWidget);
    }

    await swipeFirstPackage();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deletedItemIds, isEmpty);
    expect(find.text(formatted(inDays(5))), findsOneWidget);

    await swipeFirstPackage();
    // After the delete the server returns the product with only the second package.
    repository.pantry = [
      aPantryGroup(id: 4, name: 'Serek', items: [second]),
    ];
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.deletedItemIds, [7]);
  });
}
