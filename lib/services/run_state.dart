import '_imports.dart';

class RunState {
  final Battler player;
  final List<PathNode> availableNodes;
  final List<PathNode> visibleNodes;
  final int nodeCount;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;

  const RunState({
    required this.player,
    required this.availableNodes,
    required this.visibleNodes,
    required this.nodeCount,
    required this.battleEnemyTurnDelay,
    required this.battleCombatEndDelay,
  });

  RunState copyWith({
    Battler? player,
    List<PathNode>? availableNodes,
    List<PathNode>? visibleNodes,
    int? nodeCount,
    Duration? battleEnemyTurnDelay,
    Duration? battleCombatEndDelay,
  }) {
    return RunState(
      player: player ?? this.player,
      availableNodes: availableNodes ?? this.availableNodes,
      visibleNodes: visibleNodes ?? this.visibleNodes,
      nodeCount: nodeCount ?? this.nodeCount,
      battleEnemyTurnDelay: battleEnemyTurnDelay ?? this.battleEnemyTurnDelay,
      battleCombatEndDelay: battleCombatEndDelay ?? this.battleCombatEndDelay,
    );
  }
}
