import 'package:flutter/material.dart';

class AppColors {
  // Theme Color Palette (Light Mode only as requested)
  static const Color primary = Color(0xFFA0AAB5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1AB58F);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color primaryButton = Color(0xFF4A8B5F);
  static const Color selectedChip = Color(0xFF4A8B5F);

  static const Color secondary = Color(0xFFAAD4A5);
  static const Color onSecondary = Color(0xFF000000);
  static const Color secondaryContainer = Color(0xFF1AA596);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFFC4E8D8);
  static const Color onAccent = Color(0xFF000000);
  static const Color accentContainer = Color(
    0x1AE8DCC4,
  ); // #E8DCC41A -> 1A alpha at the start for Flutter Color
  static const Color onAccentContainer = Color(0xFF4A443F);

  static const Color background = Color(0xFFF2FAF6);
  static const Color onBackground = Color(0xFF3F4A43);
  static const Color secondaryBackground = Color(0xFFE1F2E9);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF3F4A43);
  static const Color surfaceVariant = Color(0xFFEEF9F3);
  static const Color onSurfaceVariant = Color(0xFF000000);

  static const Color primaryText = Color(0xFF3F4A43);
  static const Color secondaryText = Color(0xFF000000);
  static const Color hint = Color(0xFF000000);
  static const Color outline = Color(0xFFCDE0D5);
  static const Color divider = Color(0xFFDEEDE4);

  static const Color success = Color(0xFF8FA382);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFD9B884);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFC98585);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF89A7B1);

  // Legacy/Compatibility Colors
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF3F4A43);
  static const Color textSecondary = Color(0xFF000000);
  static const Color border = Color(0xFFCDE0D5);
  static const Color progressBackground = Color(0xFFEEF9F3);
  static const Color progressValue = Color(0xFF1AB58F);

  // Custom definitions to prevent build failures in other code referencing them
  static const Color surfaceContainer = Color(0xFFEEF9F3);
  static const Color surfaceContainerHigh = Color(0xFFE1F2E9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFCDE0D5);
  static const Color errorContainer = Color(0xFFC98585);
  static const Color onErrorContainer = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFFC4E8D8);
  static const Color tertiaryContainer = Color(0x1AE8DCC4);
  static const Color onTertiary = Color(0xFF000000);
}
