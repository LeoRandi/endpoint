import '../../services/battle_drawing_bonus_resolver.dart';

/// Resultado extendido del overlay de dibujo usado para sincronizar Quick Draw.
class BattleDrawOverlayResult {
  final BattleDrawingBonusResolution resolution;
  final bool consumedQuickDraw;
  final bool achievedPerfect;

  const BattleDrawOverlayResult({
    required this.resolution,
    required this.consumedQuickDraw,
    required this.achievedPerfect,
  });
}
