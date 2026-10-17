import 'package:flutter/material.dart';

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.inviteCode,
    required this.onCopy,
  });

  final String inviteCode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SelectableText(
              inviteCode,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: onCopy,
              tooltip: 'Copy invite code',
              icon: const Icon(Icons.copy),
            ),
          ),
        ],
      ),
    );
  }
}
