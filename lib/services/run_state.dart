import '_imports.dart';

class RunState {
  final Battler player;
  final RunHourSnapshot currentHour;
  final List<PathNode> visibleNodes;
  final int stageIndex;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;
  final bool isRunComplete;

  const RunState({
    required this.player,
    required this.currentHour,
    required this.visibleNodes,
    required this.stageIndex,
    required this.battleEnemyTurnDelay,
    required this.battleCombatEndDelay,
    this.isRunComplete = false,
  });

  RunState copyWith({
    Battler? player,
    RunHourSnapshot? currentHour,
    List<PathNode>? visibleNodes,
    int? stageIndex,
    Duration? battleEnemyTurnDelay,
    Duration? battleCombatEndDelay,
    bool? isRunComplete,
  }) {
    return RunState(
      player: player ?? this.player,
      currentHour: currentHour ?? this.currentHour,
      visibleNodes: visibleNodes ?? this.visibleNodes,
      stageIndex: stageIndex ?? this.stageIndex,
      battleEnemyTurnDelay: battleEnemyTurnDelay ?? this.battleEnemyTurnDelay,
      battleCombatEndDelay: battleCombatEndDelay ?? this.battleCombatEndDelay,
      isRunComplete: isRunComplete ?? this.isRunComplete,
    );
  }
}
