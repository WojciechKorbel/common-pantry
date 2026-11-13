import 'package:common_pantry/features/pantry/presentation/widgets/pinned_action_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  var taps = 0;

  Future<void> showLayout(WidgetTester tester, {int rows = 3}) async {
    taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinnedActionLayout(
            action: ElevatedButton(onPressed: () => taps++, child: const Text('Save')),
            child: Column(
              children: [
                for (var i = 0; i < rows; i++) SizedBox(height: 50, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the content and the action', (tester) async {
    await showLayout(tester);

    expect(find.text('row 0'), findsOneWidget);
    expect(find.text('row 2'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('the action can be tapped', (tester) async {
    await showLayout(tester);

    await tester.tap(find.text('Save'));

    expect(taps, 1);
  });

  testWidgets('the action stretches across the screen inside its padding', (tester) async {
    await showLayout(tester);

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;

    expect(tester.getSize(find.byType(ElevatedButton)).width, screenWidth - 48);
  });

  testWidgets('long content scrolls while the action stays pinned', (tester) async {
    await showLayout(tester, rows: 60);
    final before = tester.getTopLeft(find.byType(ElevatedButton));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.getTopLeft(find.byType(ElevatedButton)), before);

    await tester.tap(find.text('Save'));
    expect(taps, 1);
  });

  testWidgets('the action sits below the content', (tester) async {
    await showLayout(tester);

    expect(
      tester.getTopLeft(find.byType(ElevatedButton)).dy,
      greaterThan(tester.getBottomLeft(find.text('row 2')).dy),
    );
  });
}
