import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/household_member_tile.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/household_members_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/builders.dart';

void main() {
  final reported = <({String username, String action})>[];

  final me = aMember(userId: 1, username: 'jan', role: 'owner', isMe: true);
  final anna = aMember(userId: 2, username: 'anna');
  final piotr = aMember(userId: 3, username: 'piotr');

  Future<void> showSection(
    WidgetTester tester, {
    required HouseholdDetails details,
    bool isUpdating = false,
  }) async {
    reported.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HouseholdMembersSection(
              details: details,
              isUpdating: isUpdating,
              onMemberAction: (member, action) =>
                  reported.add((username: member.username, action: action)),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the title and the number of members', (tester) async {
    await showSection(tester, details: aHouseholdDetails(members: [me, anna, piotr]));

    expect(find.text('Members'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows one tile per member', (tester) async {
    await showSection(tester, details: aHouseholdDetails(members: [me, anna, piotr]));

    expect(find.byType(HouseholdMemberTile), findsNWidgets(3));
    expect(find.text('jan (you)'), findsOneWidget);
    expect(find.text('anna'), findsOneWidget);
    expect(find.text('piotr'), findsOneWidget);
  });

  testWidgets('shows no tiles and a zero count for an empty household', (tester) async {
    await showSection(tester, details: aHouseholdDetails());

    expect(find.byType(HouseholdMemberTile), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('owners can manage everyone except themselves', (tester) async {
    await showSection(tester, details: aHouseholdDetails(members: [me, anna, piotr]));

    expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
  });

  testWidgets('regular members cannot manage anyone', (tester) async {
    final self = aMember(userId: 2, username: 'anna', isMe: true);
    await showSection(
      tester,
      details: aHouseholdDetails(role: 'member', members: [aMember(userId: 1, role: 'owner'), self]),
    );

    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('passes the member together with the chosen action', (tester) async {
    await showSection(tester, details: aHouseholdDetails(members: [me, anna, piotr]));

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove member'));

    expect(reported, [(username: 'piotr', action: 'remove')]);
  });

  testWidgets('disables the menus while updating', (tester) async {
    await showSection(
      tester,
      details: aHouseholdDetails(members: [me, anna]),
      isUpdating: true,
    );

    expect(tester.widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>)).enabled, isFalse);
  });
}
