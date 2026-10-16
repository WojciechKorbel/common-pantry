import 'package:common_pantry/core/router/app_router.dart';
import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Shared Pantry',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
