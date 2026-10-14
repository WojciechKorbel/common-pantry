import 'package:flutter/material.dart';

class AppTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AlignmentGeometry alignment;
  final TextStyle? style;

  const AppTextLink({
    super.key,
    required this.text,
    required this.onPressed,
    this.alignment = Alignment.centerRight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: style,
        ),
      ),
    );
  }
}
