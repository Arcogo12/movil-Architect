import 'package:flutter/material.dart';
import 'package:movil_architect/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.light,
        surface: AppColors.dashboardSurface,
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.dashboardSurface,
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dashboardSurface,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.loginFieldFill,
        ),
      ),
    );
  }

  static ThemeData get dark {
    const surface = Color(0xFF121214);
    const card = Color(0xFF1C1C1F);
    const onSurface = Color(0xFFF2F2F7);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
        surface: surface,
        onSurface: onSurface,
      ).copyWith(
        surfaceContainerHighest: const Color(0xFF2A2A2E),
        outlineVariant: const Color(0xFF3A3A3E),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: surface,
      cardColor: card,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      dividerColor: const Color(0xFF3A3A3E),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF5A5A60)
              : const Color(0xFF3A3A3E),
        ),
      ),
    );
  }
}
