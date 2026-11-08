import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/presentation/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FakeScannerController implements MobileScannerController {
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = {
      #stop: 'stop',
      #toggleTorch: 'toggleTorch',
      #switchCamera: 'switchCamera',
      #dispose: 'dispose',
    }[invocation.memberName];
    if (name == null) {
      return super.noSuchMethod(invocation);
    }
    calls.add(name);
    return Future<void>.value();
  }
}

BarcodeCapture capture(List<String?> values) =>
    BarcodeCapture(barcodes: [for (final value in values) Barcode(rawValue: value)]);

void main() {
  late FakeScannerController controller;
  late void Function(BarcodeCapture) detect;
  late String? result;
  late bool closed;

  Future<void> openScanner(WidgetTester tester) async {
    controller = FakeScannerController();
    result = null;
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => BarcodeScannerScreen(
                        controller: controller,
                        scannerBuilder: (_, onDetect) {
                          detect = onDetect;
                          return const ColoredBox(key: ValueKey('camera'), color: Colors.grey);
                        },
                      ),
                    ),
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

  group('screen', () {
    testWidgets('shows the camera, the frame hint and the camera buttons', (tester) async {
      await openScanner(tester);

      expect(find.text('Scan barcode'), findsOneWidget);
      expect(find.byKey(const ValueKey('camera')), findsOneWidget);
      expect(find.text('Align barcode inside the frame'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);
    });

    testWidgets('the flash button toggles the torch', (tester) async {
      await openScanner(tester);

      await tester.tap(find.byIcon(Icons.flash_on));

      expect(controller.calls, ['toggleTorch']);
    });

    testWidgets('the flip button switches the camera', (tester) async {
      await openScanner(tester);

      await tester.tap(find.byIcon(Icons.flip_camera_ios));

      expect(controller.calls, ['switchCamera']);
    });
  });

  group('detecting a barcode', () {
    testWidgets('stops the camera and returns the barcode', (tester) async {
      await openScanner(tester);

      detect(capture(['5901234123457']));
      await tester.pumpAndSettle();

      expect(result, '5901234123457');
      expect(closed, isTrue);
      expect(find.byType(BarcodeScannerScreen), findsNothing);
      expect(controller.calls, contains('stop'));
    });

    testWidgets('trims the barcode', (tester) async {
      await openScanner(tester);

      detect(capture(['  5901234123457 ']));
      await tester.pumpAndSettle();

      expect(result, '5901234123457');
    });

    testWidgets('returns only the first of several barcodes', (tester) async {
      await openScanner(tester);

      detect(capture(['111', '222']));
      await tester.pumpAndSettle();

      expect(result, '111');
    });

    testWidgets('a second detection is ignored', (tester) async {
      await openScanner(tester);

      detect(capture(['111']));
      detect(capture(['222']));
      await tester.pumpAndSettle();

      expect(result, '111');
      expect(controller.calls.where((call) => call == 'stop'), hasLength(1));
    });

    for (final (description, values) in [
      ('no barcodes', <String?>[]),
      ('a barcode without a value', <String?>[null]),
      ('a blank barcode', <String?>['   ']),
    ]) {
      testWidgets('$description keeps scanning', (tester) async {
        await openScanner(tester);

        detect(capture(values));
        await tester.pumpAndSettle();

        expect(find.byType(BarcodeScannerScreen), findsOneWidget);
        expect(closed, isFalse);
        expect(controller.calls, isEmpty);
      });
    }

    testWidgets('a valid barcode still works after an empty one', (tester) async {
      await openScanner(tester);

      detect(capture(['   ']));
      detect(capture(['222']));
      await tester.pumpAndSettle();

      expect(result, '222');
    });
  });

  group('leaving', () {
    testWidgets('the back button closes the screen without a result', (tester) async {
      await openScanner(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });

    testWidgets('releases the camera when the screen closes', (tester) async {
      await openScanner(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(controller.calls, contains('dispose'));
    });
  });
}
