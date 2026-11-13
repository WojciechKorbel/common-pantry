import 'package:common_pantry/features/pantry/presentation/widgets/leave_household_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  var taps = 0;

  Future<void> showButton(WidgetTester tester, {bool isUpdating = false}) async {
    taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LeaveHouseholdButton(isUpdating: isUpdating, onPressed: () => taps++),
        ),
      ),
    );
  }

  testWidgets('shows the label and the logout icon', (tester) async {
    await showButton(tester);

    expect(find.text('Leave household'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    await showButton(tester);

    await tester.tap(find.text('Leave household'));

    expect(taps, 1);
  });

  testWidgets('is disabled while the household is updating', (tester) async {
    await showButton(tester, isUpdating: true);

    await tester.tap(find.text('Leave household'));

    expect(taps, 0);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
  });

  testWidgets('uses the error colour for its text and icon', (tester) async {
    await showButton(tester);

    final error = Theme.of(tester.element(find.byType(LeaveHouseholdButton))).colorScheme.error;
    final style = tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;

    expect(style.foregroundColor!.resolve({}), error);
  });
}
