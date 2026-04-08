import '../entities/_exports.dart';
import 'run_completion_type.dart';
import 'run_hour_snapshot.dart';

class RunState {
  final Battler player;
  final RunHourSnapshot currentHour;
  final List<PathNode> visibleNodes;
  final int stageIndex;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;
  final bool isRunComplete;
  final RunCompletionType? completionType;

  const RunState({
    required this.player,
    required this.currentHour,
    required this.visibleNodes,
    required this.stageIndex,
    required this.battleEnemyTurnDelay,
    required this.battleCombatEndDelay,
    this.isRunComplete = false,
    this.completionType,
  });

  RunState copyWith({
    Battler? player,
    RunHourSnapshot? currentHour,
    List<PathNode>? visibleNodes,
    int? stageIndex,
    Duration? battleEnemyTurnDelay,
    Duration? battleCombatEndDelay,
    bool? isRunComplete,
    RunCompletionType? completionType,
  }) {
    return RunState(
      player: player ?? this.player,
      currentHour: currentHour ?? this.currentHour,
      visibleNodes: visibleNodes ?? this.visibleNodes,
      stageIndex: stageIndex ?? this.stageIndex,
      battleEnemyTurnDelay: battleEnemyTurnDelay ?? this.battleEnemyTurnDelay,
      battleCombatEndDelay: battleCombatEndDelay ?? this.battleCombatEndDelay,
      isRunComplete: isRunComplete ?? this.isRunComplete,
      completionType: completionType ?? this.completionType,
    );
  }
}
