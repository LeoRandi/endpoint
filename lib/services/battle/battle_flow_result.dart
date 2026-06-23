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

  bool get shouldReturnToCaller => type == BattleFlowResultType.victory;
  bool get shouldExitRun => !shouldReturnToCaller;

  @Deprecated('Use shouldReturnToCaller instead.')
  bool get shouldReturnPlayerToCaller => shouldReturnToCaller;

  @Deprecated('Use shouldExitRun instead.')
  bool get shouldPopToRoot => shouldExitRun;
}
