import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PantryItemsScreen extends StatelessWidget {
  const PantryItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Pantry items',
        onBack: () => context.go('/households'),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: const Center(
        child: Text(
          'Pantry items - coming soon',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
