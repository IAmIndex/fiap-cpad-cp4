import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme_controller.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Aparência',
      initialValue: controller.mode,
      icon: Icon(switch (controller.mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      }),
      onSelected: (mode) => unawaited(controller.setMode(mode)),
      itemBuilder: (context) => [
        for (final mode in ThemeMode.values)
          CheckedPopupMenuItem(
            value: mode,
            checked: controller.mode == mode,
            child: Text(switch (mode) {
              ThemeMode.system => 'Seguir sistema',
              ThemeMode.light => 'Modo claro',
              ThemeMode.dark => 'Modo escuro',
            }),
          ),
      ],
    );
  }
}
