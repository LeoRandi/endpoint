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
    bool persistRun = true,
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
            runSummary: snapshot.runSummary,
            currentDaySummary: snapshot.currentDaySummary,
            pendingDaySummary: snapshot.pendingDaySummary,
            shownShopNodeIds: snapshot.shownShopNodeIds,
            shopRarityDayOffset: snapshot.shopRarityDayOffset,
            eventRarityDayOffset: snapshot.eventRarityDayOffset,
            isRunComplete: snapshot.isRunComplete,
            completionType: snapshot.completionType,
          ),
          initialIsResolvingNode: snapshot.isResolvingNode,
          initialActiveNode: snapshot.activeNode,
          persistRun: persistRun,
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
              runSummary: const RunDaySummary.empty(dayNumber: 1),
              currentDaySummary: const RunDaySummary.empty(dayNumber: 1),
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
  RunDaySummary get currentDaySummary => _state.currentDaySummary;
  RunDaySummary get runSummary => _state.runSummary;
  RunDaySummary? get pendingDaySummary => _state.pendingDaySummary;
  bool get hasPendingDaySummary => _state.pendingDaySummary != null;

  /// Actualiza el jugador fuera de una escena y corta la run al instante si ya no sigue vivo.
  void updatePlayer(Battler player) {
    _updatePlayer(player);
  }

  /// Actualiza el jugador y registra en el resumen los premios obtenidos fuera de una escena.
  void updatePlayerWithRewards(Battler player) {
    _updatePlayer(
      player,
      recordRewardsInDaySummary: true,
      persistTrigger: 'playerRewardsUpdated',
    );
  }

  void _updatePlayer(
    Battler player, {
    bool recordRewardsInDaySummary = false,
    String persistTrigger = 'playerUpdated',
  }) {
    if (_state.pendingDaySummary != null) {
      _state = _state.copyWith(player: player);
      notifyListeners();
      unawaited(_persistCurrentRun(trigger: 'playerUpdatedDuringSummary'));
      return;
    }

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
    final updatedDaySummary = _shouldRecordCurrentStageInDaySummary(
      recordRewardsInDaySummary,
    )
        ? _state.currentDaySummary.recordScene(
            before: _state.player,
            after: player,
          )
        : _state.currentDaySummary;
    final updatedRunSummary =
        _shouldRecordCurrentStageInDaySummary(recordRewardsInDaySummary)
            ? _state.runSummary.recordScene(
                before: _state.player,
                after: player,
              )
            : _state.runSummary;
    var nextState = _state.copyWith(
      player: player,
      runSummary: updatedRunSummary,
      currentDaySummary: updatedDaySummary,
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
          shownShopNodeIds: _updatedShownShopNodeIds(
            previousShownShopNodeIds: _state.shownShopNodeIds,
            hour: conventionHour,
            player: player,
          ),
        );
      } else if (shouldRerollVisibleNodes) {
        final rerolledHour = _buildRefactoredHourSnapshot(
          player: player,
          previousNodes: _state.visibleNodes,
        );
        nextState = nextState.copyWith(
          currentHour: rerolledHour,
          visibleNodes: List<PathNode>.unmodifiable(rerolledHour.nodes),
          shownShopNodeIds: _updatedShownShopNodeIds(
            previousShownShopNodeIds: _state.shownShopNodeIds,
            hour: rerolledHour,
            player: player,
          ),
        );
      }
    }

    _state = nextState;
    notifyListeners();
    if (resolvedCompletionType != null) {
      unawaited(clearPersistedRunSnapshot());
      return;
    }
    unawaited(_persistCurrentRun(trigger: persistTrigger));
  }

  bool beginNodeResolution({
    required PathNode node,
  }) {
    if (_state.pendingDaySummary != null) return false;
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
    if (_state.pendingDaySummary != null) {
      _state = _state.copyWith(visibleNodes: const <PathNode>[]);
      notifyListeners();
      if (saveTrigger != null) {
        unawaited(_persistCurrentRun(trigger: saveTrigger));
      }
      return;
    }

    final currentHour = _pathNodeService.buildHourSnapshot(
      stageIndex: _state.stageIndex,
      player: _state.player,
      availableNodes:
          _scriptedNodesForStage(_state.stageIndex) ?? _availableNodesOverride,
      shownShopNodeIds: _state.shownShopNodeIds,
      nodeCount: _nodeCount,
      shopRarityDayOffset: _state.shopRarityDayOffset,
      eventRarityDayOffset: _state.eventRarityDayOffset,
    );

    _state = _state.copyWith(
      currentHour: currentHour,
      visibleNodes: List<PathNode>.unmodifiable(currentHour.nodes),
      shownShopNodeIds: _updatedShownShopNodeIds(
        previousShownShopNodeIds: _state.shownShopNodeIds,
        hour: currentHour,
        player: _state.player,
      ),
    );
    notifyListeners();
    if (saveTrigger != null) {
      unawaited(_persistCurrentRun(trigger: saveTrigger));
    }
  }

  bool continueToNextDay() {
    final completedSummary = _state.pendingDaySummary;
    if (completedSummary == null || _state.isRunComplete) return false;

    final nextStageIndex = _state.stageIndex + 1;
    if (nextStageIndex > PathNodeService.sunriseStageIndex) {
      _state = _state.copyWith(
        isRunComplete: true,
        completionType: RunCompletionType.victory,
        pendingDaySummary: null,
        shopRarityDayOffset: 0,
        eventRarityDayOffset: 0,
      );
      notifyListeners();
      unawaited(clearPersistedRunSnapshot());
      return true;
    }

    final preparedPlayer = _preparePlayerForNextDay(_state.player);
    final nextRunStep = _buildRunStep(
      stageIndex: nextStageIndex,
      player: preparedPlayer,
      shopRarityDayOffset: 0,
      eventRarityDayOffset: 0,
    );
    final nextDayNumber = PathNodeService.dayNumberForStageIndex(
      nextStageIndex,
    );
    final nextDaySummary = _recordTransitionGains(
      summary: RunDaySummary.empty(dayNumber: nextDayNumber),
      before: preparedPlayer,
      after: nextRunStep.player,
    );
    final nextRunSummary = _recordTransitionGains(
      summary: _state.runSummary,
      before: preparedPlayer,
      after: nextRunStep.player,
    );

    _state = _state.copyWith(
      player: nextRunStep.player,
      stageIndex: nextStageIndex,
      currentHour: nextRunStep.hour,
      visibleNodes: List<PathNode>.unmodifiable(nextRunStep.hour.nodes),
      runSummary: nextRunSummary,
      currentDaySummary: nextDaySummary,
      pendingDaySummary: null,
      shownShopNodeIds: nextRunStep.shownShopNodeIds,
      shopRarityDayOffset: 0,
      eventRarityDayOffset: 0,
    );
    _isResolvingNode = false;
    _activeNode = null;
    notifyListeners();
    unawaited(_persistCurrentRun(trigger: 'nextDayStarted'));
    return true;
  }

  Battler _preparePlayerForNextDay(Battler player) {
    final withoutDebuffs = player.copyWith(
      statuses: List<BattlerStatus>.unmodifiable(
        player.statuses
            .where((status) => status.type != BattlerStatusType.debuff),
      ),
    );

    return withoutDebuffs.copyWith(health: withoutDebuffs.maxHealth);
  }

  void completeEncounter({
    required BattleFlowResult result,
    required CombatPathNode node,
  }) {
    final updatedPlayer = result.type == BattleFlowResultType.victory
        ? _applyEncounterExperience(
            player: result.player,
            node: node,
            isDailyBoss: PathNodeService.isDailyBossStage(_state.stageIndex),
          )
        : result.player;
    _completeScene(
      updatedPlayer: updatedPlayer,
      forcedCompletionType: _completionTypeForBattleResult(result.type),
      defeatedEnemy: result.type == BattleFlowResultType.victory,
      defeatedEnemyBattler: node.enemy,
      defeatedEnemyRarity: node.tier.rarity,
    );
  }

  void completeCampVisit(CampSiteVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeEventVisit(PathEventVisitResult result) {
    _completeScene(
      updatedPlayer: result.player,
      guaranteedNextNode: result.guaranteedNextNode,
      nextShopRarityDayOffset: result.nextShopRarityDayOffset,
      nextEventRarityDayOffset: result.nextEventRarityDayOffset,
      defeatedEnemy: result.defeatedEnemy,
      defeatedEnemyBattler: result.defeatedEnemyBattler,
      defeatedEnemyRarity: result.defeatedEnemyRarity,
    );
  }

  void completeArchetypeSelection(Battler player) {
    _completeScene(
      updatedPlayer: player,
      includeSceneRewardsInDaySummary: false,
    );
  }

  void completeWeaponShopVisit(WeaponShopVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void _completeScene({
    required Battler updatedPlayer,
    RunCompletionType? forcedCompletionType,
    PathNode? guaranteedNextNode,
    int nextShopRarityDayOffset = 0,
    int nextEventRarityDayOffset = 0,
    bool defeatedEnemy = false,
    Battler? defeatedEnemyBattler,
    RarityTier? defeatedEnemyRarity,
    bool includeSceneRewardsInDaySummary = true,
  }) {
    final resolvedCompletionType = forcedCompletionType ??
        _resolveCompletionType(updatedPlayer: updatedPlayer);
    final shouldRecordScene =
        _shouldRecordCurrentStageInDaySummary(includeSceneRewardsInDaySummary);
    final updatedDaySummary = shouldRecordScene
        ? _state.currentDaySummary.recordScene(
            before: _state.player,
            after: updatedPlayer,
            defeatedEnemy: defeatedEnemy,
            defeatedEnemyBattler: defeatedEnemyBattler,
            defeatedEnemyRarity: defeatedEnemyRarity,
            includeRewards: includeSceneRewardsInDaySummary,
          )
        : _state.currentDaySummary;
    final updatedRunSummary = shouldRecordScene
        ? _state.runSummary.recordScene(
            before: _state.player,
            after: updatedPlayer,
            defeatedEnemy: defeatedEnemy,
            defeatedEnemyBattler: defeatedEnemyBattler,
            defeatedEnemyRarity: defeatedEnemyRarity,
            includeRewards: includeSceneRewardsInDaySummary,
          )
        : _state.runSummary;

    if (resolvedCompletionType != null) {
      _state = _state.copyWith(
        player: updatedPlayer,
        runSummary: updatedRunSummary,
        currentDaySummary: updatedDaySummary,
        isRunComplete: true,
        completionType: resolvedCompletionType,
        pendingDaySummary: null,
        shopRarityDayOffset: 0,
        eventRarityDayOffset: 0,
      );
      _isResolvingNode = false;
      _activeNode = null;
      notifyListeners();
      unawaited(clearPersistedRunSnapshot());
      return;
    }

    final nextStageIndex = _state.stageIndex + 1;
    if (nextStageIndex > PathNodeService.sunriseStageIndex) {
      _state = _state.copyWith(
        player: updatedPlayer,
        stageIndex: nextStageIndex,
        runSummary: updatedRunSummary,
        currentDaySummary: updatedDaySummary,
        pendingDaySummary: null,
        isRunComplete: true,
        completionType: RunCompletionType.victory,
        shopRarityDayOffset: 0,
        eventRarityDayOffset: 0,
      );
      _isResolvingNode = false;
      _activeNode = null;
      notifyListeners();
      unawaited(clearPersistedRunSnapshot());
      return;
    }

    if (PathNodeService.isDailyBossStage(_state.stageIndex)) {
      _state = _state.copyWith(
        player: updatedPlayer,
        runSummary: updatedRunSummary,
        currentDaySummary: updatedDaySummary,
        pendingDaySummary: updatedDaySummary,
        visibleNodes: const <PathNode>[],
        shopRarityDayOffset: 0,
        eventRarityDayOffset: 0,
      );
      _isResolvingNode = false;
      _activeNode = null;
      notifyListeners();
      unawaited(_persistCurrentRun(trigger: 'dayCompleted'));
      return;
    }

    final activeShopRarityDayOffset = nextShopRarityDayOffset != 0
        ? nextShopRarityDayOffset
        : _state.shopRarityDayOffset;
    final activeEventRarityDayOffset = nextEventRarityDayOffset != 0
        ? nextEventRarityDayOffset
        : _state.eventRarityDayOffset;
    final nextRunStep = _buildRunStep(
      stageIndex: nextStageIndex,
      player: updatedPlayer,
      guaranteedNextNode: guaranteedNextNode,
      shopRarityDayOffset: activeShopRarityDayOffset,
      eventRarityDayOffset: activeEventRarityDayOffset,
    );
    final nextDaySummary = _recordTransitionGains(
      summary: updatedDaySummary,
      before: updatedPlayer,
      after: nextRunStep.player,
    );
    final nextRunSummary = _recordTransitionGains(
      summary: updatedRunSummary,
      before: updatedPlayer,
      after: nextRunStep.player,
    );

    _state = _state.copyWith(
      player: nextRunStep.player,
      stageIndex: nextStageIndex,
      currentHour: nextRunStep.hour,
      visibleNodes: List<PathNode>.unmodifiable(nextRunStep.hour.nodes),
      runSummary: nextRunSummary,
      currentDaySummary: nextDaySummary,
      shownShopNodeIds: nextRunStep.shownShopNodeIds,
      shopRarityDayOffset: activeShopRarityDayOffset,
      eventRarityDayOffset: activeEventRarityDayOffset,
    );
    _isResolvingNode = false;
    _activeNode = null;
    notifyListeners();
    unawaited(_persistCurrentRun(trigger: 'exitNode'));
  }

  bool _shouldRecordCurrentStageInDaySummary(bool includeSceneRewards) {
    return includeSceneRewards &&
        _state.stageIndex >= PathNodeService.firstPlayableStageIndex;
  }

  RunDaySummary _recordTransitionGains({
    required RunDaySummary summary,
    required Battler before,
    required Battler after,
  }) {
    if (after.money <= before.money) return summary;

    return summary.recordScene(
      before: before,
      after: after,
      includeRewards: false,
    );
  }

  _RunStep _buildRunStep({
    required int stageIndex,
    required Battler player,
    PathNode? guaranteedNextNode,
    int? shopRarityDayOffset,
    int? eventRarityDayOffset,
  }) {
    final activeShopRarityDayOffset =
        shopRarityDayOffset ?? _state.shopRarityDayOffset;
    final activeEventRarityDayOffset =
        eventRarityDayOffset ?? _state.eventRarityDayOffset;
    var nextPlayer = _progressPathSelectionAbilityCooldowns(player);
    var nextHour = _pathNodeService.buildHourSnapshot(
      stageIndex: stageIndex,
      player: nextPlayer,
      availableNodes:
          _scriptedNodesForStage(stageIndex) ?? _availableNodesOverride,
      shownShopNodeIds: _state.shownShopNodeIds,
      nodeCount: _nodeCount,
      shopRarityDayOffset: activeShopRarityDayOffset,
      eventRarityDayOffset: activeEventRarityDayOffset,
    );
    if (_shouldApplyHourStartEffects(nextHour)) {
      nextPlayer = nextPlayer.applyAbilityHourStartEffects();
      nextHour = _pathNodeService.buildHourSnapshot(
        stageIndex: stageIndex,
        player: nextPlayer,
        availableNodes:
            _scriptedNodesForStage(stageIndex) ?? _availableNodesOverride,
        shownShopNodeIds: _state.shownShopNodeIds,
        nodeCount: _nodeCount,
        shopRarityDayOffset: activeShopRarityDayOffset,
        eventRarityDayOffset: activeEventRarityDayOffset,
      );
    }
    nextHour = _injectGuaranteedNextNode(
      hour: nextHour,
      guaranteedNextNode: guaranteedNextNode,
    );

    return _RunStep(
      player: nextPlayer,
      hour: nextHour,
      shownShopNodeIds: _updatedShownShopNodeIds(
        previousShownShopNodeIds: _state.shownShopNodeIds,
        hour: nextHour,
        player: nextPlayer,
      ),
    );
  }

  RunHourSnapshot _injectGuaranteedNextNode({
    required RunHourSnapshot hour,
    PathNode? guaranteedNextNode,
  }) {
    final guaranteedNode = guaranteedNextNode;
    if (guaranteedNode == null || hour.nodes.isEmpty) {
      return hour;
    }
    if (hour.phase == RunHourPhase.dusk || hour.phase == RunHourPhase.sunrise) {
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

  /// Entrega la XP del encuentro segun su rareza y suma bonus en bosses diarios.
  Battler _applyEncounterExperience({
    required Battler player,
    required CombatPathNode node,
    required bool isDailyBoss,
  }) {
    final baseExperience = switch (node.tier) {
      CombatNodeTier.purple => 2,
      CombatNodeTier.yellow => 0,
      CombatNodeTier.gray || CombatNodeTier.green || CombatNodeTier.blue => 1,
    };
    final awardedExperience = baseExperience + (isDailyBoss ? 1 : 0);

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

  /// Decide si el estado actual del jugador ya implica una derrota inmediata.
  ///
  /// La victoria se concede al avanzar mas alla del boss del quinto dia, no
  /// por estar esperando a seleccionar o resolver ese nodo.
  RunCompletionType? _resolveCompletionType({
    required Battler updatedPlayer,
  }) {
    if (updatedPlayer.isDefeated) {
      return RunCompletionType.defeat;
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
      shownShopNodeIds: _state.shownShopNodeIds,
      nodeCount: _nodeCount,
      shopRarityDayOffset: _state.shopRarityDayOffset,
      eventRarityDayOffset: _state.eventRarityDayOffset,
    );

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidateSnapshot = attempt == 0
          ? latestSnapshot
          : _pathNodeService.buildHourSnapshot(
              stageIndex: _state.stageIndex,
              player: player,
              availableNodes: _scriptedNodesForStage(_state.stageIndex) ??
                  _availableNodesOverride,
              shownShopNodeIds: _state.shownShopNodeIds,
              nodeCount: _nodeCount,
              shopRarityDayOffset: _state.shopRarityDayOffset,
              eventRarityDayOffset: _state.eventRarityDayOffset,
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

  List<String> _updatedShownShopNodeIds({
    required List<String> previousShownShopNodeIds,
    required RunHourSnapshot hour,
    required Battler player,
  }) {
    final visibleShopNodeIds = hour.nodes
        .whereType<ShopPathNode>()
        .map((node) => node.nodeId)
        .toList(growable: false);
    if (visibleShopNodeIds.isEmpty) {
      return previousShownShopNodeIds;
    }

    final eligibleShopNodeIds = _pathNodeService.eligibleShopNodeIdsFor(
      stageIndex: hour.stageIndex,
      player: player,
    );
    final previousShownSet = previousShownShopNodeIds.toSet();
    final hasCompletedCycle = eligibleShopNodeIds.isNotEmpty &&
        eligibleShopNodeIds.every(previousShownSet.contains);
    final updatedShownSet =
        hasCompletedCycle ? <String>{} : Set<String>.from(previousShownSet);
    updatedShownSet.addAll(visibleShopNodeIds);

    return List<String>.unmodifiable(updatedShownSet);
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
      nodeCount: _nodeCount,
      activeNode: activeNodeOverride ?? _activeNode,
    );
  }

  Future<void> clearPersistedRunSnapshot() {
    if (!_persistRun) return Future<void>.value();

    return EndpointPreferencesService.clearCurrentRunSnapshot();
  }

  List<PathNode>? _scriptedNodesForStage(int stageIndex) {
    final scriptedNodes = _scriptedNodesByStage?[stageIndex];
    if (scriptedNodes == null || scriptedNodes.isEmpty) return null;

    return scriptedNodes;
  }
}

class _RunStep {
  final Battler player;
  final RunHourSnapshot hour;
  final List<String> shownShopNodeIds;

  const _RunStep({
    required this.player,
    required this.hour,
    required this.shownShopNodeIds,
  });
}
