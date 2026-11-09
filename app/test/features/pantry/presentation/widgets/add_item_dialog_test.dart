import 'dart:async';

import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_item_dialog.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_manually_dialog.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/purchased_item_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController pantryController;

  /// What the fake scanner screen returns when "Fake scan" is tapped.
  late String? scannedBarcode;

  // The date picker only accepts dates around today, so the test dates are built from it.
  final today = DateTime.now();
  final pickedDate = DateTime(today.year, today.month, 28);

  final found = aProduct(id: 9, name: 'Serek wiejski', brand: 'Piątnica', category: dairy);

  setUp(() {
    repository = FakePantryRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    pantryController = PantryController(
      repository,
      households,
      syncWidget: ({required String householdName, required List<PantryGroup> groups}) async {},
    );
    scannedBarcode = null;
  });

  tearDown(() {
    pantryController.dispose();
    households.dispose();
  });

  Future<void> openChoiceDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4800);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddItemDialog(
                  context,
                  home,
                  repository: repository,
                  pantryController: pantryController,
                  // There is no camera in tests: a plain page that returns [scannedBarcode].
                  scannerBuilder: (scannerContext) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Fake scanner'),
                          ElevatedButton(
                            onPressed: () => Navigator.of(scannerContext).pop(scannedBarcode),
                            child: const Text('Fake scan'),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  /// Chooses "Scan barcode" and lets the fake scanner return [barcode].
  Future<void> scan(WidgetTester tester, String? barcode) async {
    scannedBarcode = barcode;
    await tester.tap(find.text('Scan barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake scan'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  group('choice dialog', () {
    testWidgets('offers scanning a barcode or adding manually', (tester) async {
      await openChoiceDialog(tester);

      expect(find.text('Scan barcode'), findsOneWidget);
      expect(find.text('Add manually'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('tapping outside closes the choice without opening anything', (tester) async {
      await openChoiceDialog(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Scan barcode'), findsNothing);
      expect(find.byType(AddManuallyDialog), findsNothing);
      expect(find.text('Fake scanner'), findsNothing);
    });
  });

  group('adding manually', () {
    testWidgets('"Add manually" opens the manual dialog', (tester) async {
      await openChoiceDialog(tester);

      await tester.tap(find.text('Add manually'));
      await tester.pumpAndSettle();

      expect(find.text('Scan barcode'), findsNothing);
      expect(find.byType(AddManuallyDialog), findsOneWidget);
      expect(find.text('Add manually'), findsOneWidget);
    });

    testWidgets('the dialog uses the given repository', (tester) async {
      await openChoiceDialog(tester);
      await tester.tap(find.text('Add manually'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownMenu<ItemSource>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Homemade').last);
      await tester.pumpAndSettle();
      await tester.enterText(field('Name'), 'Serek');
      await tester.pump();
      await tester.tapAt(const Offset(796, 5));
      await tester.pumpAndSettle();

      expect(find.byType(HomemadeItemForm), findsOneWidget);
      expect(repository.searchQueries, ['Serek']);
    });
  });

  group('scanning', () {
    testWidgets('"Scan barcode" opens the scanner and looks nothing up yet', (tester) async {
      await openChoiceDialog(tester);

      await tester.tap(find.text('Scan barcode'));
      await tester.pumpAndSettle();

      expect(find.text('Fake scanner'), findsOneWidget);
      expect(find.text('Scan barcode'), findsNothing);
      expect(repository.barcodeLookups, isEmpty);
    });

    testWidgets('leaving the scanner without a barcode does nothing', (tester) async {
      await openChoiceDialog(tester);
      await tester.tap(find.text('Scan barcode'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Fake scanner'), findsNothing);
      expect(find.byType(AddManuallyDialog), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(repository.barcodeLookups, isEmpty);
    });

    for (final (description, barcode) in [
      ('an empty barcode', ''),
      ('a blank barcode', '   '),
      ('no barcode', null),
    ]) {
      testWidgets('$description is ignored', (tester) async {
        await openChoiceDialog(tester);

        await scan(tester, barcode);

        expect(find.byType(AddManuallyDialog), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(repository.barcodeLookups, isEmpty);
      });
    }
  });

  group('looking up the barcode', () {
    testWidgets('asks for the trimmed barcode in the current household', (tester) async {
      await openChoiceDialog(tester);

      await scan(tester, '  5901234123457 ');

      expect(repository.barcodeLookups, [(householdId: home.id, barcode: '5901234123457')]);
    });

    testWidgets('shows a loading indicator that cannot be dismissed until the answer arrives', (
      tester,
    ) async {
      final lookup = Completer<Product?>();
      repository.pendingBarcode = lookup;
      await openChoiceDialog(tester);
      scannedBarcode = '5901234123457';
      await tester.tap(find.text('Scan barcode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fake scan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AddManuallyDialog), findsNothing);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      lookup.complete(found);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AddManuallyDialog), findsOneWidget);
    });
  });

  group('known product', () {
    testWidgets('opens the dialog for the scanned product, without a message', (tester) async {
      repository.productByBarcode = found;
      await openChoiceDialog(tester);

      await scan(tester, '5901234123457');

      expect(find.byType(AddManuallyDialog), findsOneWidget);
      expect(find.text('Add scanned item'), findsOneWidget);
      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(find.text('Serek wiejski'), findsOneWidget);
      expect(find.text('Piątnica'), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
    });

    testWidgets('can be added with just a date, using the given repository and controller', (
      tester,
    ) async {
      repository.productByBarcode = found;
      await openChoiceDialog(tester);
      await scan(tester, '5901234123457');

      await tester.tap(
        find.ancestor(of: find.text('Expiry date'), matching: find.byType(InputDecorator)).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('${pickedDate.day}'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(repository.createdProducts, isEmpty);
      expect(repository.addedItems.single.productId, 9);
      expect(repository.pantryRequests, hasLength(1));
      expect(find.byType(AddManuallyDialog), findsNothing);
    });
  });

  group('unknown product', () {
    final notFoundMessage = find.text('Product 5900000000000 not found. Enter details manually.');

    testWidgets('says it was not found and opens the form with the barcode', (tester) async {
      repository.productByBarcode = null;
      await openChoiceDialog(tester);

      await scan(tester, '5900000000000');

      expect(notFoundMessage, findsWidgets);
      expect(find.byType(AddManuallyDialog), findsOneWidget);
      expect(find.text('Add scanned item'), findsOneWidget);
      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(repository.categoriesCalls, 1);
    });

    testWidgets('leaves the name and brand editable', (tester) async {
      await openChoiceDialog(tester);

      await scan(tester, '5900000000000');

      expect(tester.widget<TextField>(field('Name')).enabled ?? true, isTrue);
      expect(tester.widget<TextField>(field('Brand')).enabled ?? true, isTrue);
    });

    testWidgets('a failed lookup is treated like an unknown product', (tester) async {
      repository.barcodeError = connectionError();
      await openChoiceDialog(tester);

      await scan(tester, '5900000000000');

      expect(repository.barcodeLookups, hasLength(1));
      expect(notFoundMessage, findsWidgets);
      expect(find.byType(AddManuallyDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
