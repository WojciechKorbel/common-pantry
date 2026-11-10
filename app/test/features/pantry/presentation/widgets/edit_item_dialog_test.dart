import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/edit_item_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController controller;

  // The date picker only accepts dates around today, so the test dates are built from it.
  final today = DateTime.now();
  final expiry = DateTime(today.year, today.month, 15);
  final newExpiry = DateTime(today.year, today.month, 20);
  String formatted(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  // A product without a brand is treated as homemade, one with a brand as purchased.
  final homemade = aPantryGroup(id: 5, name: 'Serek wiejski', category: dairy);
  final purchased = PantryGroup(
    id: 5,
    name: 'Serek wiejski',
    brand: 'Piątnica',
    imageUrl: null,
    packageSize: '',
    category: dairy,
    itemCount: 1,
    earliestExpiry: expiry,
    expiryStatus: null,
    items: const [],
  );
  final item = aPantryGroupItem(id: 7, expiryDate: expiry);

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

  Future<void> openDialog(WidgetTester tester, PantryGroup product) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showEditItemDialog(
                  context,
                  product: product,
                  item: item,
                  controller: controller,
                  repository: repository,
                  householdId: home.id,
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
  Finder saveButton() => find.widgetWithText(ElevatedButton, 'Save changes');
  bool canSave(WidgetTester tester) =>
      tester.widget<ElevatedButton>(saveButton()).onPressed != null;

  /// While the dialog is open a second Scaffold sits under it, so look inside the dialog.
  Finder inDialog(String text) =>
      find.descendant(of: find.byType(EditItemDialog), matching: find.text(text));

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(field('Name'), text);
    await tester.pump();
  }

  Future<void> leaveNameField(WidgetTester tester) async {
    // Tapping outside the name field takes the focus away and triggers the product lookup.
    await tester.tap(find.text('Edit item'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseCategory(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownMenu<ProductCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickNewDate(WidgetTester tester) async {
    await tester.tap(field('Expiry date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${newExpiry.day}'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('opening', () {
    testWidgets('shows the current name, category and expiry date', (tester) async {
      await openDialog(tester, homemade);

      expect(find.text('Edit item'), findsOneWidget);
      expect(find.text('Serek wiejski'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text(formatted(expiry)), findsOneWidget);
      expect(find.byTooltip('Delete item'), findsOneWidget);
      expect(canSave(tester), isFalse);
    });

    testWidgets('loads the categories once', (tester) async {
      await openDialog(tester, homemade);

      expect(repository.categoriesCalls, 1);
    });

    testWidgets('a homemade product has no brand field', (tester) async {
      await openDialog(tester, homemade);

      expect(find.text('Brand'), findsNothing);
    });

    testWidgets('a purchased product shows its brand', (tester) async {
      await openDialog(tester, purchased);

      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Piątnica'), findsOneWidget);
    });

    testWidgets('survives a failed categories request', (tester) async {
      repository.categoriesError = connectionError();

      await openDialog(tester, homemade);

      expect(find.text('Edit item'), findsOneWidget);
      expect(canSave(tester), isFalse);
    });
  });

  group('save button', () {
    testWidgets('is enabled after changing the name', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, 'Serek ziarnisty');

      expect(canSave(tester), isTrue);
    });

    testWidgets('is disabled when the name is empty', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, '   ');

      expect(canSave(tester), isFalse);
    });

    testWidgets('is disabled again when the name change is undone', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, 'Serek ziarnisty');
      await typeName(tester, 'Serek wiejski');

      expect(canSave(tester), isFalse);
    });

    testWidgets('is enabled after changing the brand of a purchased product', (tester) async {
      await openDialog(tester, purchased);

      await tester.enterText(field('Brand'), 'Mlekovita');
      await tester.pump();

      expect(canSave(tester), isTrue);
    });

    testWidgets('is enabled after choosing another category', (tester) async {
      await openDialog(tester, homemade);

      await chooseCategory(tester, 'Ready meals & soups');

      expect(canSave(tester), isTrue);
    });

    testWidgets('is enabled after picking another expiry date', (tester) async {
      await openDialog(tester, homemade);

      await pickNewDate(tester);

      expect(find.text(formatted(newExpiry)), findsOneWidget);
      expect(canSave(tester), isTrue);
    });
  });

  group('expiry date picker', () {
    testWidgets('cancelling keeps the date', (tester) async {
      await openDialog(tester, homemade);

      await tester.tap(field('Expiry date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text(formatted(expiry)), findsOneWidget);
      expect(canSave(tester), isFalse);
    });
  });

  group('saving', () {
    testWidgets('a changed name updates only the product', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, '  Serek ziarnisty ');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(repository.updatedProducts, [
        (productId: 5, name: 'Serek ziarnisty', brand: null, categoryId: 4),
      ]);
      expect(repository.updatedItems, isEmpty);
      expect(find.byType(EditItemDialog), findsNothing);
      expect(find.text('Item updated'), findsOneWidget);
    });

    testWidgets('a changed date updates only the item', (tester) async {
      await openDialog(tester, homemade);
      await pickNewDate(tester);

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(repository.updatedItems, [(itemId: 7, expiryDate: newExpiry)]);
      expect(repository.updatedProducts, isEmpty);
      expect(find.byType(EditItemDialog), findsNothing);
      expect(find.text('Item updated'), findsOneWidget);
    });

    testWidgets('changing both updates the product and the item', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, 'Serek ziarnisty');
      await pickNewDate(tester);

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(repository.updatedProducts.single.name, 'Serek ziarnisty');
      expect(repository.updatedItems, [(itemId: 7, expiryDate: newExpiry)]);
    });

    testWidgets('sends the new brand of a purchased product', (tester) async {
      await openDialog(tester, purchased);
      await tester.enterText(field('Brand'), 'Mlekovita');
      await tester.pump();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(repository.updatedProducts, [
        (productId: 5, name: 'Serek wiejski', brand: 'Mlekovita', categoryId: 4),
      ]);
    });

    testWidgets('sends the chosen category', (tester) async {
      await openDialog(tester, homemade);
      await chooseCategory(tester, 'Ready meals & soups');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(repository.updatedProducts.single.categoryId, readyMeals.id);
    });

    testWidgets('a server error keeps the dialog open and shows the message', (tester) async {
      repository.itemActionError = serverError(404);
      await openDialog(tester, homemade);
      await typeName(tester, 'Serek ziarnisty');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(EditItemDialog), findsOneWidget);
      expect(inDialog('Item or household not found.'), findsOneWidget);
      expect(canSave(tester), isTrue);
    });

    testWidgets('a failed date update keeps the dialog open', (tester) async {
      repository.itemActionError = connectionError();
      await openDialog(tester, homemade);
      await pickNewDate(tester);

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(EditItemDialog), findsOneWidget);
      expect(
        inDialog('Cannot reach the server. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(repository.updatedItems, isEmpty);
    });
  });

  group('deleting', () {
    testWidgets('asks for confirmation and names the item', (tester) async {
      await openDialog(tester, homemade);

      await tester.tap(find.byTooltip('Delete item'));
      await tester.pumpAndSettle();

      expect(find.text('Delete item?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Serek wiejski" expiring on ${formatted(expiry)}?',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancelling keeps the item and the dialog', (tester) async {
      await openDialog(tester, homemade);

      await tester.tap(find.byTooltip('Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.deletedItemIds, isEmpty);
      expect(find.text('Delete item?'), findsNothing);
      expect(find.byType(EditItemDialog), findsOneWidget);
    });

    testWidgets('confirming deletes the item, closes the dialog and confirms', (tester) async {
      await openDialog(tester, homemade);

      await tester.tap(find.byTooltip('Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.deletedItemIds, [7]);
      expect(find.byType(EditItemDialog), findsNothing);
      expect(find.text('Item deleted from the pantry'), findsOneWidget);
    });

    testWidgets('a server error keeps the dialog open and shows the message', (tester) async {
      repository.itemActionError = serverError(404);
      await openDialog(tester, homemade);

      await tester.tap(find.byTooltip('Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.deletedItemIds, isEmpty);
      expect(find.byType(EditItemDialog), findsOneWidget);
      expect(inDialog('Item or household not found.'), findsOneWidget);
    });
  });

  group('closing', () {
    testWidgets('closes straight away when nothing changed', (tester) async {
      await openDialog(tester, homemade);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(EditItemDialog), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('asks before throwing away changes and can keep editing', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, 'Serek ziarnisty');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(EditItemDialog), findsOneWidget);
      expect(find.text('Serek ziarnisty'), findsOneWidget);
    });

    testWidgets('a changed date also counts as a change', (tester) async {
      await openDialog(tester, homemade);
      await pickNewDate(tester);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('discarding closes the dialog without saving', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, 'Serek ziarnisty');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(EditItemDialog), findsNothing);
      expect(repository.updatedProducts, isEmpty);
      expect(repository.updatedItems, isEmpty);
    });

    testWidgets('the system back button also asks first', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, 'Serek ziarnisty');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('looking up a product by name', () {
    testWidgets('a known product fills in its category', (tester) async {
      repository.products = [aProduct(id: 9, name: 'Jogurt naturalny', category: readyMeals)];
      await openDialog(tester, homemade);

      await typeName(tester, 'Jogurt naturalny');
      await leaveNameField(tester);

      expect(repository.searchQueries, ['Jogurt naturalny']);
      expect(find.text('Ready meals & soups'), findsOneWidget);
      expect(find.text('Dairy'), findsNothing);
    });

    testWidgets('a purchased product with an empty brand takes the brand of the match', (
      tester,
    ) async {
      repository.products = [aProduct(id: 9, name: 'Jogurt naturalny', brand: 'Bakoma')];
      await openDialog(tester, purchased);
      await tester.enterText(field('Brand'), '');
      await typeName(tester, 'Jogurt naturalny');

      await leaveNameField(tester);

      expect(find.text('Bakoma'), findsOneWidget);
    });

    testWidgets('the original name is not looked up again', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, 'serek WIEJSKI');
      await leaveNameField(tester);

      expect(repository.searchQueries, isEmpty);
    });

    testWidgets('a failed lookup is ignored', (tester) async {
      repository.searchError = connectionError();
      await openDialog(tester, homemade);

      await typeName(tester, 'Jogurt naturalny');
      await leaveNameField(tester);

      expect(find.byType(EditItemDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
