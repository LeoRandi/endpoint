import '_imports.dart';

enum BattleFlowResultType {
  victory,
  defeat,
  retreated,
}

class BattleFlowResult {
  final BattleFlowResultType type;
  final Battler player;

  const BattleFlowResult({
    required this.type,
    required this.player,
  });

  bool get shouldReturnPlayerToCaller => type == BattleFlowResultType.victory;
  bool get shouldPopToRoot => !shouldReturnPlayerToCaller;
}
