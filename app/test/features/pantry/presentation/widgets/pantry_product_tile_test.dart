import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group_item.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/pantry_product_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';

void main() {
  // The tile builds its labels from the real clock, so test dates are relative to today.
  final now = DateTime.now();
  DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);
  String formatted(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  const colors = ExpiryColors.light;

  late List<PantryGroupItem> edited;
  late List<(PantryGroupItem, String)> closed;
  late List<PantryGroupItem> deleteRequests;

  setUp(() {
    edited = [];
    closed = [];
    deleteRequests = [];
  });

  Future<void> showTile(
    WidgetTester tester,
    PantryGroup product, {
    bool withCallbacks = true,
    bool allowDelete = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PantryProductTile(
              product: product,
              onItemAction: withCallbacks ? edited.add : null,
              onCloseItem: withCallbacks ? (item, status) => closed.add((item, status)) : null,
              onDeleteItem: withCallbacks && allowDelete
                  ? (item) async {
                      deleteRequests.add(item);
                      return false;
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> expand(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Color markerColor(WidgetTester tester) => tester
      .widget<Container>(find.byWidgetPredicate((w) => w is Container && w.color != null))
      .color!;

  group('expiry label', () {
    testWidgets('today', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(0)));

      expect(find.text('Expires today'), findsOneWidget);
    });

    testWidgets('in two days', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(2)));

      expect(find.text('Expires in 2 days'), findsOneWidget);
    });

    testWidgets('several days ago', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(-3)));

      expect(find.text('Expired 3 days ago'), findsOneWidget);
    });

    testWidgets('the label disappears when the tile is expanded', (tester) async {
      await showTile(
        tester,
        aPantryGroup(
          name: 'Mleko',
          earliestExpiry: inDays(1),
          items: [aPantryGroupItem(expiryDate: inDays(1))],
        ),
      );
      expect(find.text('Expires tomorrow'), findsOneWidget);

      await expand(tester, 'Mleko');

      expect(find.text('Expires tomorrow'), findsNothing);
    });
  });

  group('status marker', () {
    testWidgets('the status from the server wins over the date', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(30), expiryStatus: 'expired'));

      expect(markerColor(tester), colors.expired);
    });

    testWidgets('the status from the server is case-insensitive', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(30), expiryStatus: 'SOON'));

      expect(markerColor(tester), colors.soon);
    });

    testWidgets('without a status a past date is expired', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(-5)));

      expect(markerColor(tester), colors.expired);
    });

    testWidgets('without a status a distant date is fresh', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(60)));

      expect(markerColor(tester), colors.fresh);
    });

    testWidgets('an unknown status falls back to the date', (tester) async {
      await showTile(tester, aPantryGroup(earliestExpiry: inDays(-5), expiryStatus: 'weird'));

      expect(markerColor(tester), colors.expired);
    });
  });

  group('image', () {
    testWidgets('a product without an image shows the placeholder icon', (tester) async {
      await showTile(tester, aPantryGroup());

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.fastfood), findsOneWidget);
    });

    testWidgets('an empty image address shows the placeholder icon', (tester) async {
      await showTile(tester, _withImage(''));

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.fastfood), findsOneWidget);
    });

    testWidgets('an image address loads an image', (tester) async {
      await showTile(tester, _withImage('https://example.com/serek.png'));
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('package rows', () {
    testWidgets('are sorted by expiry date', (tester) async {
      await showTile(
        tester,
        aPantryGroup(
          name: 'Serek',
          itemCount: 2,
          items: [
            aPantryGroupItem(id: 1, expiryDate: inDays(9)),
            aPantryGroupItem(id: 2, expiryDate: inDays(5)),
          ],
        ),
      );
      await expand(tester, 'Serek');

      final earlier = tester.getTopLeft(find.text(formatted(inDays(5)))).dy;
      final later = tester.getTopLeft(find.text(formatted(inDays(9)))).dy;
      expect(earlier, lessThan(later));
    });

    testWidgets('the edit button reports its package', (tester) async {
      final item = aPantryGroupItem(id: 7, expiryDate: inDays(5));
      await showTile(tester, aPantryGroup(name: 'Serek', items: [item]));
      await expand(tester, 'Serek');

      await tester.tap(find.byTooltip('Edit item'));

      expect(edited, [item]);
    });

    testWidgets('the eaten and wasted buttons report their package and status', (tester) async {
      final item = aPantryGroupItem(id: 7, expiryDate: inDays(5));
      await showTile(tester, aPantryGroup(name: 'Serek', items: [item]));
      await expand(tester, 'Serek');

      await tester.tap(find.byTooltip('Mark as eaten'));
      await tester.tap(find.byTooltip('Mark as wasted'));

      expect(closed, [(item, 'eaten'), (item, 'wasted')]);
    });

    testWidgets('without callbacks the buttons are disabled', (tester) async {
      await showTile(
        tester,
        aPantryGroup(
          name: 'Serek',
          items: [aPantryGroupItem(expiryDate: inDays(5))],
        ),
        withCallbacks: false,
      );
      await expand(tester, 'Serek');

      for (final icon in [Icons.edit_outlined, Icons.restaurant_outlined, Icons.cancel_outlined]) {
        expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon)).onPressed, isNull);
      }
    });

    testWidgets('rows can be swiped away only when deleting is allowed', (tester) async {
      final product = aPantryGroup(
        name: 'Serek',
        itemCount: 2,
        items: [
          aPantryGroupItem(id: 1, expiryDate: inDays(5)),
          aPantryGroupItem(id: 2, expiryDate: inDays(9)),
        ],
      );

      await showTile(tester, product, allowDelete: false);
      await expand(tester, 'Serek');
      expect(find.byType(Dismissible), findsNothing);

      await showTile(tester, product);
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsNWidgets(2));
    });

    testWidgets('a refused delete keeps the row', (tester) async {
      final item = aPantryGroupItem(id: 7, expiryDate: inDays(5));
      await showTile(tester, aPantryGroup(name: 'Serek', items: [item]));
      await expand(tester, 'Serek');

      await tester.drag(find.byKey(const ValueKey('pantry_item_7')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(deleteRequests, [item]);
      expect(find.text(formatted(inDays(5))), findsOneWidget);
    });
  });
}

PantryGroup _withImage(String imageUrl) => PantryGroup(
  id: 1,
  name: 'Serek wiejski',
  brand: null,
  imageUrl: imageUrl,
  packageSize: '',
  category: null,
  itemCount: 1,
  earliestExpiry: DateTime.now().add(const Duration(days: 30)),
  expiryStatus: 'fresh',
  items: const [],
);
