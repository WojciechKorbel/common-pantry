import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_manually_dialog.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/homemade_item_form.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/purchased_item_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddManuallyDialog(context, home),
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

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(AddManuallyDialog), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('the system back button closes the dialog when nothing was entered', (tester) async {
    await openDialog(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AddManuallyDialog), findsNothing);
  });
}
