import '_exports.dart';
import 'package:flutter/material.dart';

abstract final class EndpointTheme {
  static ThemeData build() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: EndpointPalette.primaryAccent,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: EndpointPalette.scaffoldBackground,
      useMaterial3: true,
    );
  }
}
