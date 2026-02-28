import 'package:flutter/material.dart';

/// Reusable app bar with blur-style background.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
