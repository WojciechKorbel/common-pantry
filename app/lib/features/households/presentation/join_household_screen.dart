import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinHouseholdScreen extends StatelessWidget {
  const JoinHouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Join household',
        onBack: () => context.pop(),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: const Center(
        child: Text(
          'Join household',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}