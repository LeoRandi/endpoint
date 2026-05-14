import 'endpoint_palette.dart';
import 'package:flutter/material.dart';

abstract final class EndpointGradients {
  static const menu = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF040A07),
      Color(0xFF0A1710),
      Color(0xFF020403),
    ],
  );

  static const path = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF050A08),
      Color(0xFF09120D),
      Color(0xFF020403),
    ],
  );

  static const battle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF090406),
      Color(0xFF050907),
      Color(0xFF020403),
    ],
  );

  static const camp = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF061008),
      Color(0xFF0B1510),
      Color(0xFF020403),
    ],
  );

  static Gradient event(Color accent) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        EndpointPalette.blend(const Color(0xFF050907), accent, 0.12),
        EndpointPalette.panelBackground,
        const Color(0xFF020403),
      ],
    );
  }

  static Gradient shop(Color accent) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        EndpointPalette.blend(const Color(0xFF090705), accent, 0.12),
        EndpointPalette.blend(const Color(0xFF11120A), accent, 0.08),
        const Color(0xFF030403),
      ],
    );
  }
}
