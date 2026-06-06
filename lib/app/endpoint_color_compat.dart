// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Compatibility helpers for color APIs used across Flutter SDK versions.
extension EndpointColorCompat on Color {
  /// Returns this color with normalized channel overrides.
  ///
  /// Newer Flutter SDKs expose `Color.withValues`; this project targets a
  /// broad SDK range, so the app layer provides the same call shape for widgets
  /// that already reason in 0.0-1.0 channel values.
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    // Converts a normalized channel value into an ARGB byte.
    int toChannel(double value) {
      return (value.clamp(0.0, 1.0) * 255).round();
    }

    return Color.fromARGB(
      toChannel(alpha ?? opacity),
      toChannel(red ?? (this.red / 255)),
      toChannel(green ?? (this.green / 255)),
      toChannel(blue ?? (this.blue / 255)),
    );
  }
}
