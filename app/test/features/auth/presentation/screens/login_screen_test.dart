import 'dart:async';

import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/auth/presentation/controllers/login_controller.dart';
import 'package:common_pantry/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late LoginController controller;

  final usernameField = find.widgetWithText(TextFormField, 'username');
  final passwordField = find.widgetWithText(TextFormField, 'password');
  final loginButton = find.widgetWithText(OutlinedButton, 'Login');

  setUp(() {
    repository = FakeAuthRepository();
    controller = LoginController(repository);
  });

  tearDown(() => controller.dispose());

  /// Shows the login screen in a router whose other pages are placeholders.
  Future<GoRouter> showLoginScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => LoginScreen(controller: controller),
        ),
        for (final path in ['/households', '/forgot-password', '/sign-up', '/verify-account'])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('page $path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    return router;
  }

  Future<void> logIn(WidgetTester tester, {String username = 'user1'}) async {
    await tester.enterText(usernameField, username);
    await tester.enterText(passwordField, 'secret');
    await tester.tap(loginButton);
  }

  testWidgets('shows the sign-in form', (tester) async {
    await showLoginScreen(tester);

    expect(find.text('Sign in'), findsOneWidget);
    expect(usernameField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);
  });

  testWidgets('empty fields show a message without calling the server', (tester) async {
    await showLoginScreen(tester);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter your username and password.'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('correct credentials open the households page', (tester) async {
    await showLoginScreen(tester);

    await logIn(tester, username: ' user1 ');
    await tester.pumpAndSettle();

    expect(repository.calls, ['login user1 secret']);
    expect(find.text('page /households'), findsOneWidget);
  });

  testWidgets('wrong credentials show a message and stay on the screen', (tester) async {
    repository.error = serverError(401);
    await showLoginScreen(tester);

    await logIn(tester);
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('the button is disabled while logging in', (tester) async {
    final pending = Completer<void>();
    repository.pendingLogin = pending;
    await showLoginScreen(tester);

    await logIn(tester);
    await tester.pump();

    expect(find.text('Logging in...'), findsOneWidget);
    await tester.tap(find.text('Logging in...'));
    await tester.pump();
    expect(repository.calls, hasLength(1));

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('page /households'), findsOneWidget);
  });

  testWidgets('links open the other sign-in pages', (tester) async {
    final router = await showLoginScreen(tester);
    final links = [
      ('Forgot password?', '/forgot-password'),
      ('Sign up', '/sign-up'),
      ('Verify account', '/verify-account'),
    ];

    for (final (link, path) in links) {
      await tester.ensureVisible(find.text(link));
      await tester.tap(find.text(link));
      await tester.pumpAndSettle();
      expect(find.text('page $path'), findsOneWidget, reason: link);

      router.pop();
      await tester.pumpAndSettle();
    }
  });
}
