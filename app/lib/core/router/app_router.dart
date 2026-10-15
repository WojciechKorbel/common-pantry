import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/features/auth/presentation/forgot_password_screen.dart';
import 'package:common_pantry/features/auth/presentation/login_screen.dart';
import 'package:common_pantry/features/auth/presentation/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // For now I left here a basic placeholder - to be replaced with real routes
      GoRoute(
        path: '/items',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Pantry'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/login');
              },
              tooltip: 'Go back to login page',
            ),
          ),
          body: const Center(
            child: Text('Pantry – coming soon'),
          ),
        ),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          controller: Dependencies.loginController,
        ),
      ),

      GoRoute(
        path: '/sign-up',
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
    ],
  );
});
