import 'package:flutter/material.dart';

class AppInlineLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onPressed;
  final MainAxisAlignment alignment;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;

  const AppInlineLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onPressed,
    this.alignment = MainAxisAlignment.center,
    this.textStyle,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: textStyle,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            linkText,
            style: linkStyle,
          ),
        ),
      ],
    );
  }
}
