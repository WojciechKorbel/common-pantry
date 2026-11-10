import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/models/product_origin.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
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
  final pickedDate = DateTime(today.year, today.month, 28);
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
  Future<void> showForm(WidgetTester tester) async {
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
                      body: HomemadeItemForm(
                        household: home,
                        onHasDataChanged: (value) => hasData = value,
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

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(field('Name'), text);
    await tester.pump();
  }

  Future<void> leaveField(WidgetTester tester) async {
    // A tap in the empty padding takes the focus away and triggers the product lookup.
    await tester.tapAt(const Offset(796, 5));
    await tester.pumpAndSettle();
  }

  Future<void> chooseCategory(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownMenu<ProductCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickDay(WidgetTester tester, int day) async {
    await tester.tap(field('Expiry date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// A new product: the name is not known, so a category has to be chosen.
  Future<void> fillNewProduct(WidgetTester tester) async {
    await typeName(tester, 'Serek');
    await leaveField(tester);
    await chooseCategory(tester, 'Dairy');
    await pickDay(tester, pickedDate.day);
  }

  group('opening', () {
    testWidgets('shows empty fields and a disabled Add button', (tester) async {
      await showForm(tester);

      expect(field('Name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(field('Expiry date'), findsOneWidget);
      expect(find.text('Amount:'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(canAdd(tester), isFalse);
      expect(categoryEnabled(tester), isFalse);
    });

    testWidgets('does not talk to the server before the user types', (tester) async {
      await showForm(tester);

      expect(repository.searchQueries, isEmpty);
      expect(repository.categoriesCalls, 0);
    });
  });

  group('reporting data', () {
    testWidgets('typing a name reports that the form has data', (tester) async {
      await showForm(tester);

      await typeName(tester, 'Serek');

      expect(hasData, isTrue);
    });

    testWidgets('clearing everything reports that the form is empty again', (tester) async {
      await showForm(tester);
      await typeName(tester, 'Serek');

      await typeName(tester, '');

      expect(hasData, isFalse);
    });

    testWidgets('changing the amount counts as data', (tester) async {
      await showForm(tester);

      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();

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

    testWidgets('a name that is only typed is not looked up yet', (tester) async {
      await showForm(tester);

      await typeName(tester, 'Serek');

      expect(repository.searchQueries, isEmpty);
      expect(categoryEnabled(tester), isFalse);
    });

    testWidgets('an empty name is not looked up', (tester) async {
      await showForm(tester);

      await leaveField(tester);

      expect(repository.searchQueries, isEmpty);
    });

    testWidgets('an existing product fills in and locks the category', (tester) async {
      repository.products = [aProduct(id: 9, name: 'serek', category: dairy)];
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Taken from an existing product'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(categoryEnabled(tester), isFalse);
      expect(repository.categoriesCalls, 0);
    });

    testWidgets('a product with a different name is not a match', (tester) async {
      repository.products = [aProduct(id: 9, name: 'Serek ziarnisty', category: dairy)];
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(find.text('Taken from an existing product'), findsNothing);
      expect(categoryEnabled(tester), isTrue);
    });

    testWidgets('a failed search is treated like an unknown product', (tester) async {
      repository.searchError = connectionError();
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(categoryEnabled(tester), isTrue);
    });

    testWidgets('changing the name again unlocks the category', (tester) async {
      repository.products = [aProduct(id: 9, name: 'Serek', category: dairy)];
      await showForm(tester);
      await typeName(tester, 'Serek');
      await leaveField(tester);
      expect(find.text('Dairy'), findsOneWidget);

      await typeName(tester, 'Serek wiejski');

      expect(find.text('Dairy'), findsNothing);
      expect(find.text('Taken from an existing product'), findsNothing);
      expect(categoryEnabled(tester), isFalse);
    });

    testWidgets('shows a message when the categories cannot be loaded', (tester) async {
      repository.categoriesError = connectionError();
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);

      expect(find.text('Could not load categories.'), findsOneWidget);
    });
  });

  group('amount', () {
    testWidgets('the buttons change the amount between 1 and 20', (tester) async {
      await showForm(tester);
      IconButton button(IconData icon) =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));

      expect(button(Icons.remove).onPressed, isNull);

      await tester.tap(find.byTooltip('Increase'));
      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byTooltip('Decrease'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      for (var i = 0; i < 20; i++) {
        if (button(Icons.add).onPressed == null) break;
        await tester.tap(find.byTooltip('Increase'));
        await tester.pump();
      }
      expect(find.text('20'), findsOneWidget);
      expect(button(Icons.add).onPressed, isNull);
    });
  });

  group('expiry date', () {
    testWidgets('picking a date shows it in the field', (tester) async {
      await showForm(tester);

      await pickDay(tester, pickedDate.day);

      expect(find.text(formatted(pickedDate)), findsOneWidget);
      expect(hasData, isTrue);
    });

    testWidgets('cancelling the picker leaves the field empty', (tester) async {
      await showForm(tester);

      await tester.tap(field('Expiry date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text(formatted(pickedDate)), findsNothing);
      expect(hasData, isNull);
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

      await pickDay(tester, pickedDate.day);
      expect(canAdd(tester), isTrue);
    });

    testWidgets('an existing product needs no category choice', (tester) async {
      repository.products = [aProduct(id: 9, name: 'Serek', category: dairy)];
      await showForm(tester);

      await typeName(tester, 'Serek');
      await leaveField(tester);
      await pickDay(tester, pickedDate.day);

      expect(canAdd(tester), isTrue);
    });

    testWidgets('editing the name afterwards disables it again', (tester) async {
      await showForm(tester);
      await fillNewProduct(tester);
      expect(canAdd(tester), isTrue);

      await typeName(tester, 'Serek wiejski');

      expect(canAdd(tester), isFalse);
    });
  });

  group('saving', () {
    testWidgets('creates the new product, adds the items and closes', (tester) async {
      await showForm(tester);
      await fillNewProduct(tester);
      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.createdProducts, [
        (name: 'Serek', brand: null, categoryId: dairy.id, origin: ProductOrigin.homemade),
      ]);
      expect(repository.addedItems, [
        (productId: 100, expiryDate: pickedDate, count: 2, origin: ProductOrigin.homemade),
      ]);
      expect(find.byType(HomemadeItemForm), findsNothing);
      expect(find.text('Item added to the pantry'), findsOneWidget);
    });

    testWidgets('reloads the pantry after saving', (tester) async {
      await showForm(tester);
      await fillNewProduct(tester);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(repository.pantryRequests, [(householdId: home.id, search: null)]);
    });

    testWidgets('an existing product is reused instead of created again', (tester) async {
      repository.products = [aProduct(id: 9, name: 'Serek', category: dairy)];
      await showForm(tester);
      await typeName(tester, 'Serek');
      await leaveField(tester);
      await pickDay(tester, pickedDate.day);

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

      expect(find.byType(HomemadeItemForm), findsOneWidget);
      expect(find.text('Please check the entered data.'), findsOneWidget);
      expect(repository.addedItems, isEmpty);
      expect(canAdd(tester), isTrue);
    });

    testWidgets('an unreachable server shows the connection message', (tester) async {
      repository.createProductError = connectionError();
      await showForm(tester);
      await fillNewProduct(tester);

      await tester.tap(addButton());
      await tester.pumpAndSettle();

      expect(find.byType(HomemadeItemForm), findsOneWidget);
      expect(
        find.text('Cannot reach the server. Check your connection and try again.'),
        findsOneWidget,
      );
    });
  });
}
