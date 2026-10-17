import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerTitle;

  const AppAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 20,
        ),
      ),
      leading: onBack == null
          ? null
          : IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: onBack,
      ),
      actions: trailing == null ? null : [trailing!],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}