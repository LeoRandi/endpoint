import 'package:flutter/material.dart';

import 'endpoint_palette.dart';

/// Builds the global Flutter theme from the Endpoint design tokens.
///
/// Feature folders should consume this theme and the palette tokens instead of
/// defining unrelated app-wide Material defaults.
abstract final class EndpointTheme {
  /// Creates the dark Material 3 theme used by the app shell.
  ///
  /// The color scheme is seeded from the primary accent, while text and icon
  /// defaults are pinned to the custom foreground color used across route,
  /// battle, shop, and overlay surfaces.
  static ThemeData build() {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: EndpointPalette.primaryAccent,
      brightness: Brightness.dark,
    );
    final darkTheme = ThemeData.dark();

    return ThemeData(
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: EndpointPalette.scaffoldBackground,
      textTheme: darkTheme.textTheme.apply(
        fontFamily: 'Exo2',
        bodyColor: EndpointPalette.softForeground,
        displayColor: EndpointPalette.softForeground,
      ),
      iconTheme: const IconThemeData(color: EndpointPalette.softForeground),
      splashFactory: InkSparkle.splashFactory,
      useMaterial3: true,
    );
  }
}
