import 'package:flutter/material.dart';

import 'endpoint_palette.dart';

/// Scene-level background gradients shared by the main pages.
///
/// These are intentionally kept in the app layer: pages choose the semantic
/// preset they need, while the concrete color recipe stays centralized.
abstract final class EndpointGradients {
  static const _top = Alignment.topCenter;
  static const _bottom = Alignment.bottomCenter;
  static const _voidFloor = Color(0xFF020403);

  static const menu = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [Color(0xFF040A07), Color(0xFF0A1710), _voidFloor],
  );

  static const path = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [Color(0xFF050A08), Color(0xFF09120D), _voidFloor],
  );

  static const battle = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [Color(0xFF090406), Color(0xFF050907), _voidFloor],
  );

  static const camp = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [Color(0xFF061008), Color(0xFF0B1510), _voidFloor],
  );

  /// Builds the background for story/event pages using the event [accent].
  ///
  /// Event pages can change identity through their accent while remaining tied
  /// to the same dark route-scene atmosphere as the rest of the app.
  static Gradient event(Color accent) {
    return _vertical(
      EndpointPalette.blend(const Color(0xFF050907), accent, 0.12),
      EndpointPalette.panelBackground,
      _voidFloor,
    );
  }

  /// Builds the background for shop pages using the current shop [accent].
  ///
  /// Shops use a warmer middle stop than route events so economy and reward
  /// surfaces feel distinct without introducing a separate page dependency.
  static Gradient shop(Color accent) {
    return _vertical(
      EndpointPalette.blend(const Color(0xFF090705), accent, 0.12),
      EndpointPalette.blend(const Color(0xFF11120A), accent, 0.08),
      const Color(0xFF030403),
    );
  }

  /// Creates a vertical three-stop gradient with the project default direction.
  ///
  /// Dynamic presets call this helper so their only visible difference is the
  /// color recipe, not repeated alignment boilerplate.
  static LinearGradient _vertical(Color start, Color middle, Color end) {
    return LinearGradient(
      begin: _top,
      end: _bottom,
      colors: [start, middle, end],
    );
  }
}
