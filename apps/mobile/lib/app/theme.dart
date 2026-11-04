// Material theme from the shared tokens (S7 FR-002). Components draw their own look; this sets the
// page, text and focus defaults so stock widgets (sheets, snack bars, progress) match.
import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

ThemeData velioTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: VelioColors.forest,
    primary: VelioColors.forest,
    onPrimary: VelioColors.lime,
    secondary: VelioColors.lime,
    onSecondary: VelioColors.forest,
    error: VelioColors.danger,
    surface: VelioColors.surface,
    onSurface: VelioColors.ink,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: VelioColors.cream,
    fontFamily: VelioFonts.body,
    textTheme: const TextTheme(
      displayLarge: VelioText.display,
      headlineMedium: VelioText.title,
      titleLarge: VelioText.heading,
      titleMedium: VelioText.subheading,
      bodyLarge: VelioText.body,
      bodyMedium: VelioText.body,
      bodySmall: VelioText.caption,
      labelLarge: VelioText.button,
    ).apply(bodyColor: VelioColors.ink, displayColor: VelioColors.ink),
    iconTheme: const IconThemeData(color: VelioColors.forest),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: VelioColors.forest),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: VelioColors.forest),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: VelioColors.ink,
      contentTextStyle: VelioText.body.copyWith(color: VelioColors.cream),
      behavior: SnackBarBehavior.floating,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
