import 'package:flutter/material.dart';

/// Shared color tokens for the whole Death at Sunrise interface.
///
/// Keeping these colors in one app-level palette lets pages, widgets, and
/// overlays share the same visual language without depending on each other.
abstract final class EndpointPalette {
  static const primaryAccent = Color(0xFF5AF78E);
  static const dangerAccent = Color(0xFFFF6B6B);
  static const warningAccent = Color(0xFFF3D35C);
  static const patternAccent = Color(0xFFFF8A1F);
  static const infoAccent = Color(0xFF59B7FF);
  static const shopAccent = Color(0xFFDBB95A);
  static const rewardAccent = Color(0xFFEBCB5A);
  static const neutralAccent = Color(0xFF9EA7B3);
  static const scaffoldBackground = Color(0xFF030807);
  static const panelBackground = Color(0xFF07120D);
  static const panelBackgroundSoft = Color(0xCC07120D);
  static const panelBackgroundStrong = Color(0xD907120D);
  static const panelBackgroundOpaque = Color(0xF107120D);
  static const panelBackgroundGold = Color(0xF017130B);
  static const panelBackgroundBattle = Color(0xCC05100B);
  static const panelBackgroundBattleOpaque = Color(0xF0090F0C);
  static const panelBackgroundMuted = Color(0x8807120D);
  static const menuButtonBackground = Color(0xFF0D2016);
  static const closeButtonBackground = Color(0xFF102519);
  static const controlBackground = Color(0x66030807);
  static const accentBorderSoft = Color(0x335AF78E);
  static const softForeground = Color(0xFFE6FFF0);
  static const softForegroundWarm = Color(0xFFFFF4C7);
  static const overlayScrimSoft = Color(0x1F000000);
  static const overlayScrim = Color(0x9E000000);
  static const overlayScrimStrong = Color(0xBD000000);

  /// Returns a readable foreground tint for [accent].
  ///
  /// Most combat and route surfaces are very dark, so this blends the accent
  /// toward white instead of using the raw saturated color as body text.
  static Color soften(Color accent, {double amount = 0.32}) {
    return Color.lerp(Colors.white, accent, amount.clamp(0.0, 1.0)) ??
        Colors.white;
  }

  /// Applies [opacity] to [color] through the project color compatibility API.
  ///
  /// This keeps callers away from deprecated opacity helpers while preserving
  /// the compact `EndpointPalette.tint(color, value)` call sites.
  static Color tint(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// Blends [base] toward [accent] by [amount].
  ///
  /// UI surfaces use this to derive accented panels while keeping their
  /// underlying value close to the shared app palette.
  static Color blend(Color base, Color accent, double amount) {
    return Color.lerp(base, accent, amount.clamp(0.0, 1.0)) ?? base;
  }
}
