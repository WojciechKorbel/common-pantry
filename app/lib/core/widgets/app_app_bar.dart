import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerTitle;
  final bool showBackButton;

  const AppAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.centerTitle = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 20,
        ),
      ),
      actions: trailing != null ? [trailing!] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
