import '_imports.dart';

class RunSessionController extends ChangeNotifier {
  final RunRandomizer _randomizer;
  final PathNodeService _pathNodeService;
  final List<PathNode>? _availableNodesOverride;
  final int _nodeCount;
  RunState _state;
  bool _isResolvingNode = false;
  PathNode? _activeNode;

  RunSessionController({
    required Battler player,
    required Duration battleEnemyTurnDelay,
    required Duration battleCombatEndDelay,
    List<PathNode>? availableNodes,
    int nodeCount = 3,
    int? randomSeed,
  }) : this._(
          player: player,
          battleEnemyTurnDelay: battleEnemyTurnDelay,
          battleCombatEndDelay: battleCombatEndDelay,
          availableNodes: availableNodes,
          nodeCount: nodeCount,
          randomizer: RunRandomizer(seed: randomSeed),
        );

  RunSessionController.resume({
    required EndpointCurrentRunSnapshot snapshot,
  }) : this._(
          player: snapshot.player,
          battleEnemyTurnDelay: snapshot.battleEnemyTurnDelay,
          battleCombatEndDelay: snapshot.battleCombatEndDelay,
          randomizer: RunRandomizer(
            seed: snapshot.randomSeed,
            state: snapshot.randomState,
          ),
          nodeCount: snapshot.nodeCount,
          restoredState: RunState(
            player: snapshot.player,
            currentHour: snapshot.currentHour,
            visibleNodes: List<PathNode>.unmodifiable(snapshot.visibleNodes),
            stageIndex: snapshot.stageIndex,
            battleEnemyTurnDelay: snapshot.battleEnemyTurnDelay,
            battleCombatEndDelay: snapshot.battleCombatEndDelay,
            isRunComplete: snapshot.isRunComplete,
            completionType: snapshot.completionType,
          ),
          initialIsResolvingNode: snapshot.isResolvingNode,
          initialActiveNode: snapshot.activeNode,
        );

  RunSessionController._({
    required Battler player,
    required Duration battleEnemyTurnDelay,
    required Duration battleCombatEndDelay,
    required RunRandomizer randomizer,
    List<PathNode>? availableNodes,
    int nodeCount = 3,
    RunState? restoredState,
    bool initialIsResolvingNode = false,
    PathNode? initialActiveNode,
  })  : _randomizer = randomizer,
        _pathNodeService = PathNodeService(
          randomizer: randomizer,
        ),
        _availableNodesOverride = availableNodes == null
            ? null
            : List<PathNode>.unmodifiable(availableNodes),
        _nodeCount = max(1, nodeCount),
        _state = restoredState ??
            RunState(
              player: player.materializeOwnedItems(),
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
    _isResolvingNode = initialIsResolvingNode;
    _activeNode = initialActiveNode;
    if (restoredState == null) {
      refreshNodes(saveTrigger: 'runInitialized');
    }
  }

  RunState get state => _state;
  RunRandomizer get randomizer => _randomizer;
  Battler get player => _state.player;
  List<PathNode> get nodes => _state.visibleNodes;
  RunHourSnapshot get currentHour => _state.currentHour;
  PathNode? get activeNode => _activeNode;
  bool get isResolvingNode => _isResolvingNode;
  bool get isRunComplete => _state.isRunComplete;
  RunCompletionType? get completionType => _state.completionType;

  /// Actualiza el jugador fuera de una escena y corta la run al instante si ya no sigue vivo.
  void updatePlayer(Battler player) {
    final resolvedCompletionType = _resolveCompletionType(
      updatedPlayer: player,
    );
    _state = _state.copyWith(
      player: player,
      isRunComplete: resolvedCompletionType != null,
      completionType: resolvedCompletionType,
    );
    notifyListeners();
    if (resolvedCompletionType != null) {
      unawaited(EndpointPreferencesService.clearCurrentRunSnapshot());
      return;
    }
    unawaited(_persistCurrentRun(trigger: 'playerUpdated'));
  }

  bool beginNodeResolution({
    required PathNode node,
  }) {
    if (_isResolvingNode) return false;
    _activeNode = node;
    _isResolvingNode = true;
    notifyListeners();
    unawaited(_persistCurrentRun(trigger: 'enterNode'));
    return true;
  }

  void cancelNodeResolution() {
    if (!_isResolvingNode) return;
    _isResolvingNode = false;
    notifyListeners();
    _activeNode = null;
    unawaited(_persistCurrentRun(trigger: 'exitNodeCancelled'));
  }

