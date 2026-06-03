import '../entities/_exports.dart';
import 'run_completion_type.dart';
import 'run_day_summary.dart';
import 'run_hour_snapshot.dart';
import 'ghost_item_lease.dart';

const _copySentinel = Object();

class RunState {
  final Battler player;
  final RunHourSnapshot currentHour;
  final List<PathNode> visibleNodes;
  final int stageIndex;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;
  final RunDaySummary runSummary;
  final RunDaySummary currentDaySummary;
  final RunDaySummary? pendingDaySummary;
  final List<String> shownShopNodeIds;
  final int shopRarityDayOffset;
  final int eventRarityDayOffset;
  final GhostItemLease? ghostItemLease;
  final bool isRunComplete;
  final RunCompletionType? completionType;

  const RunState({
    required this.player,
    required this.currentHour,
    required this.visibleNodes,
    required this.stageIndex,
    required this.battleEnemyTurnDelay,
    required this.battleCombatEndDelay,
    this.runSummary = const RunDaySummary.empty(),
    this.currentDaySummary = const RunDaySummary.empty(),
    this.pendingDaySummary,
    this.shownShopNodeIds = const <String>[],
    this.shopRarityDayOffset = 0,
    this.eventRarityDayOffset = 0,
    this.ghostItemLease,
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
    RunDaySummary? runSummary,
    RunDaySummary? currentDaySummary,
    Object? pendingDaySummary = _copySentinel,
    List<String>? shownShopNodeIds,
    int? shopRarityDayOffset,
    int? eventRarityDayOffset,
    Object? ghostItemLease = _copySentinel,
    bool? isRunComplete,
    RunCompletionType? completionType,
    bool clearCompletionType = false,
  }) {
    return RunState(
      player: player ?? this.player,
      currentHour: currentHour ?? this.currentHour,
      visibleNodes: visibleNodes ?? this.visibleNodes,
      stageIndex: stageIndex ?? this.stageIndex,
      battleEnemyTurnDelay: battleEnemyTurnDelay ?? this.battleEnemyTurnDelay,
      battleCombatEndDelay: battleCombatEndDelay ?? this.battleCombatEndDelay,
      runSummary: runSummary ?? this.runSummary,
      currentDaySummary: currentDaySummary ?? this.currentDaySummary,
      pendingDaySummary: identical(pendingDaySummary, _copySentinel)
          ? this.pendingDaySummary
          : pendingDaySummary as RunDaySummary?,
      shownShopNodeIds: shownShopNodeIds ?? this.shownShopNodeIds,
      shopRarityDayOffset:
          shopRarityDayOffset ?? this.shopRarityDayOffset,
      eventRarityDayOffset:
          eventRarityDayOffset ?? this.eventRarityDayOffset,
      ghostItemLease: identical(ghostItemLease, _copySentinel)
          ? this.ghostItemLease
          : ghostItemLease as GhostItemLease?,
      isRunComplete: isRunComplete ?? this.isRunComplete,
      completionType:
          clearCompletionType ? null : completionType ?? this.completionType,
    );
  }
}
