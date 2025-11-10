import 'package:flutter/material.dart';

/// Top navigation bar that displays the current function name based on selected bottom tab
class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onLogout;

  const TopNavBar({super.key, required this.title, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: onLogout, tooltip: 'Đăng xuất'),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
