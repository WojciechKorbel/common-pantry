import 'dart:async';

import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/household_details_controller.dart';
import 'package:common_pantry/features/pantry/presentation/household_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/builders.dart';
import '../../../helpers/fake_pantry_repository.dart';

void main() {
  late FakePantryRepository repository;

  final me = aMember(userId: 1, username: 'jan', role: 'owner', isMe: true);
  final anna = aMember(userId: 2, username: 'Anna');
  final otherOwner = aMember(userId: 3, username: 'Piotr', role: 'owner');

  HouseholdDetails ownerDetails(List<HouseholdMember> members) =>
      aHouseholdDetails(name: 'Flat 12', members: members);

  setUp(() {
    repository = FakePantryRepository();
    repository.householdDetails = ownerDetails([me, anna]);
  });

  Future<void> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = HouseholdDetailsController(repository: repository, householdId: home.id);
    final router = GoRouter(
      initialLocation: '/household-settings',
      routes: [
        GoRoute(
          path: '/household-settings',
          builder: (_, _) => HouseholdSettingsScreen(household: home, controller: controller),
        ),
        GoRoute(
          path: '/households',
          builder: (_, _) => const Scaffold(body: Text('households page')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: Text('settings page')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> chooseMemberAction(WidgetTester tester, String menuLabel) async {
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(menuLabel));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDialog(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  group('loading', () {
    testWidgets('shows a spinner while the details load', (tester) async {
      repository.pendingDetails = Completer<HouseholdDetails>();

      await pumpScreen(tester, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.detailsRequests, 1);
    });

    testWidgets('shows the household once loaded', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Akademik'), findsOneWidget); // app bar title
      expect(find.text('Flat 12'), findsOneWidget); // details name
      expect(find.text('K7Q2MX'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('jan (you)'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Leave household'), findsOneWidget);
    });

    testWidgets('shows an error with a retry button when loading fails', (tester) async {
      repository.detailsError = Exception('boom');

      await pumpScreen(tester);

      expect(find.text('Failed to load household details.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('try again reloads the details', (tester) async {
      repository.detailsError = Exception('boom');
      await pumpScreen(tester);
      repository.detailsError = null;

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.detailsRequests, 2);
      expect(find.text('Flat 12'), findsOneWidget);
      expect(find.text('Failed to load household details.'), findsNothing);
    });

    testWidgets('pull to refresh reloads the details', (tester) async {
      await pumpScreen(tester);

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repository.detailsRequests, 2);
    });
  });

  group('navigation', () {
    testWidgets('the back button goes to the households list', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('households page'), findsOneWidget);
    });

    testWidgets('the profile button opens settings', (tester) async {
      await pumpScreen(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.person_outline),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('settings page'), findsOneWidget);
    });
  });

  group('permissions', () {
    testWidgets('members cannot rename the household or manage members', (tester) async {
      repository.householdDetails = aHouseholdDetails(
        name: 'Flat 12',
        role: 'member',
        members: [
          aMember(userId: 9, username: 'Boss', role: 'owner'),
          aMember(userId: 1, username: 'jan', isMe: true),
        ],
      );

      await pumpScreen(tester);

      expect(find.byTooltip('Edit household name'), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });

  group('renaming', () {
    Future<void> rename(WidgetTester tester, String name) async {
      await tester.tap(find.byTooltip('Edit household name'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), name);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('saves the new name and confirms', (tester) async {
      await pumpScreen(tester);

      await rename(tester, 'New name');

      expect(repository.householdActions, ['rename New name']);
      expect(find.text('Household name updated.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows an error and keeps editing when it fails', (tester) async {
      await pumpScreen(tester);
      repository.householdActionError = Exception('boom');

      await rename(tester, 'New name');

      expect(find.text('Failed to update household name.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('member actions', () {
    testWidgets('promote asks for confirmation, then promotes', (tester) async {
      await pumpScreen(tester);

      await chooseMemberAction(tester, 'Promote to owner');

      expect(find.text('Promote to owner?'), findsOneWidget);
      expect(find.text('Give Anna owner permissions for this household?'), findsOneWidget);

      await confirmDialog(tester, 'Confirm');

      expect(repository.householdActions, ['promote 2']);
      expect(find.text('Anna is now an owner.'), findsOneWidget);
    });

    testWidgets('cancelling the dialog does nothing', (tester) async {
      await pumpScreen(tester);
      await chooseMemberAction(tester, 'Promote to owner');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.householdActions, isEmpty);
      expect(find.text('Promote to owner?'), findsNothing);
    });

    testWidgets('demote asks for confirmation, then demotes', (tester) async {
      repository.householdDetails = ownerDetails([me, otherOwner]);
      await pumpScreen(tester);

      await chooseMemberAction(tester, 'Demote to member');

      expect(find.text('Demote to member?'), findsOneWidget);
      expect(find.text('Remove owner permissions from Piotr?'), findsOneWidget);

      await confirmDialog(tester, 'Confirm');

      expect(repository.householdActions, ['demote 3']);
      expect(find.text('Piotr is now a member.'), findsOneWidget);
    });

    testWidgets('remove asks for confirmation, then removes', (tester) async {
      await pumpScreen(tester);

      await chooseMemberAction(tester, 'Remove member');

      expect(find.text('Remove member?'), findsOneWidget);
      expect(find.text('Remove Anna from this household?'), findsOneWidget);

      await confirmDialog(tester, 'Remove');

      expect(repository.householdActions, ['remove 2']);
      expect(find.text('Anna was removed.'), findsOneWidget);
    });

    testWidgets('shows an error when the action fails', (tester) async {
      await pumpScreen(tester);
      repository.householdActionError = Exception('boom');

      await chooseMemberAction(tester, 'Remove member');
      await confirmDialog(tester, 'Remove');

      expect(find.text('Failed to update household members.'), findsOneWidget);
      expect(repository.householdActions, isEmpty);
    });

    testWidgets('reloads the details after an action', (tester) async {
      await pumpScreen(tester);

      await chooseMemberAction(tester, 'Remove member');
      await confirmDialog(tester, 'Remove');

      expect(repository.detailsRequests, 2);
    });
  });

  group('leaving', () {
    Future<void> tapLeave(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Leave household'));
      await tester.tap(find.text('Leave household'));
      await tester.pumpAndSettle();
    }

    testWidgets('confirms, leaves and returns to the households list', (tester) async {
      repository.householdDetails = ownerDetails([me, otherOwner]);
      await pumpScreen(tester);

      await tapLeave(tester);

      expect(find.text('Leave household?'), findsOneWidget);
      expect(
        find.text('You will lose access to this household and its shared pantry.'),
        findsOneWidget,
      );

      await confirmDialog(tester, 'Leave');

      expect(repository.householdActions, ['leave']);
      expect(find.text('households page'), findsOneWidget);
    });

    testWidgets('cancelling keeps the user in the household', (tester) async {
      repository.householdDetails = ownerDetails([me, otherOwner]);
      await pumpScreen(tester);
      await tapLeave(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.householdActions, isEmpty);
      expect(find.text('households page'), findsNothing);
      expect(find.text('Flat 12'), findsOneWidget);
    });

    testWidgets('the last owner must promote someone first', (tester) async {
      await pumpScreen(tester); // me (owner) + Anna (member)

      await tapLeave(tester);

      expect(
        find.text('Promote another member to owner before leaving this household.'),
        findsOneWidget,
      );
      expect(find.text('Leave household?'), findsNothing);
      expect(repository.householdActions, isEmpty);
    });

    testWidgets('warns that the household is deleted when leaving as the last member', (
      tester,
    ) async {
      repository.householdDetails = ownerDetails([me]);
      await pumpScreen(tester);

      await tapLeave(tester);

      expect(find.textContaining('permanently delete'), findsOneWidget);
    });

    testWidgets('shows an error and stays when leaving fails', (tester) async {
      repository.householdDetails = ownerDetails([me, otherOwner]);
      await pumpScreen(tester);
      repository.householdActionError = Exception('boom');

      await tapLeave(tester);
      await confirmDialog(tester, 'Leave');

      expect(find.text('Failed to leave household.'), findsOneWidget);
      expect(find.text('households page'), findsNothing);
    });
  });
}
