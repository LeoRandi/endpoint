import '_exports.dart';
import 'package:flutter/material.dart';

abstract final class EndpointTheme {
  static ThemeData build() {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: EndpointPalette.primaryAccent,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: EndpointPalette.scaffoldBackground,
      textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'Pixeboy',
            bodyColor: EndpointPalette.softForeground,
            displayColor: EndpointPalette.softForeground,
          ),
      iconTheme: const IconThemeData(
        color: EndpointPalette.softForeground,
      ),
      splashFactory: InkSparkle.splashFactory,
      useMaterial3: true,
    );
  }
}
