import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_item_dialog.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/add_manually_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';

void main() {
  Future<void> openChoiceDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddItemDialog(context, home),
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
  });

  testWidgets('"Add manually" opens the manual dialog', (tester) async {
    await openChoiceDialog(tester);

    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();

    expect(find.text('Scan barcode'), findsNothing);
    expect(find.byType(AddManuallyDialog), findsOneWidget);
    expect(find.text('Add manually'), findsOneWidget);
  });
}
