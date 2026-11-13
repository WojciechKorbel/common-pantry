import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_manually_dialog.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/purchased_item_form.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController pantryController;

  // The date picker only accepts dates around today, so the test dates are built from it.
  final today = DateTime.now();
  final pickedDate = DateTime(today.year, today.month, 28);

  final scanned = aProduct(id: 9, name: 'Serek wiejski', brand: 'Piątnica', category: dairy);

  setUp(() {
    repository = FakePantryRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    pantryController = PantryController(
      repository,
      households,
      syncWidget: ({required String householdName, required List<PantryGroup> groups}) async {},
    );
  });

  tearDown(() {
    pantryController.dispose();
    households.dispose();
  });

  Future<void> openDialog(
    WidgetTester tester, {
    ItemSource? source,
    Product? product,
    String? barcode,
  }) async {
    tester.view.physicalSize = const Size(2400, 4800);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddManuallyDialog(
                  context,
                  home,
                  initialSource: source,
                  initialProduct: product,
                  initialBarcode: barcode,
                  repository: repository,
                  pantryController: pantryController,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> chooseSource(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownMenu<ItemSource>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(field('Name'), text);
    await tester.pump();
  }

  Future<void> closeDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
  }

  Future<void> pickDay(WidgetTester tester, int day) async {
    await tester.tap(
      find.ancestor(of: find.text('Expiry date'), matching: find.byType(InputDecorator)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('without a source', () {
    testWidgets('starts with a title, a source selector and no form', (tester) async {
      await openDialog(tester);

      expect(find.byType(AddManuallyDialog), findsOneWidget);
      expect(find.text('Add manually'), findsOneWidget);
      expect(find.text('Add scanned item'), findsNothing);
      expect(find.text('Source'), findsOneWidget);
      expect(find.byType(HomemadeItemForm), findsNothing);
      expect(find.byType(PurchasedItemForm), findsNothing);
    });

    testWidgets('the close button closes the dialog when nothing was entered', (tester) async {
      await openDialog(tester);

      await closeDialog(tester);

      expect(find.byType(AddManuallyDialog), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('the system back button closes the dialog when nothing was entered', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(AddManuallyDialog), findsNothing);
    });
  });

  group('choosing the source', () {
    testWidgets('"Homemade" shows the homemade form', (tester) async {
      await openDialog(tester);

      await chooseSource(tester, 'Homemade');

      expect(find.byType(HomemadeItemForm), findsOneWidget);
      expect(find.byType(PurchasedItemForm), findsNothing);
    });

    testWidgets('"Purchased" shows the purchased form', (tester) async {
      await openDialog(tester);

      await chooseSource(tester, 'Purchased');

      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(find.byType(HomemadeItemForm), findsNothing);
    });

    testWidgets('an initial source is selected from the start', (tester) async {
      await openDialog(tester, source: ItemSource.homemade);

      expect(find.byType(HomemadeItemForm), findsOneWidget);
      expect(find.text('Homemade'), findsOneWidget);
    });

    testWidgets('switching the source replaces the form and forgets what was typed', (
      tester,
    ) async {
      await openDialog(tester, source: ItemSource.homemade);
      await typeName(tester, 'Serek');

      await chooseSource(tester, 'Purchased');

      expect(find.byType(HomemadeItemForm), findsNothing);
      expect(find.byType(PurchasedItemForm), findsOneWidget);

      await closeDialog(tester);
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(AddManuallyDialog), findsNothing);
    });
  });

  group('closing with data', () {
    testWidgets('asks before throwing it away and can keep editing', (tester) async {
      await openDialog(tester, source: ItemSource.homemade);
      await typeName(tester, 'Serek');

      await closeDialog(tester);
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(AddManuallyDialog), findsOneWidget);
      expect(find.text('Serek'), findsOneWidget);
    });

    testWidgets('discarding closes the dialog without adding anything', (tester) async {
      await openDialog(tester, source: ItemSource.homemade);
      await typeName(tester, 'Serek');

      await closeDialog(tester);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(AddManuallyDialog), findsNothing);
      expect(repository.addedItems, isEmpty);
    });

    testWidgets('the system back button also asks first', (tester) async {
      await openDialog(tester, source: ItemSource.homemade);
      await typeName(tester, 'Serek');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.byType(AddManuallyDialog), findsOneWidget);
    });
  });

  group('adding an item', () {
    testWidgets('a saved homemade item closes the dialog and reloads the pantry', (tester) async {
      await openDialog(tester, source: ItemSource.homemade);
      await typeName(tester, 'Serek');
      await tester.tapAt(const Offset(796, 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenu<ProductCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dairy').last);
      await tester.pumpAndSettle();
      await pickDay(tester, pickedDate.day);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(repository.addedItems.single.expiryDate, pickedDate);
      expect(find.byType(AddManuallyDialog), findsNothing);
      expect(find.text('Item added to the pantry'), findsOneWidget);
      expect(repository.pantryRequests, hasLength(1));
    });
  });

  group('scanned product', () {
    testWidgets('fixes the source to purchased and locks the product details', (tester) async {
      await openDialog(tester, product: scanned);

      expect(find.text('Add scanned item'), findsOneWidget);
      expect(find.text('Fixed to purchased for scanned items'), findsOneWidget);
      expect(find.text('Purchased'), findsOneWidget);
      expect(
        tester.widget<DropdownMenu<ItemSource>>(find.byType(DropdownMenu<ItemSource>)).enabled,
        isFalse,
      );
      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(find.text('Taken from scanned product'), findsNWidgets(2));
    });

    testWidgets('counts as data, so closing asks first', (tester) async {
      await openDialog(tester, product: scanned);

      await closeDialog(tester);
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(AddManuallyDialog), findsNothing);
    });

    testWidgets('a date is enough to add it', (tester) async {
      await openDialog(tester, product: scanned);

      await pickDay(tester, pickedDate.day);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(repository.addedItems.single.productId, 9);
      expect(repository.createdProducts, isEmpty);
      expect(find.byType(AddManuallyDialog), findsNothing);
    });
  });

  group('unknown barcode', () {
    testWidgets('opens the purchased form with the categories ready', (tester) async {
      await openDialog(tester, barcode: '5900000000000');

      expect(find.text('Add scanned item'), findsOneWidget);
      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(repository.categoriesCalls, 1);
    });

    testWidgets('leaves the name and brand editable', (tester) async {
      await openDialog(tester, barcode: '5900000000000');

      expect(tester.widget<TextField>(field('Name')).enabled ?? true, isTrue);
      expect(tester.widget<TextField>(field('Brand')).enabled ?? true, isTrue);
    });

    testWidgets('closing right away does not ask, because nothing was typed', (tester) async {
      await openDialog(tester, barcode: '5900000000000');

      await closeDialog(tester);

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(AddManuallyDialog), findsNothing);
    });

    testWidgets('typing something makes closing ask first', (tester) async {
      await openDialog(tester, barcode: '5900000000000');
      await typeName(tester, 'Serek');

      await closeDialog(tester);

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });
}
