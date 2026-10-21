import 'package:flutter/material.dart';

/// Scrollable [child] with an [action] pinned to the bottom.
class PinnedActionLayout extends StatelessWidget {
  const PinnedActionLayout({
    super.key,
    required this.child,
    required this.action,
  });

  final Widget child;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: child,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.outline)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: SizedBox(width: double.infinity, child: action),
            ),
          ),
        ),
      ],
    );
  }
}
