import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double screenWidth;

  const CustomAppBar({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: colorScheme.onSurface,
          size: screenWidth * 0.06,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'PleniMind',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.help_outline,
            color: colorScheme.onSurface,
            size: screenWidth * 0.06,
          ),
          onPressed: () {
            // Implementar ação de ajuda
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
