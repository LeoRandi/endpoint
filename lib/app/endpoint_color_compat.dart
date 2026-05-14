import 'package:flutter/material.dart';

extension EndpointColorCompat on Color {
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
  }) {
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
