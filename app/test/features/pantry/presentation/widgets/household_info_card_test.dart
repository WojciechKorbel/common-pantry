import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/household_info_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/builders.dart';

void main() {
  final savedNames = <String>[];
  var saveResult = true;
  Completer<bool>? pendingSave;

  Future<void> showCard(
    WidgetTester tester, {
    HouseholdDetails? details,
    bool isUpdating = false,
  }) async {
    savedNames.clear();
    saveResult = true;
    pendingSave = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HouseholdInfoCard(
              details: details ?? aHouseholdDetails(),
              isUpdating: isUpdating,
              onSaveName: (name) {
                savedNames.add(name);
                return pendingSave?.future ?? Future.value(saveResult);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> startEditing(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Edit household name'));
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  group('display', () {
    testWidgets('shows the name, the invite code and the owner label', (tester) async {
      await showCard(tester);

      expect(find.text('Akademik'), findsOneWidget);
      expect(find.text('K7Q2MX'), findsOneWidget);
      expect(find.text('Invite code'), findsOneWidget);
      expect(find.text('You are the owner'), findsOneWidget);
    });

    testWidgets('shows the member label for regular members', (tester) async {
      await showCard(tester, details: aHouseholdDetails(role: 'member'));

      expect(find.text('You are a member'), findsOneWidget);
      expect(find.text('You are the owner'), findsNothing);
    });

    testWidgets('shows Unavailable and disables copy when there is no invite code', (tester) async {
      await showCard(tester, details: aHouseholdDetails(inviteCode: ''));

      expect(find.text('Unavailable'), findsOneWidget);
      final copy = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.copy_outlined));
      expect(copy.onPressed, isNull);
    });
  });

  group('editing permissions', () {
    testWidgets('owners see the edit button', (tester) async {
      await showCard(tester);

      expect(find.byTooltip('Edit household name'), findsOneWidget);
    });

    testWidgets('members do not see the edit button', (tester) async {
      await showCard(tester, details: aHouseholdDetails(role: 'member'));

      expect(find.byTooltip('Edit household name'), findsNothing);
    });

    testWidgets('the edit button is disabled while the household is updating', (tester) async {
      await showCard(tester, isUpdating: true);

      final edit = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.edit_outlined));
      expect(edit.onPressed, isNull);
    });
  });

  group('editing the name', () {
    testWidgets('opens a field prefilled with the current name', (tester) async {
      await showCard(tester);

      await startEditing(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Akademik');
      expect(find.text('Household name'), findsOneWidget);
      expect(find.byTooltip('Edit household name'), findsNothing);
    });

    testWidgets('cancel closes the field without saving', (tester) async {
      await showCard(tester);
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), 'Changed');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Akademik'), findsOneWidget);
      expect(savedNames, isEmpty);
    });

    testWidgets('an empty name shows a validation error and does not save', (tester) async {
      await showCard(tester);
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), '   ');

      await tapSave(tester);

      expect(find.text('A household name is required.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(savedNames, isEmpty);
    });

    testWidgets('typing clears the validation error', (tester) async {
      await showCard(tester);
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), '');
      await tapSave(tester);

      await tester.enterText(find.byType(TextField), 'N');
      await tester.pump();

      expect(find.text('A household name is required.'), findsNothing);
    });

    testWidgets('saving an unchanged name just closes the field', (tester) async {
      await showCard(tester);
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), '  Akademik  ');

      await tapSave(tester);

      expect(savedNames, isEmpty);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('saves the trimmed name and closes the field on success', (tester) async {
      await showCard(tester);
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), '  Flat 12  ');

      await tapSave(tester);

      expect(savedNames, ['Flat 12']);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('keeps the field open when saving fails', (tester) async {
      await showCard(tester);
      saveResult = false;
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), 'Flat 12');

      await tapSave(tester);

      expect(savedNames, ['Flat 12']);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Flat 12');
    });

    testWidgets('saves from the keyboard done action', (tester) async {
      await showCard(tester);
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), 'Flat 12');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(savedNames, ['Flat 12']);
    });

    testWidgets('disables the form while saving is in progress', (tester) async {
      await showCard(tester);
      pendingSave = Completer<bool>();
      await startEditing(tester);
      await tester.enterText(find.byType(TextField), 'Flat 12');

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancel')).onPressed, isNull);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      pendingSave!.complete(true);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });
  });

  group('invite code', () {
    testWidgets('copies the code to the clipboard and confirms', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await showCard(tester);

      await tester.tap(find.byTooltip('Copy invite code'));
      await tester.pump();

      expect(copied, ['K7Q2MX']);
      expect(find.text('Invite code copied.'), findsOneWidget);
    });
  });
}
