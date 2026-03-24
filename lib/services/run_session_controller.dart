import '_imports.dart';

class RunSessionController extends ChangeNotifier {
  final PathNodeService _pathNodeService;
  RunState _state;
  bool _isResolvingNode = false;

  RunSessionController({
    required Battler player,
    required Duration battleEnemyTurnDelay,
    required Duration battleCombatEndDelay,
    int? randomSeed,
  })  : _pathNodeService = PathNodeService(seed: randomSeed),
        _state = RunState(
          player: player,
          currentHour: const RunHourSnapshot(
            stageIndex: PathNodeService.startStageIndex,
            phase: RunHourPhase.day,
            title: 'HORA 0',
            subtitle: '',
            nodes: [],
          ),
          visibleNodes: const [],
          stageIndex: PathNodeService.startStageIndex,
          battleEnemyTurnDelay: battleEnemyTurnDelay,
          battleCombatEndDelay: battleCombatEndDelay,
        ) {
    refreshNodes();
  }

  RunState get state => _state;
  Battler get player => _state.player;
  List<PathNode> get nodes => _state.visibleNodes;
  RunHourSnapshot get currentHour => _state.currentHour;
  bool get isResolvingNode => _isResolvingNode;
  bool get isRunComplete => _state.isRunComplete;

  bool beginNodeResolution() {
    if (_isResolvingNode) return false;
    _isResolvingNode = true;
    notifyListeners();
    return true;
  }

  void cancelNodeResolution() {
    if (!_isResolvingNode) return;
    _isResolvingNode = false;
    notifyListeners();
  }

  void refreshNodes() {
    final currentHour = _pathNodeService.buildHourSnapshot(
      stageIndex: _state.stageIndex,
    );

    _state = _state.copyWith(
      currentHour: currentHour,
      visibleNodes: List<PathNode>.unmodifiable(currentHour.nodes),
    );
    notifyListeners();
  }

  void completeEncounter(BattleFlowResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeCampVisit(CampSiteVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeEventVisit(PathEventVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeWeaponShopVisit(WeaponShopVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void _completeScene({
    required Battler updatedPlayer,
  }) {
    final hasCompletedRun =
        _state.stageIndex >= PathNodeService.sunriseStageIndex;

    if (hasCompletedRun) {
      _state = _state.copyWith(
        player: updatedPlayer,
        isRunComplete: true,
      );
      _isResolvingNode = false;
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      player: updatedPlayer,
      stageIndex: _state.stageIndex + 1,
    );
    _isResolvingNode = false;
    refreshNodes();
  }
}
