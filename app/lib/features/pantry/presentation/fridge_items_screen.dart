import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FridgeItemsScreen extends StatelessWidget {
  const FridgeItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Fridge items',
        onBack: () => context.pop(),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: const Center(
        child: Text(
          'Fridge items - coming soon',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}