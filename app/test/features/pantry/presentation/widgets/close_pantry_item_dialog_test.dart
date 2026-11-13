import 'package:common_pantry/features/pantry/presentation/widgets/close_pantry_item_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  CloseItemDialogResult? result;
  var closed = false;

  Future<void> openDialog(
    WidgetTester tester, {
    String status = 'eaten',
    String origin = 'purchased',
  }) async {
    result = null;
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showClosePantryItemDialog(
                    context: context,
                    productName: 'Mleko',
                    expiryDate: DateTime(2026, 11, 5),
                    status: status,
                    origin: origin,
                  );
                  closed = true;
                },
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

  Color confirmColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('Confirm')).style!.color!;

  group('texts', () {
    testWidgets('eaten asks to mark the product as eaten', (tester) async {
      await openDialog(tester, status: 'eaten');

      expect(find.text('Mark as eaten?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to mark "Mleko" expiring on 05.11.2026 as eaten?'),
        findsOneWidget,
      );
      expect(confirmColor(tester), Colors.green.shade700);
    });

    testWidgets('any other status asks to mark the product as wasted', (tester) async {
      await openDialog(tester, status: 'wasted');

      expect(find.text('Mark as wasted?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to mark "Mleko" expiring on 05.11.2026 as wasted?'),
        findsOneWidget,
      );
      expect(confirmColor(tester), Colors.orange.shade800);
    });
  });

  group('shopping list option', () {
    testWidgets('a purchased product offers the checkbox, unchecked by default', (tester) async {
      await openDialog(tester, origin: 'purchased');

      expect(find.text('Add to shopping list'), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
      expect(find.text('Homemade products cannot be added to the shopping list.'), findsNothing);
    });

    testWidgets('a homemade product explains why there is no checkbox', (tester) async {
      await openDialog(tester, origin: 'homemade');

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(
        find.text('Homemade products cannot be added to the shopping list.'),
        findsOneWidget,
      );
    });
  });

  group('result', () {
    testWidgets('confirming without the checkbox does not add to the shopping list', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNotNull);
      expect(result!.addToShoppingList, isFalse);
    });

    testWidgets('confirming with the checkbox ticked adds to the shopping list', (tester) async {
      await openDialog(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result!.addToShoppingList, isTrue);
    });

    testWidgets('the checkbox can be unticked again', (tester) async {
      await openDialog(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result!.addToShoppingList, isFalse);
    });

    testWidgets('confirming a homemade product never adds to the shopping list', (tester) async {
      await openDialog(tester, origin: 'homemade');

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result!.addToShoppingList, isFalse);
    });

    testWidgets('cancel closes the dialog with no result', (tester) async {
      await openDialog(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
      expect(find.byType(ClosePantryItemDialog), findsNothing);
    });
  });
}
