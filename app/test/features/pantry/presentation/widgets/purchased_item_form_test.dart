import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/models/product_origin.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
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
  late bool? hasData;

  // The date picker only accepts dates around today, so the test dates are built from it.
  final today = DateTime.now();
  final firstDate = DateTime(today.year, today.month, 28);
  final secondDate = DateTime(today.year, today.month, 27);
  String formatted(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  setUp(() {
    repository = FakePantryRepository();
    households = HouseholdController(repository: FakeHouseholdsRepository(), initial: home);
    pantryController = PantryController(
      repository,
      households,
      syncWidget: ({required String householdName, required List<PantryGroup> groups}) async {},
    );
    hasData = null;
  });

  tearDown(() {
    pantryController.dispose();
    households.dispose();
  });

  /// The form pops its route after a successful save, so it is shown on a pushed route.
  Future<void> showForm(
    WidgetTester tester, {
    Product? initialProduct,
    String? initialBarcode,
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: PurchasedItemForm(
                        household: home,
                        onHasDataChanged: (value) => hasData = value,
                        initialProduct: initialProduct,
                        initialBarcode: initialBarcode,
                        repository: repository,
                        pantryController: pantryController,
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

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder addButton() => find.widgetWithText(ElevatedButton, 'Add');
  bool canAdd(WidgetTester tester) => tester.widget<ElevatedButton>(addButton()).onPressed != null;
  bool categoryEnabled(WidgetTester tester) => tester
      .widget<DropdownMenu<ProductCategory>>(find.byType(DropdownMenu<ProductCategory>))
      .enabled;
  bool fieldEnabled(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).enabled ?? true;

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(field('Name'), text);
    await tester.pump();
  }

  Future<void> typeBrand(WidgetTester tester, String text) async {
    await tester.enterText(field('Brand'), text);
    await tester.pump();
  }

  Future<void> leaveField(WidgetTester tester) async {
    // A tap in the empty padding takes the focus away and triggers the lookup.
    await tester.tapAt(const Offset(796, 5));
    await tester.pumpAndSettle();
  }

  Future<void> chooseCategory(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownMenu<ProductCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  /// Picks a day in the date picker opened by [target] (a row's "Expiry date" field).
  Future<void> pickDay(WidgetTester tester, Finder target, int day) async {
    await tester.tap(find.ancestor(of: target, matching: find.byType(InputDecorator)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> addRow(WidgetTester tester) async {
    await tester.tap(find.text('Add another date'));
    await tester.pump();
  }

  /// A product nobody knows yet: name, brand, a category and one date.
  Future<void> fillNewProduct(WidgetTester tester) async {
    await typeName(tester, 'Serek');
    await leaveField(tester);
    await typeBrand(tester, 'Nowa');
    await leaveField(tester);
    await chooseCategory(tester, 'Dairy');
    await pickDay(tester, find.text('Expiry date').first, firstDate.day);
  }

  final piatnica = aProduct(id: 9, name: 'Serek', brand: 'Piątnica', category: dairy);
  final bakoma = aProduct(id: 10, name: 'Serek', brand: 'Bakoma', category: readyMeals);

  group('opening', () {
    testWidgets('shows empty fields, one date row and a disabled Add button', (tester) async {
      await showForm(tester);

      expect(field('Name'), findsOneWidget);
      expect(field('Brand'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Expiry date'), findsOneWidget);
      expect(find.text('Add another date'), findsOneWidget);
      expect(canAdd(tester), isFalse);
      expect(categoryEnabled(tester), isFalse);
      expect(repository.searchQueries, isEmpty);
    });

    testWidgets('a scanned barcode without a product loads the categories at once', (tester) async {
      await showForm(tester, initialBarcode: '5900000000000');

      expect(repository.categoriesCalls, 1);
    });
  });

  group('reporting data', () {
    testWidgets('typing a name reports data, clearing it reports none', (tester) async {
      await showForm(tester);

      await typeName(tester, 'Serek');
      expect(hasData, isTrue);

      await typeName(tester, '');
      expect(hasData, isFalse);
    });

    testWidgets('a brand or an extra date row counts as data', (tester) async {
      await showForm(tester);

      await typeBrand(tester, 'Piątnica');
      expect(hasData, isTrue);

      await typeBrand(tester, '');
      expect(hasData, isFalse);

      await addRow(tester);
      expect(hasData, isTrue);
    });
  });

  group('looking up the name', () {
    testWidgets('leaving the name field searches for it and loads the categories', (tester) async {
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(repository.searchQueries, ['Serek']);
      expect(repository.categoriesCalls, 1);
      expect(categoryEnabled(tester), isTrue);
    });

    testWidgets('one product with that name fills in and locks the brand and category', (
      tester,
    ) async {
      repository.products = [piatnica];
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(find.text('Piątnica'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Taken from an existing product'), findsOneWidget);
      expect(fieldEnabled(tester, 'Brand'), isFalse);
      expect(categoryEnabled(tester), isFalse);
      expect(repository.categoriesCalls, 0);
    });

    testWidgets('changing the name afterwards unlocks the brand and category', (tester) async {
      repository.products = [piatnica];
      await showForm(tester);
      await typeName(tester, 'Serek');
      await leaveField(tester);

      await typeName(tester, 'Serek wiejski');

      expect(fieldEnabled(tester, 'Brand'), isTrue);
      expect(find.text('Piątnica'), findsNothing);
      expect(find.text('Dairy'), findsNothing);
      expect(find.text('Taken from an existing product'), findsNothing);
    });

    testWidgets('several brands with that name leave the brand to the user', (tester) async {
      repository.products = [piatnica, bakoma];
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(fieldEnabled(tester, 'Brand'), isTrue);
      expect(categoryEnabled(tester), isTrue);
    });

    testWidgets('typing a known brand afterwards picks that product', (tester) async {
      repository.products = [piatnica, bakoma];
      await showForm(tester);
      await typeName(tester, 'Serek');
      await leaveField(tester);

      await typeBrand(tester, 'bakoma');
      await leaveField(tester);

      expect(find.text('Ready meals & soups'), findsOneWidget);
      expect(categoryEnabled(tester), isFalse);
    });

    testWidgets('typing an unknown brand keeps the category open', (tester) async {
      repository.products = [piatnica, bakoma];
      await showForm(tester);
      await typeName(tester, 'Serek');
      await leaveField(tester);

      await typeBrand(tester, 'Nowa');
      await leaveField(tester);

      expect(categoryEnabled(tester), isTrue);
      expect(find.text('Dairy'), findsNothing);
    });

    testWidgets('a failed search is treated like an unknown product', (tester) async {
      repository.searchError = connectionError();
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(categoryEnabled(tester), isTrue);
    });

    testWidgets('shows a message when the categories cannot be loaded', (tester) async {
      repository.categoriesError = connectionError();
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(find.text('Could not load categories.'), findsOneWidget);
    });
  });

  group('scanned product', () {
    final scanned = aProduct(id: 9, name: 'Serek wiejski', brand: 'Piątnica', category: dairy);

    testWidgets('locks the name, brand and category', (tester) async {
      await showForm(tester, initialProduct: scanned);

      expect(find.text('Serek wiejski'), findsOneWidget);
      expect(find.text('Piątnica'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Taken from scanned product'), findsNWidgets(2));
      expect(fieldEnabled(tester, 'Name'), isFalse);
      expect(fieldEnabled(tester, 'Brand'), isFalse);
      expect(categoryEnabled(tester), isFalse);
      expect(hasData, isTrue);
    });

    testWidgets('does not search for the product again', (tester) async {
      await showForm(tester, initialProduct: scanned);

      await tester.tapAt(const Offset(796, 5));
      await tester.pumpAndSettle();

      expect(repository.searchQueries, isEmpty);
    });

    testWidgets('only needs a date to be added, and reuses the product', (tester) async {
      await showForm(tester, initialProduct: scanned);
      expect(canAdd(tester), isFalse);

      await pickDay(tester, find.text('Expiry date').first, firstDate.day);
      expect(canAdd(tester), isTrue);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.createdProducts, isEmpty);
      expect(repository.addedItems, [
        (productId: 9, expiryDate: firstDate, count: 1, origin: ProductOrigin.purchased),
      ]);
    });
  });

  group('date rows', () {
    testWidgets('a new row can be added and removed again', (tester) async {
      await showForm(tester);
      expect(
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline)).onPressed,
        isNull,
      );

      await addRow(tester);
      expect(find.text('Expiry date'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Remove date').first);
      await tester.pump();
      expect(find.text('Expiry date'), findsOneWidget);
    });

    testWidgets('each row has its own date', (tester) async {
      await showForm(tester);
      await addRow(tester);

      await pickDay(tester, find.text('Expiry date').first, firstDate.day);
      await pickDay(tester, find.text('Expiry date').last, secondDate.day);

      expect(find.text(formatted(firstDate)), findsOneWidget);
      expect(find.text(formatted(secondDate)), findsOneWidget);
    });

    testWidgets('each row has its own amount between 1 and 20', (tester) async {
      await showForm(tester);
      await addRow(tester);
      IconButton first(IconData icon) =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon).first);

      expect(first(Icons.remove).onPressed, isNull);

      await tester.tap(find.byTooltip('Increase').first);
      await tester.tap(find.byTooltip('Increase').first);
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Decrease').first);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      for (var i = 0; i < 20; i++) {
        if (first(Icons.add).onPressed == null) break;
        await tester.tap(find.byTooltip('Increase').first);
        await tester.pump();
      }
      expect(find.text('20'), findsOneWidget);
      expect(first(Icons.add).onPressed, isNull);
    });

    testWidgets('cancelling the date picker leaves the row empty', (tester) async {
      await showForm(tester);

      await tester.tap(
        find.ancestor(of: find.text('Expiry date'), matching: find.byType(InputDecorator)).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text(formatted(firstDate)), findsNothing);
    });
  });

  group('Add button', () {
    testWidgets('needs a name, a checked name, a category and a date', (tester) async {
      await showForm(tester);

      await typeName(tester, 'Serek');
      expect(canAdd(tester), isFalse);

      await leaveField(tester);
      expect(canAdd(tester), isFalse);

      await chooseCategory(tester, 'Dairy');
      expect(canAdd(tester), isFalse);

      await pickDay(tester, find.text('Expiry date').first, firstDate.day);
      expect(canAdd(tester), isTrue);
    });

    testWidgets('every date row needs a date', (tester) async {
      await showForm(tester);
      await fillNewProduct(tester);
      expect(canAdd(tester), isTrue);

      await addRow(tester);
      expect(canAdd(tester), isFalse);

      await pickDay(tester, find.text('Expiry date').last, secondDate.day);
      expect(canAdd(tester), isTrue);
    });
  });

  group('saving', () {
    testWidgets('creates the product and adds every date row, then closes', (tester) async {
      await showForm(tester);
      await fillNewProduct(tester);
      await tester.tap(find.byTooltip('Increase').first);
      await tester.pump();
      await addRow(tester);
      await pickDay(tester, find.text('Expiry date').last, secondDate.day);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.createdProducts, [
        (name: 'Serek', brand: 'Nowa', categoryId: dairy.id, origin: ProductOrigin.purchased),
      ]);
      expect(repository.addedItems, [
        (productId: 100, expiryDate: firstDate, count: 2, origin: ProductOrigin.purchased),
        (productId: 100, expiryDate: secondDate, count: 1, origin: ProductOrigin.purchased),
      ]);
      expect(find.byType(PurchasedItemForm), findsNothing);
      expect(find.text('Items added to the pantry'), findsOneWidget);
    });

    testWidgets('reloads the pantry after saving', (tester) async {
      await showForm(tester);
      await fillNewProduct(tester);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.pantryRequests, [(householdId: home.id, search: null)]);
    });

    testWidgets('an existing product is reused instead of created again', (tester) async {
      repository.products = [piatnica];
      await showForm(tester);
      await typeName(tester, 'Serek');
      await leaveField(tester);
      await pickDay(tester, find.text('Expiry date').first, firstDate.day);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.createdProducts, isEmpty);
      expect(repository.addedItems.single.productId, 9);
    });

    testWidgets('a server error keeps the form open and shows the message', (tester) async {
      repository.addItemsError = serverError(400);
      await showForm(tester);
      await fillNewProduct(tester);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(find.text('Please check the entered data.'), findsOneWidget);
      expect(canAdd(tester), isTrue);
    });

    testWidgets('an unreachable server shows the connection message', (tester) async {
      repository.createProductError = connectionError();
      await showForm(tester);
      await fillNewProduct(tester);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(find.byType(PurchasedItemForm), findsOneWidget);
      expect(
        find.text('Cannot reach the server. Check your connection and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('after a partial failure a retry adds only the missing date', (tester) async {
      repository
        ..addItemsError = serverError(400)
        ..failAddItemsOnCall = 2;
      await showForm(tester);
      await fillNewProduct(tester);
      await addRow(tester);
      await pickDay(tester, find.text('Expiry date').last, secondDate.day);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.addedItems.map((i) => i.expiryDate), [firstDate]);
      expect(
        find.text('Some dates were already added. Please check the entered data.'),
        findsOneWidget,
      );
      expect(find.text(formatted(firstDate)), findsNothing);
      expect(find.text(formatted(secondDate)), findsOneWidget);
      expect(find.text('Expiry date'), findsOneWidget);

      repository
        ..addItemsError = null
        ..failAddItemsOnCall = null;
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.createdProducts, hasLength(1));
      expect(repository.addedItems.map((i) => i.expiryDate), [firstDate, secondDate]);
      expect(find.byType(PurchasedItemForm), findsNothing);
    });
  });
}
