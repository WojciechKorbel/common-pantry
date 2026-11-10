import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/edit_product_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_households_repository.dart';
import '../../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;
  late HouseholdController households;
  late PantryController controller;

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
    earliestExpiry: DateTime(2026, 11, 20),
    expiryStatus: null,
    items: const [],
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

  Future<void> openDialog(WidgetTester tester, PantryGroup product) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showEditProductDialog(
                  context,
                  product: product,
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

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(field('Name'), text);
    await tester.pump();
  }

  Future<void> leaveNameField(WidgetTester tester) async {
    // Tapping outside the name field takes the focus away and triggers the product lookup.
    await tester.tap(find.text('Edit product'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseCategory(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownMenu<ProductCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  group('opening', () {
    testWidgets('shows the current name and category and nothing to save yet', (tester) async {
      await openDialog(tester, homemade);

      expect(find.text('Edit product'), findsOneWidget);
      expect(find.text('Serek wiejski'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
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

      expect(find.text('Edit product'), findsOneWidget);
      expect(canSave(tester), isFalse);
    });
  });

  group('save button', () {
    testWidgets('is enabled after changing the name', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, 'Serek ziarnisty');

      expect(canSave(tester), isTrue);
    });

    testWidgets('is disabled again when the change is undone', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, 'Serek ziarnisty');
      await typeName(tester, 'Serek wiejski');

      expect(canSave(tester), isFalse);
    });

    testWidgets('is disabled when the name is empty', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, '   ');

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
  });

  group('saving', () {
    testWidgets('sends the new name and closes with a confirmation', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, '  Serek ziarnisty ');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(repository.updatedProducts, [
        (productId: 5, name: 'Serek ziarnisty', brand: null, categoryId: 4),
      ]);
      expect(find.byType(EditProductDialog), findsNothing);
      expect(find.text('Product updated'), findsOneWidget);
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

      expect(find.byType(EditProductDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EditProductDialog),
          matching: find.text('Item or household not found.'),
        ),
        findsOneWidget,
      );
      expect(canSave(tester), isTrue);
    });
  });

  group('closing', () {
    testWidgets('closes straight away when nothing changed', (tester) async {
      await openDialog(tester, homemade);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProductDialog), findsNothing);
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
      expect(find.byType(EditProductDialog), findsOneWidget);
      expect(find.text('Serek ziarnisty'), findsOneWidget);
    });

    testWidgets('discarding closes the dialog without saving', (tester) async {
      await openDialog(tester, homemade);
      await typeName(tester, 'Serek ziarnisty');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProductDialog), findsNothing);
      expect(repository.updatedProducts, isEmpty);
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

    testWidgets('an empty name is not looked up', (tester) async {
      await openDialog(tester, homemade);

      await typeName(tester, '');
      await leaveNameField(tester);

      expect(repository.searchQueries, isEmpty);
    });

    testWidgets('a failed lookup is ignored', (tester) async {
      repository.searchError = connectionError();
      await openDialog(tester, homemade);

      await typeName(tester, 'Jogurt naturalny');
      await leaveNameField(tester);

      expect(find.byType(EditProductDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
