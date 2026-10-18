import 'package:flutter/material.dart';

class AppHouseholdButton extends StatelessWidget {
  final String householdName;
  final VoidCallback? onPressed;

  const AppHouseholdButton({
    super.key,
    required this.householdName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                householdName,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}