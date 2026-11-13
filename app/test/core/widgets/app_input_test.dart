import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/core/widgets/app_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late TextEditingController textController;
  late GlobalKey<FormState> formKey;
  late List<String> changes;

  setUp(() {
    textController = TextEditingController();
    formKey = GlobalKey<FormState>();
    changes = [];
  });

  tearDown(() => textController.dispose());

  Future<void> showInput(
    WidgetTester tester, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppInput(
              hintText: 'Password',
              icon: Icons.lock_outline,
              isPassword: isPassword,
              controller: textController,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
  }

  bool obscured(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).obscureText;

  testWidgets('shows the hint and the leading icon', (tester) async {
    await showInput(tester);

    expect(find.text('Password'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('typing updates the controller and reports every change', (tester) async {
    await showInput(tester);

    await tester.enterText(find.byType(TextField), 'abc');

    expect(textController.text, 'abc');
    expect(changes, ['abc']);
  });

  testWidgets('passes the keyboard type to the field', (tester) async {
    await showInput(tester, keyboardType: TextInputType.emailAddress);

    expect(
      tester.widget<TextField>(find.byType(TextField)).keyboardType,
      TextInputType.emailAddress,
    );
  });

  group('plain input', () {
    testWidgets('is never obscured and has no visibility button', (tester) async {
      await showInput(tester);

      expect(obscured(tester), isFalse);
      expect(find.byType(IconButton), findsNothing);
    });
  });

  group('password input', () {
    testWidgets('is hidden by default', (tester) async {
      await showInput(tester, isPassword: true);

      expect(obscured(tester), isTrue);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('the eye button shows and hides the text', (tester) async {
      await showInput(tester, isPassword: true);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(obscured(tester), isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(obscured(tester), isTrue);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('toggling the eye keeps the typed text', (tester) async {
      await showInput(tester, isPassword: true);
      await tester.enterText(find.byType(TextField), 'secret');

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(textController.text, 'secret');
    });
  });

  group('validation', () {
    String? required(String? value) => (value == null || value.isEmpty) ? 'Required' : null;

    testWidgets('shows the validator message for invalid input', (tester) async {
      await showInput(tester, validator: required);

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('shows no message for valid input', (tester) async {
      await showInput(tester, validator: required);
      await tester.enterText(find.byType(TextField), 'abc');

      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();

      expect(find.text('Required'), findsNothing);
    });
  });
}
