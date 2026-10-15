import 'package:flutter/material.dart';

class AppPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double spacing;

  const AppPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.spacing = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        SizedBox(height: spacing),
      ],
    );
  }
}