  void refreshNodes({
    String? saveTrigger,
  }) {
    final currentHour = _pathNodeService.buildHourSnapshot(
      stageIndex: _state.stageIndex,
      player: _state.player,
      availableNodes: _availableNodesOverride,
      nodeCount: _nodeCount,
    );

    _state = _state.copyWith(
      currentHour: currentHour,
      visibleNodes: List<PathNode>.unmodifiable(currentHour.nodes),
    );
    notifyListeners();
    if (saveTrigger != null) {
      unawaited(_persistCurrentRun(trigger: saveTrigger));
    }
  }

  void completeEncounter({
    required BattleFlowResult result,
    required CombatPathNode node,
  }) {
    final updatedPlayer = result.type == BattleFlowResultType.victory
        ? _applyEncounterExperience(
            player: result.player,
            node: node,
          )
        : result.player;
    _completeScene(
      updatedPlayer: updatedPlayer,
      forcedCompletionType: _completionTypeForBattleResult(result.type),
    );
  }

  void completeCampVisit(CampSiteVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeEventVisit(PathEventVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeArchetypeSelection(Battler player) {
    _completeScene(updatedPlayer: player);
  }

  void completeWeaponShopVisit(WeaponShopVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void _completeScene({
    required Battler updatedPlayer,
    RunCompletionType? forcedCompletionType,
  }) {
    final resolvedCompletionType = forcedCompletionType ??
        _resolveCompletionType(updatedPlayer: updatedPlayer);

    if (resolvedCompletionType != null) {
      _state = _state.copyWith(
        player: updatedPlayer,
        isRunComplete: true,
        completionType: resolvedCompletionType,
      );
      _isResolvingNode = false;
      _activeNode = null;
      notifyListeners();
      unawaited(EndpointPreferencesService.clearCurrentRunSnapshot());
      return;
    }

    final nextStageIndex = _state.stageIndex + 1;
    var nextPlayer = updatedPlayer;
    var nextHour = _pathNodeService.buildHourSnapshot(
      stageIndex: nextStageIndex,
      player: nextPlayer,
      availableNodes: _availableNodesOverride,
      nodeCount: _nodeCount,
    );
    if (_shouldApplyHourStartEffects(nextHour)) {
      nextPlayer = nextPlayer.applyAbilityHourStartEffects();
      nextHour = _pathNodeService.buildHourSnapshot(
        stageIndex: nextStageIndex,
        player: nextPlayer,
        availableNodes: _availableNodesOverride,
        nodeCount: _nodeCount,
      );
    }

    _state = _state.copyWith(
      player: nextPlayer,
      stageIndex: nextStageIndex,
      currentHour: nextHour,
      visibleNodes: List<PathNode>.unmodifiable(nextHour.nodes),
    );
    _isResolvingNode = false;
    _activeNode = null;
    notifyListeners();
    unawaited(_persistCurrentRun(trigger: 'exitNode'));
  }

  /// Entrega la XP del encuentro segun su rareza y deja fuera al boss amarillo final.
  Battler _applyEncounterExperience({
    required Battler player,
    required CombatPathNode node,
  }) {
    final awardedExperience = switch (node.tier) {
      CombatNodeTier.purple => 2,
      CombatNodeTier.yellow => 0,
      CombatNodeTier.gray || CombatNodeTier.green || CombatNodeTier.blue => 1,
    };

    return player.gainExperience(awardedExperience);
  }

  /// Convierte el resultado bruto del combate en un cierre de run forzado cuando procede.
  RunCompletionType? _completionTypeForBattleResult(
    BattleFlowResultType resultType,
  ) {
    switch (resultType) {
      case BattleFlowResultType.victory:
        return null;
      case BattleFlowResultType.defeat:
        return RunCompletionType.defeat;
      case BattleFlowResultType.retreated:
        return RunCompletionType.retreated;
    }
  }

  /// Decide si el estado actual del jugador ya implica victoria o derrota de la run.
  RunCompletionType? _resolveCompletionType({
    required Battler updatedPlayer,
  }) {
    if (updatedPlayer.isDefeated) {
      return RunCompletionType.defeat;
    }
    if (_state.stageIndex >= PathNodeService.sunriseStageIndex) {
      return RunCompletionType.victory;
    }

    return null;
  }

  bool _shouldApplyHourStartEffects(RunHourSnapshot hour) {
    return hour.phase == RunHourPhase.day || hour.phase == RunHourPhase.night;
  }

  Future<void> _persistCurrentRun({
    required String trigger,
    PathNode? activeNodeOverride,
  }) {
    return EndpointPreferencesService.saveCurrentRunSnapshot(
      state: _state,
      randomizer: _randomizer,
      isResolvingNode: _isResolvingNode,
      trigger: trigger,
      activeNode: activeNodeOverride ?? _activeNode,
    );
  }
}
