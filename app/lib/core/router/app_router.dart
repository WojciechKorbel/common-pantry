import 'package:common_pantry/features/auth/presentation/login_screen.dart';
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
        builder: (_, __) => const Scaffold(body: Center(child: Text('Pantry – coming soon'))),
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
    ],
  );
});
