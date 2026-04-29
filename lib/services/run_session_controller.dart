import '_imports.dart';

class RunSessionController extends ChangeNotifier {
  final RunRandomizer _randomizer;
  final PathNodeService _pathNodeService;
  final List<PathNode>? _availableNodesOverride;
  final Map<int, List<PathNode>>? _scriptedNodesByStage;
  final int _nodeCount;
  final bool _persistRun;
  RunState _state;
  bool _isResolvingNode = false;
  PathNode? _activeNode;

  RunSessionController({
    required Battler player,
    required Duration battleEnemyTurnDelay,
    required Duration battleCombatEndDelay,
    List<PathNode>? availableNodes,
    Map<int, List<PathNode>>? scriptedNodesByStage,
    int nodeCount = 3,
    int? randomSeed,
    bool persistRun = true,
  }) : this._(
          player: player,
          battleEnemyTurnDelay: battleEnemyTurnDelay,
          battleCombatEndDelay: battleCombatEndDelay,
          availableNodes: availableNodes,
          scriptedNodesByStage: scriptedNodesByStage,
          nodeCount: nodeCount,
          randomizer: RunRandomizer(seed: randomSeed),
          persistRun: persistRun,
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
    Map<int, List<PathNode>>? scriptedNodesByStage,
    int nodeCount = 3,
    RunState? restoredState,
    bool initialIsResolvingNode = false,
    PathNode? initialActiveNode,
    bool persistRun = true,
  })  : _randomizer = randomizer,
        _pathNodeService = PathNodeService(
          randomizer: randomizer,
        ),
        _availableNodesOverride = availableNodes == null
            ? null
            : List<PathNode>.unmodifiable(availableNodes),
        _scriptedNodesByStage = scriptedNodesByStage == null
            ? null
            : Map<int, List<PathNode>>.unmodifiable({
                for (final entry in scriptedNodesByStage.entries)
                  entry.key: List<PathNode>.unmodifiable(entry.value),
              }),
        _nodeCount = max(1, nodeCount),
        _persistRun = persistRun,
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
    final shouldRerollVisibleNodes = _didTriggerTimelineRefactor(
      previousPlayer: _state.player,
      updatedPlayer: player,
    );
    final shouldConveneShopNodes = _didTriggerSuddenConvention(
      previousPlayer: _state.player,
      updatedPlayer: player,
    );
    final resolvedCompletionType = _resolveCompletionType(
      updatedPlayer: player,
    );
    var nextState = _state.copyWith(
      player: player,
      isRunComplete: resolvedCompletionType != null,
      completionType: resolvedCompletionType,
    );
    if (resolvedCompletionType == null && !_isResolvingNode) {
      if (shouldConveneShopNodes && _canApplySuddenConvention()) {
        final conventionHour = _buildSuddenConventionHourSnapshot(
          player: player,
        );
        nextState = nextState.copyWith(
          currentHour: conventionHour,
          visibleNodes: List<PathNode>.unmodifiable(conventionHour.nodes),
        );
      } else if (shouldRerollVisibleNodes) {
        final rerolledHour = _buildRefactoredHourSnapshot(
          player: player,
          previousNodes: _state.visibleNodes,
        );
        nextState = nextState.copyWith(
          currentHour: rerolledHour,
          visibleNodes: List<PathNode>.unmodifiable(rerolledHour.nodes),
        );
      }
    }

    _state = nextState;
    notifyListeners();
    if (resolvedCompletionType != null) {
      if (_persistRun) {
        unawaited(EndpointPreferencesService.clearCurrentRunSnapshot());
      }
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
      availableNodes:
          _scriptedNodesForStage(_state.stageIndex) ?? _availableNodesOverride,
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
    _completeScene(
      updatedPlayer: result.player,
      guaranteedNextNode: result.guaranteedNextNode,
    );
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
    PathNode? guaranteedNextNode,
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
      if (_persistRun) {
        unawaited(EndpointPreferencesService.clearCurrentRunSnapshot());
      }
      return;
    }

    final nextStageIndex = _state.stageIndex + 1;
    var nextPlayer = _progressPathSelectionAbilityCooldowns(updatedPlayer);
    var nextHour = _pathNodeService.buildHourSnapshot(
      stageIndex: nextStageIndex,
      player: nextPlayer,
      availableNodes:
          _scriptedNodesForStage(nextStageIndex) ?? _availableNodesOverride,
      nodeCount: _nodeCount,
    );
    if (_shouldApplyHourStartEffects(nextHour)) {
      nextPlayer = nextPlayer.applyAbilityHourStartEffects();
      nextHour = _pathNodeService.buildHourSnapshot(
        stageIndex: nextStageIndex,
        player: nextPlayer,
        availableNodes:
            _scriptedNodesForStage(nextStageIndex) ?? _availableNodesOverride,
        nodeCount: _nodeCount,
      );
    }
    nextHour = _injectGuaranteedNextNode(
      hour: nextHour,
      guaranteedNextNode: guaranteedNextNode,
    );

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

  RunHourSnapshot _injectGuaranteedNextNode({
    required RunHourSnapshot hour,
    PathNode? guaranteedNextNode,
  }) {
    final guaranteedNode = guaranteedNextNode;
    if (guaranteedNode == null || hour.nodes.isEmpty) {
      return hour;
    }
    if (hour.nodes.any((node) => node.nodeId == guaranteedNode.nodeId)) {
      return hour;
    }

    final updatedNodes = List<PathNode>.from(hour.nodes);
    final replaceIndex = _randomizer.nextInt(updatedNodes.length);
    updatedNodes[replaceIndex] = guaranteedNode;

    return RunHourSnapshot(
      stageIndex: hour.stageIndex,
      phase: hour.phase,
      title: hour.title,
      subtitle: hour.subtitle,
      nodes: List<PathNode>.unmodifiable(updatedNodes),
    );
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

  bool _didTriggerTimelineRefactor({
    required Battler previousPlayer,
    required Battler updatedPlayer,
  }) {
    final previousAbility =
        previousPlayer.abilityById(BattlerAbilityId.refactorizacionTimeline);
    final updatedAbility =
        updatedPlayer.abilityById(BattlerAbilityId.refactorizacionTimeline);
    if (previousAbility == null || updatedAbility == null) {
      return false;
    }

    final cooldownRaised = updatedAbility.remainingCooldownTurns >
        previousAbility.remainingCooldownTurns;
    final spentCredits = updatedPlayer.money < previousPlayer.money;
    return cooldownRaised && spentCredits;
  }

  bool _didTriggerSuddenConvention({
    required Battler previousPlayer,
    required Battler updatedPlayer,
  }) {
    final previousAbility =
        previousPlayer.abilityById(BattlerAbilityId.convencionRepentina);
    final updatedAbility =
        updatedPlayer.abilityById(BattlerAbilityId.convencionRepentina);
    if (previousAbility == null || updatedAbility == null) {
      return false;
    }

    return updatedAbility.remainingCooldownTurns >
        previousAbility.remainingCooldownTurns;
  }

  bool _canApplySuddenConvention() {
    return currentHour.phase != RunHourPhase.dusk &&
        currentHour.phase != RunHourPhase.sunrise;
  }

  Battler _progressPathSelectionAbilityCooldowns(Battler player) {
    final cappedPlayer = player.enforceAbilityCooldownCap();
    if (cappedPlayer.abilities.isEmpty) return cappedPlayer;

    var hasChanges = false;
    final updatedAbilities = cappedPlayer.abilities.map((ability) {
      if (ability.manualActivationContext !=
          BattlerAbilityActivationContext.pathSelection) {
        return ability;
      }

      final tickedAbility = ability.tickCooldown();
      if (tickedAbility.remainingCooldownTurns !=
          ability.remainingCooldownTurns) {
        hasChanges = true;
      }
      return tickedAbility;
    }).toList(growable: false);

    if (!hasChanges) return cappedPlayer;

    return cappedPlayer.copyWith(
      abilities: List<BattlerAbility>.unmodifiable(updatedAbilities),
    );
  }

  RunHourSnapshot _buildRefactoredHourSnapshot({
    required Battler player,
    required List<PathNode> previousNodes,
  }) {
    const maxAttempts = 24;
    RunHourSnapshot? firstDifferentSnapshot;
    RunHourSnapshot latestSnapshot = _pathNodeService.buildHourSnapshot(
      stageIndex: _state.stageIndex,
      player: player,
      availableNodes:
          _scriptedNodesForStage(_state.stageIndex) ?? _availableNodesOverride,
      nodeCount: _nodeCount,
    );

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidateSnapshot = attempt == 0
          ? latestSnapshot
          : _pathNodeService.buildHourSnapshot(
              stageIndex: _state.stageIndex,
              player: player,
              availableNodes: _scriptedNodesForStage(_state.stageIndex) ??
                  _availableNodesOverride,
              nodeCount: _nodeCount,
            );
      latestSnapshot = candidateSnapshot;

      if (!_areNodeListsEqualById(
        previousNodes,
        candidateSnapshot.nodes,
      )) {
        firstDifferentSnapshot ??= candidateSnapshot;
      }
      if (_areAllNodeIdsDistinct(
        previousNodes,
        candidateSnapshot.nodes,
      )) {
        return candidateSnapshot;
      }
    }

    return firstDifferentSnapshot ?? latestSnapshot;
  }

  RunHourSnapshot _buildSuddenConventionHourSnapshot({
    required Battler player,
  }) {
    return _pathNodeService.buildSuddenConventionSnapshot(
      stageIndex: _state.stageIndex,
      player: player,
      nodeCount: _nodeCount,
    );
  }

  bool _areNodeListsEqualById(
    List<PathNode> leftNodes,
    List<PathNode> rightNodes,
  ) {
    if (leftNodes.length != rightNodes.length) return false;

    for (var index = 0; index < leftNodes.length; index++) {
      if (leftNodes[index].nodeId != rightNodes[index].nodeId) {
        return false;
      }
    }

    return true;
  }

  bool _areAllNodeIdsDistinct(
    List<PathNode> previousNodes,
    List<PathNode> candidateNodes,
  ) {
    final previousNodeIds = previousNodes.map((node) => node.nodeId).toSet();
    if (previousNodeIds.isEmpty || candidateNodes.isEmpty) {
      return !_areNodeListsEqualById(previousNodes, candidateNodes);
    }

    return candidateNodes.every(
      (candidateNode) => !previousNodeIds.contains(candidateNode.nodeId),
    );
  }

  Future<void> _persistCurrentRun({
    required String trigger,
    PathNode? activeNodeOverride,
  }) {
    if (!_persistRun) return Future<void>.value();

    return EndpointPreferencesService.saveCurrentRunSnapshot(
      state: _state,
      randomizer: _randomizer,
      isResolvingNode: _isResolvingNode,
      trigger: trigger,
      activeNode: activeNodeOverride ?? _activeNode,
    );
  }

  List<PathNode>? _scriptedNodesForStage(int stageIndex) {
    final scriptedNodes = _scriptedNodesByStage?[stageIndex];
    if (scriptedNodes == null || scriptedNodes.isEmpty) return null;

    return scriptedNodes;
  }
}
