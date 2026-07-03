import '_imports.dart';
import '../persistence/endpoint_preferences_models.dart';

class RunSessionController extends ChangeNotifier {
  static const int _ordinaryDefeatRewardMoney = 3;

  final RunRandomizer _randomizer;
  final PathNodeService _pathNodeService;
  final List<PathNode>? _availableNodesOverride;
  final Map<int, List<PathNode>>? _scriptedNodesByStage;
  final EndpointRunRulesMode _runRulesMode;
  final int _nodeCount;
  final bool _persistRun;
  final RunSnapshotRepository _snapshotRepository;
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
    EndpointRunRulesMode runRulesMode = EndpointRunRulesMode.fullHeal,
    bool persistRun = true,
    RunSnapshotRepository snapshotRepository =
        const NoopRunSnapshotRepository(),
  }) : this._(
          player: player,
          battleEnemyTurnDelay: battleEnemyTurnDelay,
          battleCombatEndDelay: battleCombatEndDelay,
          availableNodes: availableNodes,
          scriptedNodesByStage: scriptedNodesByStage,
          nodeCount: nodeCount,
          runRulesMode: runRulesMode,
          randomizer: RunRandomizer(seed: randomSeed),
          persistRun: persistRun,
          snapshotRepository: snapshotRepository,
        );

  RunSessionController.resume({
    required EndpointCurrentRunSnapshot snapshot,
    EndpointRunRulesMode runRulesMode = EndpointRunRulesMode.fullHeal,
    bool persistRun = true,
    RunSnapshotRepository snapshotRepository =
        const NoopRunSnapshotRepository(),
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
            shownEventNodeIds: snapshot.shownEventNodeIds,
            shopRarityDayOffset: snapshot.shopRarityDayOffset,
            eventRarityDayOffset: snapshot.eventRarityDayOffset,
            ghostItemLease: snapshot.ghostItemLease,
            isRunComplete: snapshot.isRunComplete,
            completionType: snapshot.completionType,
          ),
          initialIsResolvingNode: snapshot.isResolvingNode,
          initialActiveNode: snapshot.activeNode,
          runRulesMode: runRulesMode,
          persistRun: persistRun,
          snapshotRepository: snapshotRepository,
        );

  RunSessionController._({
    required Battler player,
    required Duration battleEnemyTurnDelay,
    required Duration battleCombatEndDelay,
    required RunRandomizer randomizer,
    List<PathNode>? availableNodes,
    Map<int, List<PathNode>>? scriptedNodesByStage,
    int nodeCount = 3,
    EndpointRunRulesMode runRulesMode = EndpointRunRulesMode.fullHeal,
    RunState? restoredState,
    bool initialIsResolvingNode = false,
    PathNode? initialActiveNode,
    bool persistRun = true,
    required RunSnapshotRepository snapshotRepository,
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
        _runRulesMode = runRulesMode,
        _nodeCount = max(1, nodeCount),
        _persistRun = persistRun,
        _snapshotRepository = snapshotRepository,
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
  bool get _isFullHealMode => _runRulesMode == EndpointRunRulesMode.fullHeal;
  RunCompletionType? get completionType => _state.completionType;
  RunDaySummary get currentDaySummary => _state.currentDaySummary;
  RunDaySummary get runSummary => _state.runSummary;
  RunDaySummary? get pendingDaySummary => _state.pendingDaySummary;
  bool get hasPendingDaySummary => _state.pendingDaySummary != null;
  GhostItemLease? get ghostItemLease => _state.ghostItemLease;
  bool get hasPendingGhostItemResolution =>
      _state.ghostItemLease?.isDue == true &&
      _ghostLeasedItem(_state.player) != null;
  Item? get pendingGhostItem => _ghostLeasedItem(_state.player);

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
    if (hasPendingGhostItemResolution) return false;
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
      shownEventNodeIds: _state.shownEventNodeIds,
      includeHealingFreeValueNodes: !_isFullHealMode,
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
      shownEventNodeIds: _updatedShownEventNodeIds(
        previousShownEventNodeIds: _state.shownEventNodeIds,
        hour: currentHour,
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
        shownShopNodeIds: const <String>[],
        shownEventNodeIds: const <String>[],
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
      shownEventNodeIds: nextRunStep.shownEventNodeIds,
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
    final isVictory = result.type == BattleFlowResultType.victory;
    final isFinalBossDefeat =
        result.type == BattleFlowResultType.defeat && _isFinalBossNode(node);
    final doesDefeatEndRun =
        result.type == BattleFlowResultType.defeat &&
            (!_isFullHealMode || isFinalBossDefeat);
    final hasSurvivedCombat =
        result.type != BattleFlowResultType.retreated && !doesDefeatEndRun;
    var updatedPlayer = isVictory
        ? _applyEncounterExperience(
            player: result.player,
            node: node,
            isDailyBoss: PathNodeService.isDailyBossStage(_state.stageIndex),
          )
        : result.player;
    if (_isFullHealMode &&
        result.type == BattleFlowResultType.defeat &&
        !isFinalBossDefeat) {
      updatedPlayer = updatedPlayer.earnMoney(_ordinaryDefeatRewardMoney);
    }
    if (_isFullHealMode && hasSurvivedCombat) {
      updatedPlayer = _healPlayerToFull(updatedPlayer);
    }
    final updatedGhostLease = hasSurvivedCombat
        ? _advanceGhostItemLeaseAfterCombat(updatedPlayer)
        : _state.ghostItemLease;
    _completeScene(
      updatedPlayer: updatedPlayer,
      forcedCompletionType: doesDefeatEndRun
          ? RunCompletionType.defeat
          : _completionTypeForBattleResult(result.type),
      defeatedEnemy: isVictory,
      defeatedEnemyBattler: node.enemy,
      defeatedEnemyRarity: node.tier.rarity,
      ghostItemLease: updatedGhostLease,
    );
  }

  void completeCampVisit(CampSiteVisitResult result) {
    _completeScene(updatedPlayer: result.player);
  }

  void completeEventVisit(PathEventVisitResult result) {
    final didLoseEventCombat = result.player.isDefeated;
    var updatedPlayer = _isFullHealMode && didLoseEventCombat
        ? result.player.earnMoney(_ordinaryDefeatRewardMoney)
        : result.player;
    if (_isFullHealMode && (result.defeatedEnemy || didLoseEventCombat)) {
      updatedPlayer = _healPlayerToFull(updatedPlayer);
    }
    final updatedGhostLease =
        _isFullHealMode && (result.defeatedEnemy || didLoseEventCombat)
        ? _advanceGhostItemLeaseAfterCombat(updatedPlayer)
        : result.ghostItemLease;
    _completeScene(
      updatedPlayer: updatedPlayer,
      guaranteedNextNode: result.guaranteedNextNode,
      nextShopRarityDayOffset: result.nextShopRarityDayOffset,
      nextEventRarityDayOffset: result.nextEventRarityDayOffset,
      defeatedEnemy: result.defeatedEnemy,
      defeatedEnemyBattler: result.defeatedEnemyBattler,
      defeatedEnemyRarity: result.defeatedEnemyRarity,
      ghostItemLease: updatedGhostLease,
    );
  }

  void resolveGhostItemLease({
    required bool keepItem,
  }) {
    final lease = _state.ghostItemLease;
    if (lease == null) return;

    final ghostItem = _ghostLeasedItem(_state.player);
    if (ghostItem == null) {
      _state = _state.copyWith(ghostItemLease: null);
      notifyListeners();
      unawaited(_persistCurrentRun(trigger: 'ghostItemLeaseMissing'));
      return;
    }

    final price = const PathEventService().tintoreriaFantasmaPriceFor(
      ghostItem,
    );
    final updatedPlayer = keepItem && _state.player.canAfford(price)
        ? _state.player.spendMoney(price).replaceOwnedItem(
              currentItem: ghostItem,
              replacementItem: ghostItem.copyWith(isGhostly: false),
            )
        : _state.player.removeItem(ghostItem);

    _state = _state.copyWith(
      player: updatedPlayer,
      ghostItemLease: null,
    );
    notifyListeners();
    unawaited(_persistCurrentRun(trigger: 'ghostItemLeaseResolved'));
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
    GhostItemLease? ghostItemLease,
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
        ghostItemLease: null,
        shownShopNodeIds: const <String>[],
        shownEventNodeIds: const <String>[],
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
        ghostItemLease: null,
        shownShopNodeIds: const <String>[],
        shownEventNodeIds: const <String>[],
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
        ghostItemLease: ghostItemLease ?? _state.ghostItemLease,
        shownShopNodeIds: const <String>[],
        shownEventNodeIds: const <String>[],
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
      shownEventNodeIds: nextRunStep.shownEventNodeIds,
      shopRarityDayOffset: activeShopRarityDayOffset,
      eventRarityDayOffset: activeEventRarityDayOffset,
      ghostItemLease: ghostItemLease ?? _state.ghostItemLease,
    );
    _isResolvingNode = false;
    _activeNode = null;
    notifyListeners();
    unawaited(_persistCurrentRun(trigger: 'exitNode'));
  }

  GhostItemLease? _advanceGhostItemLeaseAfterCombat(Battler player) {
    final lease = _state.ghostItemLease;
    if (lease == null) return null;
    if (_ghostLeasedItem(player) == null) return null;

    return lease.afterCombat();
  }

  Item? _ghostLeasedItem(Battler player) {
    final lease = _state.ghostItemLease;
    if (lease == null) return null;

    final item = player.ownedItemByInstanceId(lease.itemInstanceId);
    if (item == null || !item.isGhostly) return null;
    return item;
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
    final nextPlayer = player;
    var nextHour = _pathNodeService.buildHourSnapshot(
      stageIndex: stageIndex,
      player: nextPlayer,
      availableNodes:
          _scriptedNodesForStage(stageIndex) ?? _availableNodesOverride,
      shownShopNodeIds: _state.shownShopNodeIds,
      shownEventNodeIds: _state.shownEventNodeIds,
      includeHealingFreeValueNodes: !_isFullHealMode,
      nodeCount: _nodeCount,
      shopRarityDayOffset: activeShopRarityDayOffset,
      eventRarityDayOffset: activeEventRarityDayOffset,
    );
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
      shownEventNodeIds: _updatedShownEventNodeIds(
        previousShownEventNodeIds: _state.shownEventNodeIds,
        hour: nextHour,
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

  bool _isFinalBossNode(CombatPathNode node) {
    return PathNodeService.isFinalBossStage(_state.stageIndex) &&
        node.nodeId == yellowCombatNode.nodeId;
  }

  Battler _healPlayerToFull(Battler player) {
    return player.copyWith(health: player.maxHealth);
  }

  /// Convierte el resultado bruto del combate en un cierre de run forzado cuando procede.
  RunCompletionType? _completionTypeForBattleResult(
    BattleFlowResultType resultType,
  ) {
    switch (resultType) {
      case BattleFlowResultType.victory:
        return null;
      case BattleFlowResultType.defeat:
        return _isFullHealMode ? null : RunCompletionType.defeat;
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
    if (!_isFullHealMode && updatedPlayer.isDefeated) {
      return RunCompletionType.defeat;
    }

    return null;
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

    final previousShownSet = previousShownShopNodeIds.toSet();
    final updatedShownSet = Set<String>.from(previousShownSet);
    updatedShownSet.addAll(visibleShopNodeIds);

    return List<String>.unmodifiable(updatedShownSet);
  }

  List<String> _updatedShownEventNodeIds({
    required List<String> previousShownEventNodeIds,
    required RunHourSnapshot hour,
  }) {
    final visibleEventNodeIds = hour.nodes
        .whereType<EventPathNode>()
        .where((node) => !freeValuePathEventIds.contains(node.id))
        .map((node) => node.nodeId)
        .toList(growable: false);
    if (visibleEventNodeIds.isEmpty) {
      return previousShownEventNodeIds;
    }

    return List<String>.unmodifiable({
      ...previousShownEventNodeIds,
      ...visibleEventNodeIds,
    });
  }

  Future<void> _persistCurrentRun({
    required String trigger,
    PathNode? activeNodeOverride,
  }) {
    if (!_persistRun) return Future<void>.value();

    return _snapshotRepository.save(
      RunSnapshotWriteRequest(
        state: _state,
        randomizer: _randomizer,
        isResolvingNode: _isResolvingNode,
        trigger: trigger,
        nodeCount: _nodeCount,
        activeNode: activeNodeOverride ?? _activeNode,
      ),
    );
  }

  Future<void> clearPersistedRunSnapshot() {
    if (!_persistRun) return Future<void>.value();

    return _snapshotRepository.clear();
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
  final List<String> shownEventNodeIds;

  const _RunStep({
    required this.player,
    required this.hour,
    required this.shownShopNodeIds,
    required this.shownEventNodeIds,
  });
}
