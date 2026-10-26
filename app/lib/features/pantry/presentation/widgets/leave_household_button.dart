import 'package:flutter/material.dart';

class LeaveHouseholdButton extends StatelessWidget {
  const LeaveHouseholdButton({
    super.key,
    required this.isUpdating,
    required this.onPressed,
  });

  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isUpdating ? null : onPressed,
      icon: const Icon(Icons.logout),
      label: const Text('Leave household'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
