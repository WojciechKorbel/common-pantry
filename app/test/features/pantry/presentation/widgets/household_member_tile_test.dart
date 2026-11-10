import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/household_member_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builders.dart';

void main() {
  final actions = <String>[];

  Future<void> showTile(
    WidgetTester tester, {
    HouseholdMember? member,
    bool canManage = true,
    bool isUpdating = false,
  }) async {
    actions.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HouseholdMemberTile(
            member: member ?? aMember(username: 'anna'),
            canManage: canManage,
            isUpdating: isUpdating,
            onAction: actions.add,
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
  }

  group('content', () {
    testWidgets('shows the username, the first letter and the member role', (tester) async {
      await showTile(tester, member: aMember(username: 'anna'));

      expect(find.text('anna'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows the owner role and badge', (tester) async {
      await showTile(tester, member: aMember(username: 'anna', role: 'owner'));

      expect(find.text('Owner'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    });

    testWidgets('marks the current user with (you)', (tester) async {
      await showTile(tester, member: aMember(username: 'jan', isMe: true));

      expect(find.text('jan (you)'), findsOneWidget);
    });

    testWidgets('falls back to ? when the username is empty', (tester) async {
      await showTile(tester, member: aMember(username: ''));

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('management menu', () {
    testWidgets('is hidden when the viewer cannot manage members', (tester) async {
      await showTile(tester, canManage: false);

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('is hidden for the current user', (tester) async {
      await showTile(tester, member: aMember(isMe: true));

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('offers promote and remove for a regular member', (tester) async {
      await showTile(tester);
      await openMenu(tester);

      expect(find.text('Promote to owner'), findsOneWidget);
      expect(find.text('Remove member'), findsOneWidget);
      expect(find.text('Demote to member'), findsNothing);
    });

    testWidgets('offers demote and remove for an owner', (tester) async {
      await showTile(tester, member: aMember(role: 'owner'));
      await openMenu(tester);

      expect(find.text('Demote to member'), findsOneWidget);
      expect(find.text('Remove member'), findsOneWidget);
      expect(find.text('Promote to owner'), findsNothing);
    });

    testWidgets('reports promote', (tester) async {
      await showTile(tester);
      await openMenu(tester);

      await tester.tap(find.text('Promote to owner'));

      expect(actions, ['promote']);
    });

    testWidgets('reports demote', (tester) async {
      await showTile(tester, member: aMember(role: 'owner'));
      await openMenu(tester);

      await tester.tap(find.text('Demote to member'));

      expect(actions, ['demote']);
    });

    testWidgets('reports remove', (tester) async {
      await showTile(tester);
      await openMenu(tester);

      await tester.tap(find.text('Remove member'));

      expect(actions, ['remove']);
    });

    testWidgets('is disabled while the household is updating', (tester) async {
      await showTile(tester, isUpdating: true);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(tester.widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>)).enabled, isFalse);
      expect(find.text('Remove member'), findsNothing);
    });
  });
}
