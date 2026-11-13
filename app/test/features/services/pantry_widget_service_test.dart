import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/services/pantry_widget_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/builders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 8, 15, 30);
  DateTime inDays(int days) => DateTime(2026, 11, 8 + days);

  PantryGroup product(String name, {int count = 1, int days = 30, String? status}) => aPantryGroup(
    name: name,
    itemCount: count,
    earliestExpiry: inDays(days),
    expiryStatus: status,
  );

  PantryWidgetSummary summary(List<PantryGroup> groups) =>
      PantryWidgetService.buildSummary(groups, now);

  group('empty pantry', () {
    test('invites to add items', () {
      final result = summary([]);

      expect(result.statusType, 'empty');
      expect(result.countHeader, 'No items yet');
      expect(result.bodyMessage, 'Your pantry is empty.\nAdd items to track expiration.');
      expect(result.footerInfo, 'Common Pantry');
    });

    test('products without any items count as empty', () {
      final result = summary([product('Mleko', count: 0, status: 'expired')]);

      expect(result.statusType, 'empty');
      expect(result.footerInfo, 'Common Pantry');
    });
  });

  group('everything fresh', () {
    test('says so and counts all items', () {
      final result = summary([
        product('Ryż', count: 2, status: 'fresh'),
        product('Makaron', count: 1, status: 'fresh'),
      ]);

      expect(result.statusType, 'fresh');
      expect(result.countHeader, 'All fresh!');
      expect(result.bodyMessage, 'Everything is fresh and good to go!');
      expect(result.footerInfo, '3 total items in pantry');
    });
  });

  group('expired products', () {
    test('count items, not products', () {
      final result = summary([product('Jogurt', count: 2, days: -1, status: 'expired')]);

      expect(result.statusType, 'expired');
      expect(result.countHeader, '2 expired');
      expect(result.bodyMessage, '• Jogurt (2x) · yesterday');
      expect(result.footerInfo, '2 total items in pantry');
    });

    test('older ones show how many days ago', () {
      final result = summary([product('Jogurt', days: -3, status: 'expired')]);

      expect(result.bodyMessage, '• Jogurt (1x) · 3 d ago');
    });
  });

  group('products expiring soon', () {
    test('count items and use the soon status', () {
      final result = summary([product('Mleko', count: 3, days: 1, status: 'soon')]);

      expect(result.statusType, 'soon');
      expect(result.countHeader, '3 expiring soon');
      expect(result.bodyMessage, '• Mleko (3x) · tomorrow');
    });

    test('are labelled today, tomorrow or in N days', () {
      final result = summary([
        product('A', days: 0, status: 'soon'),
        product('B', days: 1, status: 'soon'),
        product('C', days: 4, status: 'soon'),
      ]);

      expect(result.bodyMessage, '• A (1x) · today\n• B (1x) · tomorrow\n• C (1x) · in 4 d');
    });
  });

  group('expired and soon together', () {
    test('show both counts and the worst status', () {
      final result = summary([
        product('Mleko', count: 3, days: 1, status: 'soon'),
        product('Jogurt', days: -1, status: 'expired'),
      ]);

      expect(result.statusType, 'expired');
      expect(result.countHeader, '1 expired, 3 soon');
    });

    test('list expired products before the ones expiring soon', () {
      final result = summary([
        product('Mleko', days: 1, status: 'soon'),
        product('Jogurt', days: -1, status: 'expired'),
      ]);

      expect(result.bodyMessage, '• Jogurt (1x) · yesterday\n• Mleko (1x) · tomorrow');
    });

    test('fresh products are counted in the footer but not listed', () {
      final result = summary([
        product('Jogurt', days: -1, status: 'expired'),
        product('Ryż', count: 4, status: 'fresh'),
      ]);

      expect(result.bodyMessage, '• Jogurt (1x) · yesterday');
      expect(result.footerInfo, '5 total items in pantry');
    });
  });

  group('long lists', () {
    List<PantryGroup> soonProducts(int count) => [
      for (var i = 1; i <= count; i++) product('P$i', days: 1, status: 'soon'),
    ];

    test('show five products and how many more there are', () {
      final lines = summary(soonProducts(7)).bodyMessage.split('\n');

      expect(lines, hasLength(6));
      expect(lines.first, '• P1 (1x) · tomorrow');
      expect(lines[4], '• P5 (1x) · tomorrow');
      expect(lines.last, '… and 2 more');
    });

    test('exactly five products have no "more" line', () {
      final lines = summary(soonProducts(5)).bodyMessage.split('\n');

      expect(lines, hasLength(5));
      expect(lines.last, '• P5 (1x) · tomorrow');
    });
  });

  group('status from the date', () {
    test('a product without a status is judged by its expiry date', () {
      final result = summary([
        product('Stare', days: -5),
        product('Świeże', days: 60),
      ]);

      expect(result.statusType, 'expired');
      expect(result.countHeader, '1 expired');
      expect(result.bodyMessage, '• Stare (1x) · 5 d ago');
    });

    test('only fresh dates mean all fresh', () {
      final result = summary([product('Ryż', days: 60)]);

      expect(result.statusType, 'fresh');
    });
  });

  group('sending data to the home screen widget', () {
    const channel = MethodChannel('home_widget');
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          calls.add(call);
          return true;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    Map<String, Object?> saved() => {
      for (final call in calls.where((call) => call.method == 'saveWidgetData'))
        (call.arguments as Map)['id'] as String: (call.arguments as Map)['data'],
    };

    test(
      'updateWidget saves the household name and the summary, then refreshes the widget',
      () async {
        await PantryWidgetService.updateWidget(householdName: 'Akademik', groups: []);

        expect(saved(), {
          'household_name': 'Akademik',
          'count_header': 'No items yet',
          'status_type': 'empty',
          'body_message': 'Your pantry is empty.\nAdd items to track expiration.',
          'footer_info': 'Common Pantry',
        });
        expect(calls.map((call) => call.method), contains('updateWidget'));
      },
    );

    test('updateThemeMode saves the mode name and refreshes the widget', () async {
      await PantryWidgetService.updateThemeMode(ThemeMode.dark);

      expect(saved(), {'theme_mode': 'dark'});
      expect(calls.map((call) => call.method), contains('updateWidget'));
    });
  });
}
