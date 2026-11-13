import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pantry_search_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController controller;
  late TextEditingController searchController;
  late int notifications;

  setUp(() {
    repository = FakePantryRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    controller = PantryController(
      repository,
      households,
      syncWidget: ({required String householdName, required List<PantryGroup> groups}) async {},
    );
    searchController = TextEditingController();
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() {
    searchController.dispose();
    controller.dispose();
    households.dispose();
  });

  Future<void> showSearchBar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PantrySearchBar(controller: controller, searchController: searchController),
        ),
      ),
    );
  }

  Future<void> openFilterMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Filter by expiry date'));
    await tester.pumpAndSettle();
  }

  Finder checkOn(String label) => find.descendant(
    of: find.widgetWithText(PopupMenuItem<ExpiryFilterOption>, label),
    matching: find.byIcon(Icons.check),
  );

  group('search field', () {
    testWidgets('shows the hint and no clear button while empty', (tester) async {
      await showSearchBar(tester);

      expect(find.text('Search for a product or brand...'), findsOneWidget);
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('typing passes the query to the controller and shows the clear button', (
      tester,
    ) async {
      await showSearchBar(tester);

      await tester.enterText(find.byType(TextField), 'jogurt');
      await tester.pump();

      expect(notifications, greaterThan(0));
      expect(find.byTooltip('Clear search'), findsOneWidget);
    });

    testWidgets('text that is already in the search controller shows the clear button', (
      tester,
    ) async {
      searchController.text = 'mleko';

      await showSearchBar(tester);

      expect(find.byTooltip('Clear search'), findsOneWidget);
    });

    testWidgets('the clear button empties the field and the query', (tester) async {
      await showSearchBar(tester);
      await tester.enterText(find.byType(TextField), 'jogurt');
      await tester.pump();
      final before = notifications;

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(searchController.text, isEmpty);
      expect(notifications, greaterThan(before));
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });

  group('expiry filter menu', () {
    testWidgets('lists every option and marks "All" as selected by default', (tester) async {
      await showSearchBar(tester);
      await openFilterMenu(tester);

      for (final label in ['All', 'Fresh', 'Expiring soon', 'Expired']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(checkOn('All'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('no filter means no badge on the filter icon', (tester) async {
      await showSearchBar(tester);

      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });

    for (final (label, status) in [
      ('Fresh', ExpiryStatus.fresh),
      ('Expiring soon', ExpiryStatus.soon),
      ('Expired', ExpiryStatus.expired),
    ]) {
      testWidgets('choosing "$label" sets the filter, badge and check mark', (tester) async {
        await showSearchBar(tester);
        await openFilterMenu(tester);

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(controller.expiryFilter, status);
        expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);

        await openFilterMenu(tester);
        expect(checkOn(label), findsOneWidget);
        expect(checkOn('All'), findsNothing);
      });
    }

    testWidgets('choosing "All" removes the filter again', (tester) async {
      await showSearchBar(tester);
      await openFilterMenu(tester);
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      expect(controller.expiryFilter, ExpiryStatus.expired);

      await openFilterMenu(tester);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(controller.expiryFilter, isNull);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });
  });
}
