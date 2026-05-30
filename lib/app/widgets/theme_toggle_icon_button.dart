import 'package:e_waste/app/theme_controller.dart';
import 'package:flutter/material.dart';

class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        final bool isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
          onPressed: ThemeController.instance.toggleTheme,
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        );
      },
    );
  }
}
