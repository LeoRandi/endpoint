import 'package:flutter/material.dart';

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

  static Color soften(Color accent, {double amount = 0.32}) {
    return Color.lerp(Colors.white, accent, amount) ?? Colors.white;
  }

  static Color tint(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color blend(Color base, Color accent, double amount) {
    return Color.lerp(base, accent, amount) ?? base;
  }
}
