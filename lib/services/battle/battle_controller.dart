import '_imports.dart';

class BattleController extends ChangeNotifier {
  static const int patternBanHistoryCount = 1;
  final BattleResolver _resolver;
  final BattleTurnEngine _turnEngine;
  final BattlerEffectPipeline _effectPipeline;
  final BattlePurgeService _purgeService;
  final BattleEnemyAiService _enemyAi;
  final RunRandomizer _randomizer;
  final BattleTurnCoordinator _turnCoordinator;
  final BattleActionHandlers _actionHandlers;
  final BattleActionIntentProducer _actionIntentProducer;
  final BattleCombatStateReducer _stateReducer;
  final BattleAnimationCueProducer _animationCueProducer;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final BattleCombatAnimationCallback? onCombatAnimation;

  Battler _enemy;
  Battler _player;
  EnemyTurnAction _enemyNextAction = EnemyTurnAction.attack;
  String? _resultText;
  BattleFlowResult? _pendingExitResult;
  int _playerBlockUseCount = 0;
  final List<_BattleUsedPattern> _playerUsedPatterns = <_BattleUsedPattern>[];
  final List<_BattleUsedPattern> _enemyUsedPatterns = <_BattleUsedPattern>[];
  late final int _playerInitialBlockBarrier;
  late final int _enemyInitialBlockBarrier;
  bool _isDisposed = false;

  Timer? _enemyTurnTimer;
  Timer? _combatExitTimer;

  BattleController({
    required Battler enemy,
    required Battler player,
    required RunHourPhase phase,
    required int enemyTier,
    required this.enemyTurnDelay,
    required this.combatEndDelay,
    RunRandomizer? randomizer,
    BattlerEffectPipeline effectPipeline = const BattlerEffectPipeline(),
    BattleResolver resolver = const BattleResolver(),
    BattleTurnEngine turnEngine = const BattleTurnEngine(),
    BattlePurgeService purgeService = const BattlePurgeService(),
    BattleEnemyAiService? enemyAi,
    BattleTurnCoordinator? turnCoordinator,
    BattleActionHandlers? actionHandlers,
    BattleActionIntentProducer actionIntentProducer =
        const BattleActionIntentProducer(),
    BattleCombatStateReducer stateReducer = const BattleCombatStateReducer(),
    BattleAnimationCueProducer animationCueProducer =
        const BattleAnimationCueProducer(),
    this.onCombatAnimation,
  })  : _enemy = enemy.prepareForCombat(
          phase: phase,
        ),
        _player = player.prepareForCombat(
          phase: phase,
        ),
        _resolver = resolver,
        _effectPipeline = effectPipeline,
        _purgeService = purgeService,
        _randomizer = randomizer ?? RunRandomizer(),
        _enemyAi = enemyAi ?? BattleEnemyAiService.forEnemyTier(enemyTier),
        _turnCoordinator = turnCoordinator ?? BattleTurnCoordinator(),
        _actionHandlers =
            actionHandlers ?? BattleActionHandlers(stateReducer: stateReducer),
        _actionIntentProducer = actionIntentProducer,
        _stateReducer = stateReducer,
        _animationCueProducer = animationCueProducer,
        _turnEngine = turnEngine {
    final playerItemCombatStart =
        _effectPipeline.applyEquippedItemCombatStartEffects(
      owner: _player,
      opponent: _enemy,
      randomizer: _randomizer,
    );
    _player = playerItemCombatStart.owner;
    _enemy = playerItemCombatStart.opponent;

    final enemyItemCombatStart =
        _effectPipeline.applyEquippedItemCombatStartEffects(
      owner: _enemy,
      opponent: _player,
      randomizer: _randomizer,
    );
    _enemy = enemyItemCombatStart.owner;
    _player = enemyItemCombatStart.opponent;

    _playerInitialBlockBarrier = max(0, _player.maxBarrier);
    _enemyInitialBlockBarrier = max(0, _enemy.maxBarrier);
    _syncCombatRoundFlags();
    _enemyNextAction = _rollEnemyTurnAction();
    _beginTurnWithoutAnimation(BattleTurnState.player, notify: false);
  }

  Battler get enemy => _enemy;
  Battler get player => _player;
  BattleTurnState get _turn => _turnCoordinator.turn;
  set _turn(BattleTurnState value) {
    if (value == BattleTurnState.finished) {
      _turnCoordinator.finish();
    } else {
      _turnCoordinator.begin(value);
    }
  }

  int get _currentRound => _turnCoordinator.currentRound;
  BattleTurnState get turn => _turn;
  bool get isPlayerTurn => _turn == BattleTurnState.player;
  bool get isEnemyTurn => _turn == BattleTurnState.enemy;
  bool get isCombatFinished => _turn == BattleTurnState.finished;
  bool get canUseActions => isPlayerTurn && !isCombatFinished;
  bool get canResolveEnemyPattern => isEnemyTurn && !isCombatFinished;
  int get currentRound => _currentRound;
  List<List<String>> get playerBannedPatternPointKeys =>
      _activeBannedPatternPointKeys(_playerUsedPatterns);
  List<List<String>> get enemyBannedPatternPointKeys =>
      _activeBannedPatternPointKeys(_enemyUsedPatterns);
  int get currentPurgeDamageAmount => _purgeService.damageForRound(
        round: max(purgeStartRound, _currentRound),
        doctrine: _player.purgeDoctrine,
      );
  int get purgeStartRound =>
      _purgeService.configFor(_player.purgeDoctrine).startRound;
  int get purgeWarningRound =>
      _purgeService.configFor(_player.purgeDoctrine).warningRound;
  bool get isPurgeWarningVisible => _currentRound >= purgeWarningRound;
  bool get isPurgeActive => _currentRound >= purgeStartRound;
  int get playerPurgeDamagePreview => _purgeService.damageForBattler(
        battler: _player,
        round: max(purgeStartRound, _currentRound),
        doctrine: _player.purgeDoctrine,
      );
  int get enemyPurgeDamagePreview => _purgeService.damageForBattler(
        battler: _enemy,
        round: max(purgeStartRound, _currentRound),
        doctrine: _player.purgeDoctrine,
      );
  int get playerBlockBarrierGain => _playerCurrentBlockBarrierGain();
  int get playerInitialBarrier => _playerInitialBlockBarrier;
  EnemyTurnIntentPreview get enemyTurnIntentPreview =>
      _buildEnemyTurnIntentPreview();
  PlayerActionIntentPreview get playerActionIntentPreview =>
      _buildPlayerActionIntentPreview();

  void replacePlayer(Battler player) {
    if (identical(_player, player)) return;

    _player = player;
    notifyListeners();
  }

  void replaceEnemy(Battler enemy) {
    if (identical(_enemy, enemy)) return;

    _enemy = enemy;
    notifyListeners();
  }

  String get turnTitle {
    return BattleTurnPresentationService.titleFor(_turn);
  }

  String get turnDescription {
    return BattleTurnPresentationService.descriptionFor(
      turn: _turn,
      resultText: _resultText,
    );
  }

  BattleFlowResult? consumePendingExitResult() {
    final pendingExitResult = _pendingExitResult;
    _pendingExitResult = null;
    return pendingExitResult;
  }

  Future<void> handleAttack({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
  }) async {
    if (!canUseActions) return;
    var resolvedActionBonus = actionBonus;

    if (resolvedActionBonus.healAmount > 0) {
      await _applyPlayerHealing(resolvedActionBonus.healAmount);
    }

    final attackerBefore = _player;
    final defenderBefore = _enemy;
    final resolution = _resolveAttackAction(
      attacker: _player,
      defender: _enemy,
      flatAttackBonus: resolvedActionBonus.attackBonus,
    );

    await _playAttackActionAnimations(
      attackerSide: BattleCombatantSide.player,
      attackerBefore: attackerBefore,
      defenderBefore: defenderBefore,
      resolution: resolution,
    );
    if (_isDisposed || !canUseActions) return;

    _player = resolution.attacker;
    _enemy = resolution.defender;
    if (resolvedActionBonus.immediateBarrierAmount > 0) {
      await _applyActionBarrierToPlayer(
        resolvedActionBonus.immediateBarrierAmount,
      );
      if (_isDisposed) return;
    }

    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.player)) {
      return;
    }

    if (resolvedActionBonus.endTurnBarrierAmount > 0) {
      await _applyActionBarrierToPlayer(
        resolvedActionBonus.endTurnBarrierAmount,
      );
    }

    await _beginTurn(BattleTurnState.enemy);
    if (_turn == BattleTurnState.enemy) {
      _scheduleEnemyTurn();
    }
  }

  Future<void> handlePatternMatch({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
    BattlePatternMatchContext? patternContext,
    bool scheduleEnemyTurn = true,
  }) async {
    if (!canUseActions) return;
    if (patternContext != null) {
      if (_isPatternBanned(_playerUsedPatterns, patternContext.patternPoints)) {
        return;
      }
      _recordUsedPattern(_playerUsedPatterns, patternContext.patternPoints);
    }
    final resolvedActionBonus = actionBonus;
    var patternAttackModifier = resolvedActionBonus.attackBonus;
    var patternBlockModifier = resolvedActionBonus.immediateBarrierAmount;
    final patternHealModifier = resolvedActionBonus.healAmount;

    final resolvedPatternContext =
        patternContext?.withRandomSource(_randomizer);
    if (resolvedPatternContext != null) {
      _player = _player.applyAugmentPatternWeaponBoost(
        pattern: resolvedPatternContext,
      );

      final playerBeforePreAttackItems = _player;
      final enemyBeforePreAttackItems = _enemy;
      final preAttackItemResolution =
          _player.applyEquippedItemPrePatternAttackEffects(
        opponent: _enemy,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforePreAttackItems,
        enemyBefore: enemyBeforePreAttackItems,
        playerAfter: preAttackItemResolution.owner,
        enemyAfter: preAttackItemResolution.opponent,
      );
      if (_isDisposed || !canUseActions) return;

      _player = preAttackItemResolution.owner;
      _enemy = preAttackItemResolution.opponent;
      patternAttackModifier += preAttackItemResolution.attackBonusDelta;
      patternBlockModifier += preAttackItemResolution.barrierBonusDelta;
      final preAttackItemFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (preAttackItemFinish != null) {
        _finishCombat(
          resultType: preAttackItemFinish.resultType,
          resultText: preAttackItemFinish.resultText,
        );
        return;
      }

      final playerBeforePatternUsedItems = _player;
      final enemyBeforePatternUsedItems = _enemy;
      final patternUsedItemResolution =
          _player.applyEquippedItemPatternUsedEffects(
        opponent: _enemy,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforePatternUsedItems,
        enemyBefore: enemyBeforePatternUsedItems,
        playerAfter: patternUsedItemResolution.owner,
        enemyAfter: patternUsedItemResolution.opponent,
      );
      if (_isDisposed || !canUseActions) return;

      _player = patternUsedItemResolution.owner;
      _enemy = patternUsedItemResolution.opponent;
      patternAttackModifier += patternUsedItemResolution.attackBonusDelta;
      patternBlockModifier += patternUsedItemResolution.barrierBonusDelta;
      final patternUsedItemFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (patternUsedItemFinish != null) {
        _finishCombat(
          resultType: patternUsedItemFinish.resultType,
          resultText: patternUsedItemFinish.resultText,
        );
        return;
      }
    }

    if (resolvedPatternContext != null) {
      final didFinish = await _resolvePlayerPatternItemActions(
        pattern: resolvedPatternContext,
        attackModifier: patternAttackModifier,
        blockModifier: patternBlockModifier,
        healModifier: patternHealModifier,
      );
      if (didFinish || _isDisposed || !canUseActions) return;
    }

    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.player)) {
      return;
    }

    if (resolvedActionBonus.endTurnBarrierAmount > 0) {
      await _applyActionBarrierToPlayer(
        resolvedActionBonus.endTurnBarrierAmount,
      );
    }

    await _beginTurn(BattleTurnState.enemy);
    if (scheduleEnemyTurn && _turn == BattleTurnState.enemy) {
      _scheduleEnemyTurn();
    }
  }

  Future<bool> _resolvePlayerPatternItemActions({
    required BattlePatternMatchContext pattern,
    required int attackModifier,
    required int blockModifier,
    required int healModifier,
  }) async {
    final resolvedActions = <ActionEffect>[];
    for (final pointKey in pattern.usedItemPointKeys) {
      final item = _itemAtPatternPoint(owner: _player, pointKey: pointKey);
      if (item == null) continue;
      final boostedItem = _player.itemWithCombatActionBonuses(item);
      final actions = _actionsForPatternItemUse(
        item: boostedItem,
        pattern: pattern,
        pointKey: pointKey,
      );
      var didResolveAction = false;
      final pendingActions = <({
        ActionEffect action,
        Item item,
        bool allowFollowUps,
      })>[
        for (final action in actions)
          (action: action, item: item, allowFollowUps: true),
      ];

      while (pendingActions.isNotEmpty) {
        final pendingAction = pendingActions.removeAt(0);
        final action = _actionWithItemActionScaling(
          owner: _player,
          action: pendingAction.action,
        );
        didResolveAction = true;
        _player = _player.recordResolvedItemAction(action);
        switch (action.actionType) {
          case ItemActionType.attack:
            final attackerBefore = _player;
            final defenderBefore = _enemy;
            final attackResolution = _resolveAttackAction(
              attacker: _player,
              defender: _enemy,
              baseDamageOverride: max(
                0,
                action.totalValue + attackModifier,
              ),
              sourceItem: pendingAction.item,
            );
            await _playAttackActionAnimations(
              attackerSide: BattleCombatantSide.player,
              attackerBefore: attackerBefore,
              defenderBefore: defenderBefore,
              resolution: attackResolution,
            );
            if (_isDisposed || !canUseActions) return true;
            _player = attackResolution.attacker;
            _enemy = attackResolution.defender;
            if (pendingAction.allowFollowUps &&
                attackResolution.followUpItemActions.isNotEmpty) {
              pendingActions.insertAll(0, <({
                ActionEffect action,
                Item item,
                bool allowFollowUps,
              })>[
                for (final followUp in attackResolution.followUpItemActions)
                  (
                    action: followUp.action,
                    item: followUp.item,
                    allowFollowUps: false,
                  ),
              ]);
            }
            break;
          case ItemActionType.block:
            final playerBefore = _player;
            final enemyBefore = _enemy;
            _player = _applyBarrierGain(
              _player,
              max(0, action.totalValue + blockModifier),
            );
            await _playBlockResolutionAnimation(
              defenderSide: BattleCombatantSide.player,
              defenderBefore: playerBefore,
              opponentBefore: enemyBefore,
              defenderAfter: _player,
              opponentAfter: _enemy,
            );
            if (_isDisposed || !canUseActions) return true;
            break;
          case ItemActionType.heal:
            final playerBefore = _player;
            final enemyBefore = _enemy;
            _player = _player.heal(action.totalValue + healModifier);
            await _playHealingActionAnimation(
              healerSide: BattleCombatantSide.player,
              healerBefore: playerBefore,
              opponentBefore: enemyBefore,
              healerAfter: _player,
              opponentAfter: _enemy,
            );
            if (_isDisposed || !canUseActions) return true;
            break;
          case ItemActionType.none:
            final resolution = ItemEffectDispatcher.resolveCustomAction(
              owner: _player,
              opponent: _enemy,
              item: pendingAction.item,
              effect: action,
              pattern: pattern,
              previousActions: List<ActionEffect>.unmodifiable(resolvedActions),
            );
            _player = resolution.owner;
            _enemy = resolution.opponent;
            if (pendingAction.allowFollowUps &&
                (resolution.followUpActions.isNotEmpty ||
                    resolution.followUpItemActions.isNotEmpty)) {
              pendingActions.insertAll(0, <({
                ActionEffect action,
                Item item,
                bool allowFollowUps,
              })>[
                for (final followUp in resolution.followUpItemActions)
                  (
                    action: followUp.action,
                    item: followUp.item,
                    allowFollowUps: false,
                  ),
                for (final followUp in resolution.followUpActions)
                  (
                    action: followUp,
                    item: pendingAction.item,
                    allowFollowUps: false,
                  ),
              ]);
            }
            break;
        }
        final actionResolvedItemResolution =
            _applyPlayerItemActionResolvedEffects(
          action: action,
          item: pendingAction.item,
          pattern: pattern,
        );
        _player = actionResolvedItemResolution.owner;
        _enemy = actionResolvedItemResolution.opponent;
        if (pendingAction.allowFollowUps &&
            (actionResolvedItemResolution.followUpActions.isNotEmpty ||
                actionResolvedItemResolution.followUpItemActions.isNotEmpty)) {
          pendingActions.insertAll(0, <({
            ActionEffect action,
            Item item,
            bool allowFollowUps,
          })>[
            for (final followUp
                in actionResolvedItemResolution.followUpItemActions)
              (
                action: followUp.action,
                item: followUp.item,
                allowFollowUps: false,
              ),
            for (final followUp in actionResolvedItemResolution.followUpActions)
              (
                action: followUp,
                item: pendingAction.item,
                allowFollowUps: false,
              ),
          ]);
        }
        resolvedActions.add(action);
      }

      if (!didResolveAction) continue;
      final finish = _turnEngine.finishFor(player: _player, enemy: _enemy);
      if (finish != null) {
        _finishCombat(
          resultType: finish.resultType,
          resultText: finish.resultText,
        );
        return true;
      }
    }

    return false;
  }

  ActionEffect _actionWithItemActionScaling({
    required Battler owner,
    required ActionEffect action,
  }) {
    if (action.actionType == ItemActionType.none) {
      return action;
    }

    var updatedAction = action;
    for (final item in owner.equippedItemsForHook(
      ItemEffectHook.actionResolved,
    )) {
      for (final effect in item.passiveEffects.where(
        (effect) =>
            effect.effectKey == ItemEffectKeys.goldenGodfatherRichScaling,
      )) {
        updatedAction = updatedAction.withBonusSource(
          sourceKey: _itemActionScalingSourceKey(item, effect),
          bonusValue: effect.value * (owner.money ~/ 10),
        );
      }
    }

    if (owner.itemActionResolvedCountThisTurn < 4) {
      return updatedAction;
    }

    for (final item in owner.equippedItemsForHook(
      ItemEffectHook.actionResolved,
    )) {
      for (final effect in item.passiveEffects.where(
        (effect) =>
            effect.effectKey == ItemEffectKeys.thousandCutHaloActionScaling,
      )) {
        updatedAction = updatedAction.withBonusSource(
          sourceKey: _itemActionScalingSourceKey(item, effect),
          bonusValue: effect.value,
        );
      }
    }
    return updatedAction;
  }

  String _itemActionScalingSourceKey(Item item, PassiveEffect effect) {
    return '${effect.effectKey}:${item.instanceId ?? item.catalogKey}';
  }

  ItemEffectResolution _applyPlayerItemActionResolvedEffects({
    required ActionEffect action,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return _player.applyEquippedItemActionResolvedEffects(
      target: _enemy,
      action: action,
      sourceItem: item,
      pattern: pattern,
    );
  }

  ItemEffectResolution _applyEnemyItemActionResolvedEffects({
    required ActionEffect action,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return _enemy.applyEquippedItemActionResolvedEffects(
      target: _player,
      action: action,
      sourceItem: item,
      pattern: pattern,
    );
  }

  Item? _itemAtPatternPoint({
    required Battler owner,
    required String pointKey,
  }) {
    for (final item in owner.equippedItems) {
      if (OperativePatternLayoutService.pointKeyForItem(
            player: owner,
            item: item,
          ) ==
          pointKey) {
        return item;
      }
    }
    return null;
  }

  List<ActionEffect> _actionsForPatternItemUse({
    required Item item,
    required BattlePatternMatchContext pattern,
    required String pointKey,
  }) {
    OperativePatternPoint? itemPoint;
    for (final point in pattern.patternPoints) {
      if (point.key != pointKey) continue;
      itemPoint = point;
      break;
    }

    return List<ActionEffect>.unmodifiable([
      ...item.actionEffects,
      if (itemPoint != null)
        ...item
            .matchingPatternEffects(
              patternPoints: pattern.patternPoints,
              itemPoint: itemPoint,
            )
            .map((effect) => effect.actionEffect),
    ]);
  }

  Future<void> handleEnemyPatternMatch({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
    BattlePatternMatchContext? patternContext,
  }) async {
    if (!canResolveEnemyPattern) return;
    patternContext = patternContext?.withRandomSource(_randomizer);
    if (patternContext != null) {
      if (_isPatternBanned(_enemyUsedPatterns, patternContext.patternPoints)) {
        return;
      }
      _recordUsedPattern(_enemyUsedPatterns, patternContext.patternPoints);
    }

    final resolvedActionBonus = actionBonus;
    var patternAttackModifier = resolvedActionBonus.attackBonus;
    var patternBlockModifier = resolvedActionBonus.immediateBarrierAmount;
    final patternHealModifier = resolvedActionBonus.healAmount;
    final resolvedPatternContext = patternContext;

    final preAttackPlayerBefore = _player;
    final preAttackEnemyBefore = _enemy;
    final preAttackResolution = _resolveEnemyPreAttackState(
      enemy: _enemy,
      player: _player,
    );
    await _playCombatStateTransitionAnimations(
      playerBefore: preAttackPlayerBefore,
      enemyBefore: preAttackEnemyBefore,
      playerAfter: preAttackResolution.player,
      enemyAfter: preAttackResolution.enemy,
    );
    if (_isDisposed || _turn != BattleTurnState.enemy) return;
    _enemy = preAttackResolution.enemy;
    _player = preAttackResolution.player;
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    final preAttackFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (preAttackFinish != null) {
      _finishCombat(
        resultType: preAttackFinish.resultType,
        resultText: preAttackFinish.resultText,
      );
      return;
    }

    if (resolvedPatternContext != null) {
      _enemy = _enemy.applyAugmentPatternWeaponBoost(
        pattern: resolvedPatternContext,
      );

      final enemyBeforePreAttackItems = _enemy;
      final playerBeforePreAttackItems = _player;
      final preAttackItemResolution =
          _enemy.applyEquippedItemPrePatternAttackEffects(
        opponent: _player,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforePreAttackItems,
        enemyBefore: enemyBeforePreAttackItems,
        playerAfter: preAttackItemResolution.opponent,
        enemyAfter: preAttackItemResolution.owner,
      );
      if (_isDisposed || _turn != BattleTurnState.enemy) return;

      _enemy = preAttackItemResolution.owner;
      _player = preAttackItemResolution.opponent;
      patternAttackModifier += preAttackItemResolution.attackBonusDelta;
      patternBlockModifier += preAttackItemResolution.barrierBonusDelta;
      final preAttackItemFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (preAttackItemFinish != null) {
        _finishCombat(
          resultType: preAttackItemFinish.resultType,
          resultText: preAttackItemFinish.resultText,
        );
        return;
      }

      final enemyBeforePatternUsedItems = _enemy;
      final playerBeforePatternUsedItems = _player;
      final patternUsedItemResolution =
          _enemy.applyEquippedItemPatternUsedEffects(
        opponent: _player,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforePatternUsedItems,
        enemyBefore: enemyBeforePatternUsedItems,
        playerAfter: patternUsedItemResolution.opponent,
        enemyAfter: patternUsedItemResolution.owner,
      );
      if (_isDisposed || _turn != BattleTurnState.enemy) return;

      _enemy = patternUsedItemResolution.owner;
      _player = patternUsedItemResolution.opponent;
      patternAttackModifier += patternUsedItemResolution.attackBonusDelta;
      patternBlockModifier += patternUsedItemResolution.barrierBonusDelta;
      final patternUsedItemFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (patternUsedItemFinish != null) {
        _finishCombat(
          resultType: patternUsedItemFinish.resultType,
          resultText: patternUsedItemFinish.resultText,
        );
        return;
      }
    }

    if (resolvedPatternContext != null) {
      final didFinish = await _resolveEnemyPatternItemActions(
        pattern: resolvedPatternContext,
        attackModifier: patternAttackModifier,
        blockModifier: patternBlockModifier,
        healModifier: patternHealModifier,
      );
      if (didFinish || _isDisposed || _turn != BattleTurnState.enemy) return;
    }

    _enemyAi.registerResolvedAction(EnemyTurnAction.attack);
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.enemy)) {
      return;
    }

    _enemyNextAction = _rollEnemyTurnAction();
    await _beginTurn(BattleTurnState.player);
  }

  Future<bool> _resolveEnemyPatternItemActions({
    required BattlePatternMatchContext pattern,
    required int attackModifier,
    required int blockModifier,
    required int healModifier,
  }) async {
    final resolvedActions = <ActionEffect>[];
    for (final pointKey in pattern.usedItemPointKeys) {
      final item = _itemAtPatternPoint(owner: _enemy, pointKey: pointKey);
      if (item == null) continue;
      final boostedItem = _enemy.itemWithCombatActionBonuses(item);
      final actions = _actionsForPatternItemUse(
        item: boostedItem,
        pattern: pattern,
        pointKey: pointKey,
      );
      var didResolveAction = false;
      final pendingActions = <({
        ActionEffect action,
        Item item,
        bool allowFollowUps,
      })>[
        for (final action in actions)
          (action: action, item: item, allowFollowUps: true),
      ];

      while (pendingActions.isNotEmpty) {
        final pendingAction = pendingActions.removeAt(0);
        final action = _actionWithItemActionScaling(
          owner: _enemy,
          action: pendingAction.action,
        );
        didResolveAction = true;
        _enemy = _enemy.recordResolvedItemAction(action);
        switch (action.actionType) {
          case ItemActionType.attack:
            final enemyBefore = _enemy;
            final playerBefore = _player;
            final attackResolution = _resolveAttackAction(
              attacker: _enemy,
              defender: _player,
              baseDamageOverride: max(
                0,
                action.totalValue + attackModifier,
              ),
              sourceItem: pendingAction.item,
            );
            await _playAttackActionAnimations(
              attackerSide: BattleCombatantSide.enemy,
              attackerBefore: enemyBefore,
              defenderBefore: playerBefore,
              resolution: attackResolution,
            );
            if (_isDisposed || _turn != BattleTurnState.enemy) return true;
            _enemy = attackResolution.attacker;
            _player = attackResolution.defender;
            if (pendingAction.allowFollowUps &&
                attackResolution.followUpItemActions.isNotEmpty) {
              pendingActions.insertAll(0, <({
                ActionEffect action,
                Item item,
                bool allowFollowUps,
              })>[
                for (final followUp in attackResolution.followUpItemActions)
                  (
                    action: followUp.action,
                    item: followUp.item,
                    allowFollowUps: false,
                  ),
              ]);
            }
            break;
          case ItemActionType.block:
            final enemyBefore = _enemy;
            final playerBefore = _player;
            _enemy = _applyBarrierGain(
              _enemy,
              max(0, action.totalValue + blockModifier),
            );
            await _playBlockResolutionAnimation(
              defenderSide: BattleCombatantSide.enemy,
              defenderBefore: enemyBefore,
              opponentBefore: playerBefore,
              defenderAfter: _enemy,
              opponentAfter: _player,
            );
            if (_isDisposed || _turn != BattleTurnState.enemy) return true;
            break;
          case ItemActionType.heal:
            final enemyBefore = _enemy;
            final playerBefore = _player;
            _enemy = _enemy.heal(action.totalValue + healModifier);
            await _playHealingActionAnimation(
              healerSide: BattleCombatantSide.enemy,
              healerBefore: enemyBefore,
              opponentBefore: playerBefore,
              healerAfter: _enemy,
              opponentAfter: _player,
            );
            if (_isDisposed || _turn != BattleTurnState.enemy) return true;
            break;
          case ItemActionType.none:
            final resolution = ItemEffectDispatcher.resolveCustomAction(
              owner: _enemy,
              opponent: _player,
              item: pendingAction.item,
              effect: action,
              pattern: pattern,
              previousActions: List<ActionEffect>.unmodifiable(resolvedActions),
            );
            _enemy = resolution.owner;
            _player = resolution.opponent;
            if (pendingAction.allowFollowUps &&
                (resolution.followUpActions.isNotEmpty ||
                    resolution.followUpItemActions.isNotEmpty)) {
              pendingActions.insertAll(0, <({
                ActionEffect action,
                Item item,
                bool allowFollowUps,
              })>[
                for (final followUp in resolution.followUpItemActions)
                  (
                    action: followUp.action,
                    item: followUp.item,
                    allowFollowUps: false,
                  ),
                for (final followUp in resolution.followUpActions)
                  (
                    action: followUp,
                    item: pendingAction.item,
                    allowFollowUps: false,
                  ),
              ]);
            }
            break;
        }
        final actionResolvedItemResolution =
            _applyEnemyItemActionResolvedEffects(
          action: action,
          item: pendingAction.item,
          pattern: pattern,
        );
        _enemy = actionResolvedItemResolution.owner;
        _player = actionResolvedItemResolution.opponent;
        if (pendingAction.allowFollowUps &&
            (actionResolvedItemResolution.followUpActions.isNotEmpty ||
                actionResolvedItemResolution.followUpItemActions.isNotEmpty)) {
          pendingActions.insertAll(0, <({
            ActionEffect action,
            Item item,
            bool allowFollowUps,
          })>[
            for (final followUp
                in actionResolvedItemResolution.followUpItemActions)
              (
                action: followUp.action,
                item: followUp.item,
                allowFollowUps: false,
              ),
            for (final followUp in actionResolvedItemResolution.followUpActions)
              (
                action: followUp,
                item: pendingAction.item,
                allowFollowUps: false,
              ),
          ]);
        }
        resolvedActions.add(action);
      }

      if (!didResolveAction) continue;
      final finish = _turnEngine.finishFor(player: _player, enemy: _enemy);
      if (finish != null) {
        _finishCombat(
          resultType: finish.resultType,
          resultText: finish.resultText,
        );
        return true;
      }
    }

    return false;
  }

  List<List<String>> _activeBannedPatternPointKeys(
    List<_BattleUsedPattern> history,
  ) {
    if (history.length > patternBanHistoryCount) {
      history.removeRange(0, history.length - patternBanHistoryCount);
    }
    return List<List<String>>.unmodifiable(
      history.map((entry) => entry.pointKeys),
    );
  }

  bool _isPatternBanned(
    List<_BattleUsedPattern> history,
    List<OperativePatternPoint> patternPoints,
  ) {
    final pointKeys = patternPoints.map((point) => point.key).toList();
    return _activeBannedPatternPointKeys(history).any(
      (banned) => _sameOrderedPointKeys(banned, pointKeys),
    );
  }

  void _recordUsedPattern(
    List<_BattleUsedPattern> history,
    List<OperativePatternPoint> patternPoints,
  ) {
    history.add(
      _BattleUsedPattern(
        pointKeys: List<String>.unmodifiable(
          patternPoints.map((point) => point.key),
        ),
        usedRound: _currentRound,
      ),
    );
  }

  bool _sameOrderedPointKeys(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  Future<void> handleBlock({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
  }) async {
    if (!canUseActions) return;
    final resolvedActionBonus = actionBonus;

    if (resolvedActionBonus.healAmount > 0) {
      await _applyPlayerHealing(resolvedActionBonus.healAmount);
    }

    if (resolvedActionBonus.attackBonus > 0) {
      _player = _player.applyStatus(
        PotenciaStatus(value: resolvedActionBonus.attackBonus),
        applyEquipmentModifiers: false,
      );
    }

    final baseBarrierGain = _playerCurrentBlockBarrierGain();
    _playerBlockUseCount++;
    final defenderBefore = _player;
    final opponentBefore = _enemy;
    final defendResolution = _resolveDefendAction(
      defender: _player,
      opponent: _enemy,
      barrierGain: baseBarrierGain,
    );
    await _playBlockResolutionAnimation(
      defenderSide: BattleCombatantSide.player,
      defenderBefore: defenderBefore,
      opponentBefore: opponentBefore,
      defenderAfter: defendResolution.defender,
      opponentAfter: defendResolution.opponent,
    );
    if (_isDisposed || !canUseActions) return;

    _player = defendResolution.defender;
    _enemy = defendResolution.opponent;

    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.player)) {
      return;
    }

    if (resolvedActionBonus.endTurnBarrierAmount > 0) {
      await _applyActionBarrierToPlayer(
        resolvedActionBonus.endTurnBarrierAmount,
      );
    }

    await _beginTurn(BattleTurnState.enemy);
    if (_turn == BattleTurnState.enemy) {
      _scheduleEnemyTurn();
    }
  }

  void handleRunAway() {
    if (isCombatFinished) return;

    _cancelTimers();
    _player = _player.finalizeCombatState();
    _enemy = _enemy.finalizeCombatState();
    _turn = BattleTurnState.finished;
    _resultText = 'Retirada confirmada.';
    _pendingExitResult = BattleFlowResult(
      type: BattleFlowResultType.retreated,
      player: _player,
    );
    notifyListeners();
  }

  void handleSystemBack() {
    if (isCombatFinished) return;
    handleRunAway();
  }

  void _scheduleEnemyTurn() {
    _enemyTurnTimer?.cancel();
    _enemyTurnTimer = Timer(enemyTurnDelay, () {
      unawaited(_resolveEnemyTurn());
    });
  }

  Future<void> _resolveEnemyTurn() async {
    if (_turn != BattleTurnState.enemy) return;

    final plannedAction = _enemyNextAction;
    final preAttackPlayerBefore = _player;
    final preAttackEnemyBefore = _enemy;
    final preAttackResolution = _resolveEnemyPreAttackState(
      enemy: _enemy,
      player: _player,
    );
    await _playCombatStateTransitionAnimations(
      playerBefore: preAttackPlayerBefore,
      enemyBefore: preAttackEnemyBefore,
      playerAfter: preAttackResolution.player,
      enemyAfter: preAttackResolution.enemy,
    );
    if (_isDisposed || _turn != BattleTurnState.enemy) return;
    _enemy = preAttackResolution.enemy;
    _player = preAttackResolution.player;
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }
    final preAttackFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (preAttackFinish != null) {
      _finishCombat(
        resultType: preAttackFinish.resultType,
        resultText: preAttackFinish.resultText,
      );
      return;
    }

    final enemyActionResolution = await _resolveEnemyActionWithAnimation(
      enemy: _enemy,
      player: _player,
      action: plannedAction,
    );
    if (_isDisposed || _turn != BattleTurnState.enemy) return;
    _enemy = enemyActionResolution.enemy;
    _player = enemyActionResolution.player;

    final itemUseEnemyBefore = _enemy;
    final itemUsePlayerBefore = _player;
    final itemUseResolution =
        _enemy.applyEquippedItemForcedPatternUsedEffects(opponent: _player);
    await _playCombatStateTransitionAnimations(
      playerBefore: itemUsePlayerBefore,
      enemyBefore: itemUseEnemyBefore,
      playerAfter: itemUseResolution.opponent,
      enemyAfter: itemUseResolution.owner,
    );
    if (_isDisposed || _turn != BattleTurnState.enemy) return;
    _enemy = itemUseResolution.owner;
    _player = itemUseResolution.opponent;

    _enemyAi.registerResolvedAction(plannedAction);
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.enemy)) {
      return;
    }

    _enemyNextAction = _rollEnemyTurnAction();
    await _beginTurn(BattleTurnState.player);
  }

  _EnemyPreAttackResolution _resolveEnemyPreAttackState({
    required Battler enemy,
    required Battler player,
  }) {
    return _EnemyPreAttackResolution(
      enemy: enemy,
      player: player,
    );
  }

  EnemyTurnIntentPreview _buildEnemyTurnIntentPreview() {
    if (_turn == BattleTurnState.finished ||
        _enemy.isDefeated ||
        _player.isDefeated) {
      return const EnemyTurnIntentPreview();
    }

    final initialEnemy = _enemy;
    final initialPlayer = _player;
    final plannedAction = _enemyNextAction;

    final preAttackResolution = _resolveEnemyPreAttackState(
      enemy: initialEnemy,
      player: initialPlayer,
    );

    var predictedEnemy = preAttackResolution.enemy;
    var predictedPlayer = preAttackResolution.player;
    _EnemyIntentAttackBreakdown? attackBreakdown;

    final shouldResolveAttack = _turnEngine.finishFor(
          player: predictedPlayer,
          enemy: predictedEnemy,
        ) ==
        null;
    if (shouldResolveAttack) {
      if (plannedAction == EnemyTurnAction.attack) {
        final attackResolution = _resolveAttackAction(
          attacker: predictedEnemy,
          defender: predictedPlayer,
        );
        attackBreakdown = _buildEnemyIntentAttackBreakdown(attackResolution);
        predictedEnemy = attackResolution.attacker;
        predictedPlayer = attackResolution.defender;
      } else {
        final actionResolution = _resolveEnemyAction(
          enemy: predictedEnemy,
          player: predictedPlayer,
          action: plannedAction,
        );
        predictedEnemy = actionResolution.enemy;
        predictedPlayer = actionResolution.player;
      }

      final itemUseResolution = predictedEnemy
          .applyEquippedItemForcedPatternUsedEffects(opponent: predictedPlayer);
      predictedEnemy = itemUseResolution.owner;
      predictedPlayer = itemUseResolution.opponent;
    }

    final damage = max(
        0,
        _actionIntentProducer.combatDurabilityOf(initialPlayer) -
            _actionIntentProducer.combatDurabilityOf(predictedPlayer));
    final barrierGain =
        max(0, predictedEnemy.currentBarrier - initialEnemy.currentBarrier);

    return EnemyTurnIntentPreview(
      action: plannedAction,
      damage: damage,
      attackHitDamage: attackBreakdown?.damagePerHit ?? damage,
      attackHitCount: attackBreakdown?.hitCount ?? 1,
      barrierGain: barrierGain,
      appliedDebuffs: _actionIntentProducer.appliedDebuffs(
        before: initialPlayer,
        after: predictedPlayer,
      ),
    );
  }

  PlayerActionIntentPreview _buildPlayerActionIntentPreview() {
    if (_turn == BattleTurnState.finished ||
        _enemy.isDefeated ||
        _player.isDefeated) {
      return const PlayerActionIntentPreview();
    }

    final attackResolution = _resolveAttackAction(
      attacker: _player,
      defender: _enemy,
    );
    final attackBreakdown = _buildAttackIntentBreakdown(attackResolution);
    final attackDamage = max(
      0,
      _actionIntentProducer.combatDurabilityOf(_enemy) -
          _actionIntentProducer.combatDurabilityOf(attackResolution.defender),
    );

    final defendResolution = _resolveDefendAction(
      defender: _player,
      opponent: _enemy,
      barrierGain: _playerCurrentBlockBarrierGain(),
    );
    final blockBarrierGain = max(
      0,
      defendResolution.defender.currentBarrier - _player.currentBarrier,
    );

    return PlayerActionIntentPreview(
      attackDamage: attackDamage,
      attackHitDamage: attackBreakdown.damagePerHit,
      attackHitCount: attackBreakdown.hitCount,
      blockBarrierGain: blockBarrierGain,
      attackEffects: _actionIntentProducer.playerActionEffects(
        ownerBefore: _player,
        ownerAfter: attackResolution.attacker,
        opponentBefore: _enemy,
        opponentAfter: attackResolution.defender,
      ),
      blockEffects: _actionIntentProducer.playerActionEffects(
        ownerBefore: _player,
        ownerAfter: defendResolution.defender,
        opponentBefore: _enemy,
        opponentAfter: defendResolution.opponent,
      ),
    );
  }

  _EnemyIntentAttackBreakdown _buildEnemyIntentAttackBreakdown(
    _BattleAttackActionResolution resolution,
  ) =>
      _buildAttackIntentBreakdown(resolution);

  _EnemyIntentAttackBreakdown _buildAttackIntentBreakdown(
    _BattleAttackActionResolution resolution,
  ) {
    final attackHits = resolution.hits
        .where(
          (hit) =>
              hit.primaryCombatant == _BattleAttackHitCombatant.attacker &&
              hit.motionAsset == BattleCombatMotionAsset.sword,
        )
        .toList(growable: false);
    if (attackHits.isEmpty) {
      return _EnemyIntentAttackBreakdown(
        damagePerHit: resolution.damageDealt,
        hitCount: 1,
      );
    }

    final firstDamage = attackHits.first.damageDealt;
    final hasUniformDamage = attackHits.every(
      (hit) => hit.damageDealt == firstDamage,
    );

    return _EnemyIntentAttackBreakdown(
      damagePerHit: hasUniformDamage
          ? firstDamage
          : attackHits.fold<int>(
              0,
              (total, hit) => total + hit.damageDealt,
            ),
      hitCount: hasUniformDamage ? attackHits.length : 1,
    );
  }

  _EnemyActionResolution _resolveEnemyAction({
    required Battler enemy,
    required Battler player,
    required EnemyTurnAction action,
  }) {
    if (action == EnemyTurnAction.defend) {
      final defendResolution = _resolveDefendAction(
        defender: enemy,
        opponent: player,
        barrierGain: _enemyInitialBlockBarrier,
      );
      return _EnemyActionResolution(
        enemy: defendResolution.defender,
        player: defendResolution.opponent,
      );
    }

    final attackResolution = _resolveAttackAction(
      attacker: enemy,
      defender: player,
    );
    return _EnemyActionResolution(
      enemy: attackResolution.attacker,
      player: attackResolution.defender,
    );
  }

  Future<_EnemyActionResolution> _resolveEnemyActionWithAnimation({
    required Battler enemy,
    required Battler player,
    required EnemyTurnAction action,
  }) async {
    if (action == EnemyTurnAction.defend) {
      final defendResolution = _resolveEnemyAction(
        enemy: enemy,
        player: player,
        action: action,
      );
      await _playBlockResolutionAnimation(
        defenderSide: BattleCombatantSide.enemy,
        defenderBefore: enemy,
        opponentBefore: player,
        defenderAfter: defendResolution.enemy,
        opponentAfter: defendResolution.player,
      );
      return defendResolution;
    }

    final attackResolution = _resolveAttackAction(
      attacker: enemy,
      defender: player,
    );
    await _playAttackActionAnimations(
      attackerSide: BattleCombatantSide.enemy,
      attackerBefore: enemy,
      defenderBefore: player,
      resolution: attackResolution,
    );

    return _EnemyActionResolution(
      enemy: attackResolution.attacker,
      player: attackResolution.defender,
    );
  }

  BattleDefendActionResolution _resolveDefendAction({
    required Battler defender,
    required Battler opponent,
    required int barrierGain,
  }) {
    return _actionHandlers.resolveDefend(
      defender: defender,
      opponent: opponent,
      barrierGain: barrierGain,
    );
  }

  _BattleAttackActionResolution _resolveAttackAction({
    required Battler attacker,
    required Battler defender,
    int flatAttackBonus = 0,
    int? baseDamageOverride,
    int challengeCounterattackBonus = 0,
    bool triggerAttackResolvedEffects = true,
    Item? sourceItem,
  }) {
    var updatedAttacker = attacker.removeCombatFlag(
      Battler.pendingBasicAttackFollowUpFlag,
    );
    var updatedDefender = defender;
    var totalDamageDealt = 0;
    final attackCount = attacker.basicAttackCount;
    final hits = <_BattleAttackHitResolution>[];
    final followUpItemActions = <ItemFollowUpAction>[];

    for (var attackIndex = 0; attackIndex < attackCount; attackIndex++) {
      if (updatedAttacker.isDefeated || updatedDefender.isDefeated) {
        break;
      }

      updatedAttacker = _applyPreAttackDesafioGains(updatedAttacker);

      final challengeBeforeAttacker = updatedAttacker;
      final challengeBeforeDefender = updatedDefender;
      final challengeConsumption = _consumeDesafioIfPresent(updatedAttacker);
      final consumedDesafioValue = challengeConsumption.value;
      var desafioCounterPrevented = challengeConsumption.preventsCounterattack;
      updatedAttacker = challengeConsumption.owner;

      if (consumedDesafioValue > 0) {
        final challengeResolution = _resolveDirectDamageOnly(
          source: updatedAttacker,
          target: updatedDefender,
          damage: consumedDesafioValue,
          barrierIgnore: _desafioBarrierIgnoreFor(updatedAttacker),
        );
        updatedAttacker = challengeResolution.source;
        updatedDefender = challengeResolution.target;
        totalDamageDealt += challengeResolution.damageDealt;
        final executionBellResolution = _applyExecutionBellAfterDesafioAttack(
          owner: updatedAttacker,
          target: updatedDefender,
        );
        updatedAttacker = executionBellResolution.owner;
        updatedDefender = executionBellResolution.target;
        hits.add(
          _BattleAttackHitResolution(
            primaryCombatant: _BattleAttackHitCombatant.attacker,
            motionAsset: BattleCombatMotionAsset.fist,
            attackerBefore: challengeBeforeAttacker.removeCombatFlag(
              Battler.pendingBasicAttackFollowUpFlag,
            ),
            defenderBefore: challengeBeforeDefender,
            attackerAfter: updatedAttacker,
            defenderAfter: updatedDefender,
            damageDealt: challengeResolution.damageDealt,
          ),
        );
      }

      if (consumedDesafioValue > 0 &&
          !desafioCounterPrevented &&
          !updatedAttacker.isDefeated &&
          !updatedDefender.isDefeated) {
        final counterDamage =
            max(0, consumedDesafioValue ~/ 2 + challengeCounterattackBonus);
        if (counterDamage > 0) {
          final counterBeforeAttacker = updatedAttacker;
          final counterBeforeDefender = updatedDefender;
          final counterResolution = _resolveDirectDamageOnly(
            source: updatedDefender,
            target: updatedAttacker,
            damage: counterDamage,
            kind: DamageKind.desafioCounter,
          );
          updatedDefender = counterResolution.source;
          updatedAttacker = counterResolution.target;
          hits.add(
            _BattleAttackHitResolution(
              primaryCombatant: _BattleAttackHitCombatant.defender,
              motionAsset: BattleCombatMotionAsset.fist,
              attackerBefore: counterBeforeAttacker,
              defenderBefore: counterBeforeDefender,
              attackerAfter: updatedAttacker,
              defenderAfter: updatedDefender,
              damageDealt: counterResolution.damageDealt,
            ),
          );

          if (!updatedAttacker.isDefeated) {
            updatedAttacker =
                _applySeguroRotoAfterDesafioCounter(updatedAttacker);
            updatedAttacker =
                _applyAceleradorRetoAfterSurvivingCounter(updatedAttacker);
          }

          if (!updatedAttacker.isDefeated && !updatedDefender.isDefeated) {
            final ultimaPalabraResolution = _resolveUltimaPalabraAfterCounter(
              owner: updatedAttacker,
              target: updatedDefender,
            );
            updatedAttacker = ultimaPalabraResolution.owner;
            updatedDefender = ultimaPalabraResolution.target;
            totalDamageDealt += ultimaPalabraResolution.damageDealt;
            hits.addAll(ultimaPalabraResolution.hits);
          }
        }
      }

      if (updatedAttacker.isDefeated || updatedDefender.isDefeated) {
        break;
      }

      final hasFollowUp = attackIndex < attackCount - 1;
      updatedAttacker = hasFollowUp
          ? updatedAttacker.addCombatFlag(
              Battler.pendingBasicAttackFollowUpFlag,
            )
          : updatedAttacker.removeCombatFlag(
              Battler.pendingBasicAttackFollowUpFlag,
            );
      final attackerBeforeHit = updatedAttacker;
      final defenderBeforeHit = updatedDefender;

      final resolution = _resolver.resolveAttack(
        attacker: updatedAttacker,
        defender: updatedDefender,
        flatAttackBonus: flatAttackBonus,
        baseDamageOverride: baseDamageOverride,
        triggerAttackResolvedEffects: triggerAttackResolvedEffects,
        sourceItem: sourceItem,
      );
      updatedAttacker = resolution.attacker.removeCombatFlag(
        Battler.pendingBasicAttackFollowUpFlag,
      );
      updatedDefender = resolution.defender;
      totalDamageDealt += resolution.damageDealt;
      followUpItemActions.addAll(resolution.followUpItemActions);
      hits.add(
        _BattleAttackHitResolution(
          primaryCombatant: _BattleAttackHitCombatant.attacker,
          motionAsset: BattleCombatMotionAsset.sword,
          attackerBefore: attackerBeforeHit.removeCombatFlag(
            Battler.pendingBasicAttackFollowUpFlag,
          ),
          defenderBefore: defenderBeforeHit,
          attackerAfter: updatedAttacker,
          defenderAfter: updatedDefender,
          damageDealt: resolution.damageDealt,
        ),
      );

      if (consumedDesafioValue <= 0 ||
          desafioCounterPrevented ||
          updatedAttacker.isDefeated ||
          updatedDefender.isDefeated) {
        continue;
      }
    }

    return _BattleAttackActionResolution(
      attacker: updatedAttacker.removeCombatFlag(
        Battler.pendingBasicAttackFollowUpFlag,
      ),
      defender: updatedDefender,
      damageDealt: totalDamageDealt,
      hits: List<_BattleAttackHitResolution>.unmodifiable(hits),
      followUpItemActions:
          List<ItemFollowUpAction>.unmodifiable(followUpItemActions),
    );
  }

  _BattleAttackActionResolution _resolveDesafioOnlyAction({
    required Battler attacker,
    required Battler defender,
    int challengeCounterattackBonus = 0,
  }) {
    final attackerBefore = attacker.removeCombatFlag(
      Battler.pendingBasicAttackFollowUpFlag,
    );
    final defenderBefore = defender;
    var updatedAttacker = attackerBefore;
    var updatedDefender = defender;
    var totalDamageDealt = 0;
    final hits = <_BattleAttackHitResolution>[];

    final challengeConsumption = _consumeDesafioIfPresent(updatedAttacker);
    final consumedDesafioValue = challengeConsumption.value;
    updatedAttacker = challengeConsumption.owner;
    if (consumedDesafioValue <= 0) {
      return _BattleAttackActionResolution(
        attacker: updatedAttacker,
        defender: updatedDefender,
        damageDealt: 0,
        hits: const <_BattleAttackHitResolution>[],
      );
    }

    final challengeResolution = _resolveDirectDamageOnly(
      source: updatedAttacker,
      target: updatedDefender,
      damage: consumedDesafioValue,
      barrierIgnore: _desafioBarrierIgnoreFor(updatedAttacker),
    );
    updatedAttacker = challengeResolution.source;
    updatedDefender = challengeResolution.target;
    totalDamageDealt += challengeResolution.damageDealt;
    final executionBellResolution = _applyExecutionBellAfterDesafioAttack(
      owner: updatedAttacker,
      target: updatedDefender,
    );
    updatedAttacker = executionBellResolution.owner;
    updatedDefender = executionBellResolution.target;
    hits.add(
      _BattleAttackHitResolution(
        primaryCombatant: _BattleAttackHitCombatant.attacker,
        motionAsset: BattleCombatMotionAsset.fist,
        attackerBefore: attackerBefore,
        defenderBefore: defenderBefore,
        attackerAfter: updatedAttacker,
        defenderAfter: updatedDefender,
        damageDealt: challengeResolution.damageDealt,
      ),
    );

    if (!challengeConsumption.preventsCounterattack &&
        !updatedAttacker.isDefeated &&
        !updatedDefender.isDefeated) {
      final counterDamage =
          max(0, consumedDesafioValue ~/ 2 + challengeCounterattackBonus);
      if (counterDamage > 0) {
        final counterBeforeAttacker = updatedAttacker;
        final counterBeforeDefender = updatedDefender;
        final counterResolution = _resolveDirectDamageOnly(
          source: updatedDefender,
          target: updatedAttacker,
          damage: counterDamage,
          kind: DamageKind.desafioCounter,
        );
        updatedDefender = counterResolution.source;
        updatedAttacker = counterResolution.target;
        hits.add(
          _BattleAttackHitResolution(
            primaryCombatant: _BattleAttackHitCombatant.defender,
            motionAsset: BattleCombatMotionAsset.fist,
            attackerBefore: counterBeforeAttacker,
            defenderBefore: counterBeforeDefender,
            attackerAfter: updatedAttacker,
            defenderAfter: updatedDefender,
            damageDealt: counterResolution.damageDealt,
          ),
        );

        if (!updatedAttacker.isDefeated) {
          updatedAttacker =
              _applySeguroRotoAfterDesafioCounter(updatedAttacker);
          updatedAttacker =
              _applyAceleradorRetoAfterSurvivingCounter(updatedAttacker);
        }
      }
    }

    return _BattleAttackActionResolution(
      attacker: updatedAttacker,
      defender: updatedDefender,
      damageDealt: totalDamageDealt,
      hits: List<_BattleAttackHitResolution>.unmodifiable(hits),
    );
  }

  ({Battler owner, Battler target}) _applyExecutionBellAfterDesafioAttack({
    required Battler owner,
    required Battler target,
  }) {
    var updatedOwner = owner;
    var updatedTarget = target;

    for (final item in updatedOwner.equippedItems) {
      for (final effect in item.passiveEffects.where(
        (effect) =>
            effect.effectKey == ItemEffectKeys.executionBellCounterRevenge,
      )) {
        if (updatedOwner.itemCombatFlagUseCount(
              item: item,
              kind: effect.effectKey,
            ) >=
            effect.value) {
          continue;
        }

        final burnResolution = updatedTarget.applyStatusFromSourceResolved(
          const QuemaduraStatus(remainingTurns: 5),
          source: updatedOwner,
        );
        updatedOwner = burnResolution.source.addItemCombatFlagUse(
          item: item,
          kind: effect.effectKey,
        );
        updatedTarget = burnResolution.owner;
      }
    }

    return (owner: updatedOwner, target: updatedTarget);
  }

  Battler _applyPreAttackDesafioGains(Battler owner) {
    return owner;
  }

  _DesafioConsumption _consumeDesafioIfPresent(Battler owner) {
    final status = owner.statusById(DesafioStatus.statusId);
    if (status is! DesafioStatus || status.value <= 0) {
      return _DesafioConsumption(
        owner: owner,
        value: 0,
        preventsCounterattack: false,
      );
    }

    return _DesafioConsumption(
      owner: owner.removeStatusInstance(status),
      value: max(0, status.resolved(owner).value),
      preventsCounterattack: false,
    );
  }

  int _desafioBarrierIgnoreFor(Battler owner) {
    return 0;
  }

  Battler _applySeguroRotoAfterDesafioCounter(Battler owner) {
    return owner;
  }

  Battler _applyAceleradorRetoAfterSurvivingCounter(Battler owner) {
    return owner;
  }

  _UltimaPalabraResolution _resolveUltimaPalabraAfterCounter({
    required Battler owner,
    required Battler target,
  }) {
    return _UltimaPalabraResolution(
      owner: owner,
      target: target,
      damageDealt: 0,
      hits: const <_BattleAttackHitResolution>[],
    );
  }

  _DirectDamageResolution _resolveDirectDamageOnly({
    required Battler source,
    required Battler target,
    required int damage,
    DamageKind kind = DamageKind.direct,
    int barrierIgnore = 0,
  }) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) {
      return _DirectDamageResolution(
        source: source,
        target: target,
        damageDealt: 0,
      );
    }

    final incomingStatusModifiedDamage =
        _effectPipeline.applyIncomingDamageModifiers(
      owner: target,
      source: source,
      damage: safeDamage,
    );
    final incomingItemModifiedDamage =
        _effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: target,
      source: source,
      damage: incomingStatusModifiedDamage,
    );
    final incomingEffectResolution = _effectPipeline.applyIncomingDamageEffects(
      owner: target,
      source: source,
      damage: incomingItemModifiedDamage,
      kind: kind,
    );
    final damageDealt = incomingEffectResolution.damage;
    var updatedTarget = _receiveDamageWithBarrierIgnore(
      owner: incomingEffectResolution.owner,
      damage: damageDealt,
      barrierIgnore: barrierIgnore,
    );
    var updatedSource = source;

    updatedTarget = _effectPipeline.applyReceiveDamageResolvedEffects(
      owner: updatedTarget,
      source: updatedSource,
      damageTaken: damageDealt,
    );
    final receiveItemResolution =
        _effectPipeline.applyEquippedItemReceiveDamageResolvedEffects(
      owner: updatedTarget,
      source: updatedSource,
      damageTaken: damageDealt,
      damageKind: kind,
    );
    updatedTarget = receiveItemResolution.owner;
    updatedSource = receiveItemResolution.opponent;
    if (damageDealt > 0) {
      updatedTarget = updatedTarget.recordDamageTakenThisRound(damageDealt);
    }

    final statusLossResolution = _effectPipeline.applyStatusLossBarrierTriggers(
      ownerBefore: source,
      ownerAfter: updatedSource,
      opponentBefore: target,
      opponentAfter: updatedTarget,
    );

    return _DirectDamageResolution(
      source: statusLossResolution.owner,
      target: statusLossResolution.opponent,
      damageDealt: damageDealt,
    );
  }

  Battler _receiveDamageWithBarrierIgnore({
    required Battler owner,
    required int damage,
    int barrierIgnore = 0,
  }) {
    return _stateReducer.receiveDamageWithBarrierIgnore(
      owner: owner,
      damage: damage,
      barrierIgnore: barrierIgnore,
    );
  }

  Future<void> _playAttackActionAnimations({
    required BattleCombatantSide attackerSide,
    required Battler attackerBefore,
    required Battler defenderBefore,
    required _BattleAttackActionResolution resolution,
  }) async {
    final defenderSide = attackerSide == BattleCombatantSide.player
        ? BattleCombatantSide.enemy
        : BattleCombatantSide.player;
    if (resolution.hits.isEmpty) {
      final playerBefore = attackerSide == BattleCombatantSide.player
          ? attackerBefore
          : defenderBefore;
      final enemyBefore = attackerSide == BattleCombatantSide.enemy
          ? attackerBefore
          : defenderBefore;
      await _playCombatAnimation(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.attackMotion,
          primarySide: attackerSide,
          secondarySide: defenderSide,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerBefore,
          enemyAfter: enemyBefore,
        ),
      );
      return;
    }

    for (final hit in resolution.hits) {
      final visualState = _visualStateForAttackHit(
        hit: hit,
        attackerSide: attackerSide,
      );
      final primarySide = _primarySideForAttackHit(
        hit: hit,
        attackerSide: attackerSide,
      );
      final secondarySide = primarySide == BattleCombatantSide.player
          ? BattleCombatantSide.enemy
          : BattleCombatantSide.player;
      await _playCombatAnimation(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.attackMotion,
          primarySide: primarySide,
          secondarySide: secondarySide,
          playerBefore: visualState.playerBefore,
          enemyBefore: visualState.enemyBefore,
          playerAfter: visualState.playerBefore,
          enemyAfter: visualState.enemyBefore,
          motionAsset: hit.motionAsset,
        ),
      );
      if (_isDisposed) return;

      await _playCombatStateTransitionAnimations(
        playerBefore: visualState.playerBefore,
        enemyBefore: visualState.enemyBefore,
        playerAfter: visualState.playerAfter,
        enemyAfter: visualState.enemyAfter,
      );
      if (_isDisposed) return;
    }
  }

  BattleCombatantSide _primarySideForAttackHit({
    required _BattleAttackHitResolution hit,
    required BattleCombatantSide attackerSide,
  }) {
    if (hit.primaryCombatant == _BattleAttackHitCombatant.attacker) {
      return attackerSide;
    }

    return attackerSide == BattleCombatantSide.player
        ? BattleCombatantSide.enemy
        : BattleCombatantSide.player;
  }

  _BattleAttackHitVisualState _visualStateForAttackHit({
    required _BattleAttackHitResolution hit,
    required BattleCombatantSide attackerSide,
  }) {
    final attackerIsPlayer = attackerSide == BattleCombatantSide.player;
    return _BattleAttackHitVisualState(
      playerBefore: attackerIsPlayer ? hit.attackerBefore : hit.defenderBefore,
      enemyBefore: attackerIsPlayer ? hit.defenderBefore : hit.attackerBefore,
      playerAfter: attackerIsPlayer ? hit.attackerAfter : hit.defenderAfter,
      enemyAfter: attackerIsPlayer ? hit.defenderAfter : hit.attackerAfter,
    );
  }

  Future<void> _playBlockResolutionAnimation({
    required BattleCombatantSide defenderSide,
    required Battler defenderBefore,
    required Battler opponentBefore,
    required Battler defenderAfter,
    required Battler opponentAfter,
  }) async {
    final opponentSide = defenderSide == BattleCombatantSide.player
        ? BattleCombatantSide.enemy
        : BattleCombatantSide.player;
    final playerBefore = defenderSide == BattleCombatantSide.player
        ? defenderBefore
        : opponentBefore;
    final enemyBefore = defenderSide == BattleCombatantSide.enemy
        ? defenderBefore
        : opponentBefore;
    final playerAfter = defenderSide == BattleCombatantSide.player
        ? defenderAfter
        : opponentAfter;
    final enemyAfter = defenderSide == BattleCombatantSide.enemy
        ? defenderAfter
        : opponentAfter;

    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.blockMotion,
        primarySide: defenderSide,
        secondarySide: opponentSide,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerBefore,
        enemyAfter: enemyBefore,
      ),
    );
    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
    );
  }

  Future<void> _playHealingActionAnimation({
    required BattleCombatantSide healerSide,
    required Battler healerBefore,
    required Battler opponentBefore,
    required Battler healerAfter,
    required Battler opponentAfter,
  }) async {
    final playerBefore = healerSide == BattleCombatantSide.player
        ? healerBefore
        : opponentBefore;
    final enemyBefore =
        healerSide == BattleCombatantSide.enemy ? healerBefore : opponentBefore;
    final playerAfter =
        healerSide == BattleCombatantSide.player ? healerAfter : opponentAfter;
    final enemyAfter =
        healerSide == BattleCombatantSide.enemy ? healerAfter : opponentAfter;

    await _playCombatAnimation(
      BattleCombatAnimationCueFactory.stateTransitionCue(
        hook: BattleCombatAnimationHook.healthGain,
        side: healerSide,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerAfter,
        enemyAfter: enemyAfter,
        floatingNumbers: BattleCombatAnimationCueFactory.gainFloatingNumbers(
          before: healerBefore,
          after: healerAfter,
          includeHealth: true,
        ),
      ),
    );
  }

  Future<void> _playCombatStateTransitionAnimations({
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
    Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>> floatingNumbersBySide =
        const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{},
  }) async {
    final cues = _animationCueProducer.stateTransitionCues(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
      floatingNumbersBySide: floatingNumbersBySide,
    );
    for (final cue in cues) {
      await _playCombatAnimation(cue);
    }
  }

  Future<void> _playCombatAnimation(BattleCombatAnimationCue cue) async {
    final callback = onCombatAnimation;
    if (callback == null) return;
    await callback(cue);
  }

  void _finishCombat({
    required BattleFlowResultType resultType,
    required String resultText,
  }) {
    if (_turn == BattleTurnState.finished) return;

    _cancelTimers();
    _player = _player.finalizeCombatState();
    _enemy = _enemy.finalizeCombatState();
    _turn = BattleTurnState.finished;
    _resultText = resultText;
    notifyListeners();

    _combatExitTimer = Timer(combatEndDelay, () {
      _pendingExitResult = BattleFlowResult(
        type: resultType,
        player: _player,
      );
      notifyListeners();
    });
  }

  void _cancelTimers() {
    _enemyTurnTimer?.cancel();
    _combatExitTimer?.cancel();
    _enemyTurnTimer = null;
    _combatExitTimer = null;
  }

  /// Revisa tras cada mutacion sensible si el jugador ya debe perder sin esperar a otra fase.
  bool _finishImmediatelyIfPlayerIsDown() {
    final finish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (finish == null || finish.resultType == BattleFlowResultType.victory) {
      return false;
    }

    _finishCombat(
      resultType: finish.resultType,
      resultText: finish.resultText,
    );
    return true;
  }

  void _syncCombatRoundFlags() {
    _player = _player.withCombatRound(_currentRound);
    _enemy = _enemy.withCombatRound(_currentRound);
  }

  Future<void> _beginTurn(
    BattleTurnState nextTurn, {
    bool notify = true,
  }) async {
    _turn = nextTurn;
    _syncCombatRoundFlags();
    final playerBefore = _player;
    final enemyBefore = _enemy;
    final resolution = _turnEngine.beginTurn(
      isPlayerTurn: nextTurn == BattleTurnState.player,
      player: _player,
      enemy: _enemy,
      randomizer: _randomizer,
    );

    var nextPlayer = resolution.player;
    var nextEnemy = resolution.enemy;
    final turnStartFloatingNumbers = _buildTurnStartDebuffFloatingNumbers(
      activeTurn: nextTurn,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: nextPlayer,
      enemyAfter: nextEnemy,
    );

    if (resolution.finish != null) {
      await _playTurnStartDebuffDamageAnimations(
        activeTurn: nextTurn,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
      );
      if (_isDisposed) return;

      await _playCombatStateTransitionAnimations(
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: nextPlayer,
        enemyAfter: nextEnemy,
        floatingNumbersBySide: turnStartFloatingNumbers,
      );
      if (_isDisposed) return;
      _player = nextPlayer;
      _enemy = nextEnemy;
      _finishCombat(
        resultType: resolution.finish!.resultType,
        resultText: resolution.finish!.resultText,
      );
      return;
    }

    await _playTurnStartDebuffDamageAnimations(
      activeTurn: nextTurn,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
    );
    if (_isDisposed) return;

    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: nextPlayer,
      enemyAfter: nextEnemy,
      floatingNumbersBySide: turnStartFloatingNumbers,
    );
    if (_isDisposed) return;
    _player = nextPlayer;
    _enemy = nextEnemy;

    if (await _resolveTurnStartDesafio(nextTurn)) {
      return;
    }

    final autoBlockFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (autoBlockFinish != null) {
      _finishCombat(
        resultType: autoBlockFinish.resultType,
        resultText: autoBlockFinish.resultText,
      );
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  void _beginTurnWithoutAnimation(
    BattleTurnState nextTurn, {
    bool notify = true,
  }) {
    _turn = nextTurn;
    _syncCombatRoundFlags();
    final resolution = _turnEngine.beginTurn(
      isPlayerTurn: nextTurn == BattleTurnState.player,
      player: _player,
      enemy: _enemy,
      randomizer: _randomizer,
    );

    if (resolution.finish != null) {
      _player = resolution.player;
      _enemy = resolution.enemy;
      _finishCombat(
        resultType: resolution.finish!.resultType,
        resultText: resolution.finish!.resultText,
      );
      return;
    }

    _player = resolution.player;
    _enemy = resolution.enemy;
    _resolveTurnStartDesafioWithoutAnimation(nextTurn);
    if (isCombatFinished) return;

    final autoBlockFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (autoBlockFinish != null) {
      _finishCombat(
        resultType: autoBlockFinish.resultType,
        resultText: autoBlockFinish.resultText,
      );
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> handleSimultaneousPatternMatches({
    required BattleActionBonus playerActionBonus,
    required BattlePatternMatchContext playerPatternContext,
    required BattleActionBonus enemyActionBonus,
    required BattlePatternMatchContext enemyPatternContext,
    required List<BattlePatternActionPileEntry> playerActionPile,
    required List<BattlePatternActionPileEntry> enemyActionPile,
    BattlePatternActionPileStepCallback? onActionPileStep,
    BattlePatternActionPileUpdateCallback? onActionPileUpdate,
  }) async {
    if (!canUseActions) return;

    var resolvedPlayerPatternContext =
        playerPatternContext.withRandomSource(_randomizer);
    var resolvedEnemyPatternContext =
        enemyPatternContext.withRandomSource(_randomizer);
    if (_isPatternBanned(
          _playerUsedPatterns,
          resolvedPlayerPatternContext.patternPoints,
        ) ||
        _isPatternBanned(
          _enemyUsedPatterns,
          resolvedEnemyPatternContext.patternPoints,
        )) {
      return;
    }
    _recordUsedPattern(
      _playerUsedPatterns,
      resolvedPlayerPatternContext.patternPoints,
    );
    _recordUsedPattern(
      _enemyUsedPatterns,
      resolvedEnemyPatternContext.patternPoints,
    );

    final playerModifiers = _ActionPileModifiers();
    final enemyModifiers = _ActionPileModifiers();

    final prepPlayerBefore = _player;
    final prepEnemyBefore = _enemy;
    _player = _player.applyAugmentPatternWeaponBoost(
      pattern: resolvedPlayerPatternContext,
    );
    _enemy = _enemy.applyAugmentPatternWeaponBoost(
      pattern: resolvedEnemyPatternContext,
    );

    final enemyPreAttackResolution = _resolveEnemyPreAttackState(
      enemy: _enemy,
      player: _player,
    );
    _enemy = enemyPreAttackResolution.enemy;
    _player = enemyPreAttackResolution.player;

    final playerPreAttackItemResolution =
        _player.applyEquippedItemPrePatternAttackEffects(
      opponent: _enemy,
      pattern: resolvedPlayerPatternContext,
    );
    _player = playerPreAttackItemResolution.owner;
    _enemy = playerPreAttackItemResolution.opponent;
    playerModifiers.attack += playerPreAttackItemResolution.attackBonusDelta;
    playerModifiers.barrier += playerPreAttackItemResolution.barrierBonusDelta;

    final enemyPreAttackItemResolution =
        _enemy.applyEquippedItemPrePatternAttackEffects(
      opponent: _player,
      pattern: resolvedEnemyPatternContext,
    );
    _enemy = enemyPreAttackItemResolution.owner;
    _player = enemyPreAttackItemResolution.opponent;
    enemyModifiers.attack += enemyPreAttackItemResolution.attackBonusDelta;
    enemyModifiers.barrier += enemyPreAttackItemResolution.barrierBonusDelta;

    final playerPatternUsedItemResolution =
        _player.applyEquippedItemPatternUsedEffects(
      opponent: _enemy,
      pattern: resolvedPlayerPatternContext,
    );
    _player = playerPatternUsedItemResolution.owner;
    _enemy = playerPatternUsedItemResolution.opponent;
    playerModifiers.attack += playerPatternUsedItemResolution.attackBonusDelta;
    playerModifiers.barrier +=
        playerPatternUsedItemResolution.barrierBonusDelta;

    final enemyPatternUsedItemResolution =
        _enemy.applyEquippedItemPatternUsedEffects(
      opponent: _player,
      pattern: resolvedEnemyPatternContext,
    );
    _enemy = enemyPatternUsedItemResolution.owner;
    _player = enemyPatternUsedItemResolution.opponent;
    enemyModifiers.attack += enemyPatternUsedItemResolution.attackBonusDelta;
    enemyModifiers.barrier += enemyPatternUsedItemResolution.barrierBonusDelta;

    await _playCombatStateTransitionAnimations(
      playerBefore: prepPlayerBefore,
      enemyBefore: prepEnemyBefore,
      playerAfter: _player,
      enemyAfter: _enemy,
    );
    if (_isDisposed || !canUseActions) return;

    final prepFinish = _turnEngine.finishFor(player: _player, enemy: _enemy);
    if (prepFinish != null) {
      _finishCombat(
        resultType: prepFinish.resultType,
        resultText: prepFinish.resultText,
      );
      return;
    }

    final didFinish = await _resolveSimultaneousPatternActionGroups(
      playerPattern: resolvedPlayerPatternContext,
      playerActionPile: playerActionPile,
      playerModifiers: playerModifiers,
      enemyPattern: resolvedEnemyPatternContext,
      enemyActionPile: enemyActionPile,
      enemyModifiers: enemyModifiers,
      onActionPileStep: onActionPileStep,
      onActionPileUpdate: onActionPileUpdate,
    );
    if (didFinish || _isDisposed || !canUseActions) return;

    _enemyAi.registerResolvedAction(EnemyTurnAction.attack);
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.player)) {
      return;
    }
    await _beginTurn(BattleTurnState.enemy);
    if (_isDisposed || _turn != BattleTurnState.enemy) return;
    if (await _completeTurn(BattleTurnState.enemy)) {
      return;
    }

    _enemyNextAction = _rollEnemyTurnAction();
    await _beginTurn(BattleTurnState.player);
  }

  Future<bool> _resolveSimultaneousPatternActionGroups({
    required BattlePatternMatchContext playerPattern,
    required List<BattlePatternActionPileEntry> playerActionPile,
    required _ActionPileModifiers playerModifiers,
    required BattlePatternMatchContext enemyPattern,
    required List<BattlePatternActionPileEntry> enemyActionPile,
    required _ActionPileModifiers enemyModifiers,
    BattlePatternActionPileStepCallback? onActionPileStep,
    BattlePatternActionPileUpdateCallback? onActionPileUpdate,
  }) async {
    final playerPile = List<BattlePatternActionPileEntry>.of(playerActionPile);
    final enemyPile = List<BattlePatternActionPileEntry>.of(enemyActionPile);
    final playerResolvedActions = <ActionEffect>[];
    final enemyResolvedActions = <ActionEffect>[];
    var playerIndex = 0;
    var enemyIndex = 0;
    var playerActs = playerPile.isNotEmpty;
    var enemyActs = enemyPile.isNotEmpty;

    while (playerActs || enemyActs) {
      await onActionPileStep?.call(
        BattlePatternActionPileStep(
          playerIndex: _displayIndexForActionPile(
            entries: playerPile,
            index: playerIndex,
          ),
          enemyIndex: _displayIndexForActionPile(
            entries: enemyPile,
            index: enemyIndex,
          ),
          playerActs: playerActs,
          enemyActs: enemyActs,
        ),
      );
      if (_isDisposed || !canUseActions) return true;

      final playerBeforeBeat = _player;
      final enemyBeforeBeat = _enemy;
      final motions = <BattleCombatMotionCue>[];
      final buffSides = <BattleCombatantSide>{};

      if (playerActs) {
        final resolved = _resolveActionPileEntry(
          side: BattleCombatantSide.player,
          entry: playerPile[playerIndex],
          pattern: playerPattern,
          modifiers: playerModifiers,
          resolvedActions: playerResolvedActions,
        );
        motions.addAll(resolved.motions);
        if (resolved.didBuff) buffSides.add(BattleCombatantSide.player);
        if (resolved.followUps.isNotEmpty) {
          _insertActionPileFollowUps(
            entries: playerPile,
            currentIndex: playerIndex,
            followUps: resolved.followUps,
          );
          await onActionPileUpdate?.call(
            isPlayer: true,
            entries: List<BattlePatternActionPileEntry>.unmodifiable(
              playerPile,
            ),
          );
        }
      }
      if (enemyActs) {
        final resolved = _resolveActionPileEntry(
          side: BattleCombatantSide.enemy,
          entry: enemyPile[enemyIndex],
          pattern: enemyPattern,
          modifiers: enemyModifiers,
          resolvedActions: enemyResolvedActions,
        );
        motions.addAll(resolved.motions);
        if (resolved.didBuff) buffSides.add(BattleCombatantSide.enemy);
        if (resolved.followUps.isNotEmpty) {
          _insertActionPileFollowUps(
            entries: enemyPile,
            currentIndex: enemyIndex,
            followUps: resolved.followUps,
          );
          await onActionPileUpdate?.call(
            isPlayer: false,
            entries: List<BattlePatternActionPileEntry>.unmodifiable(enemyPile),
          );
        }
      }

      await _playSimultaneousPatternActionBeatAnimations(
        playerBefore: playerBeforeBeat,
        enemyBefore: enemyBeforeBeat,
        playerAfter: _player,
        enemyAfter: _enemy,
        motions: motions,
        buffSides: buffSides,
      );
      if (_isDisposed || !canUseActions) return true;

      final finish = _turnEngine.finishFor(player: _player, enemy: _enemy);
      if (finish != null) {
        _finishCombat(
          resultType: finish.resultType,
          resultText: finish.resultText,
        );
        return true;
      }

      final playerHasMoreInChain = playerActs &&
          _hasNextChainedActionPileEntry(
            entries: playerPile,
            index: playerIndex,
          );
      final enemyHasMoreInChain = enemyActs &&
          _hasNextChainedActionPileEntry(
            entries: enemyPile,
            index: enemyIndex,
          );

      if (playerHasMoreInChain && enemyHasMoreInChain) {
        playerIndex++;
        enemyIndex++;
        playerActs = true;
        enemyActs = true;
      } else if (playerHasMoreInChain) {
        playerIndex++;
        playerActs = true;
        enemyActs = false;
      } else if (enemyHasMoreInChain) {
        enemyIndex++;
        playerActs = false;
        enemyActs = true;
      } else {
        playerIndex++;
        enemyIndex++;
        playerActs = playerIndex < playerPile.length;
        enemyActs = enemyIndex < enemyPile.length;
      }
    }

    return false;
  }

  int _displayIndexForActionPile({
    required List<BattlePatternActionPileEntry> entries,
    required int index,
  }) {
    if (entries.isEmpty) return -1;
    return index.clamp(0, entries.length - 1);
  }

  bool _hasNextChainedActionPileEntry({
    required List<BattlePatternActionPileEntry> entries,
    required int index,
  }) {
    if (index < 0 || index + 1 >= entries.length) return false;
    return entries[index].chainKey == entries[index + 1].chainKey;
  }

  void _insertActionPileFollowUps({
    required List<BattlePatternActionPileEntry> entries,
    required int currentIndex,
    required List<BattlePatternActionPileEntry> followUps,
  }) {
    if (followUps.isEmpty) return;

    var insertIndex = currentIndex + 1;
    while (insertIndex < entries.length &&
        entries[insertIndex].chainKey == entries[currentIndex].chainKey) {
      insertIndex++;
    }
    entries.insertAll(insertIndex, followUps);
  }

  ({
    List<BattleCombatMotionCue> motions,
    bool didBuff,
    List<BattlePatternActionPileEntry> followUps,
  }) _resolveActionPileEntry({
    required BattleCombatantSide side,
    required BattlePatternActionPileEntry entry,
    required BattlePatternMatchContext pattern,
    required _ActionPileModifiers modifiers,
    required List<ActionEffect> resolvedActions,
  }) {
    final isPlayer = side == BattleCombatantSide.player;
    final bonus = entry.bonus;
    if (bonus != null) {
      switch (bonus.kind) {
        case OperativePatternBonusKind.attack:
          modifiers.attack += bonus.amount;
          break;
        case OperativePatternBonusKind.barrier:
          modifiers.barrier += bonus.amount;
          break;
        case OperativePatternBonusKind.health:
          modifiers.heal += bonus.amount;
          break;
      }
      return (
        motions: const <BattleCombatMotionCue>[],
        didBuff: true,
        followUps: const <BattlePatternActionPileEntry>[],
      );
    }

    final item = entry.item;
    final entryAction = entry.action;
    if (item == null || entryAction == null) {
      return (
        motions: const <BattleCombatMotionCue>[],
        didBuff: false,
        followUps: const <BattlePatternActionPileEntry>[],
      );
    }

    final owner = isPlayer ? _player : _enemy;
    final action = _actionWithItemActionScaling(
      owner: owner,
      action: entryAction,
    );
    final motions = <BattleCombatMotionCue>[];
    final followUps = <BattlePatternActionPileEntry>[];

    if (isPlayer) {
      _player = _player.recordResolvedItemAction(action);
    } else {
      _enemy = _enemy.recordResolvedItemAction(action);
    }

    switch (action.actionType) {
      case ItemActionType.attack:
        final attackResolution = _resolveAttackAction(
          attacker: isPlayer ? _player : _enemy,
          defender: isPlayer ? _enemy : _player,
          baseDamageOverride: max(0, action.totalValue + modifiers.attack),
          sourceItem: item,
        );
        if (isPlayer) {
          _player = attackResolution.attacker;
          _enemy = attackResolution.defender;
        } else {
          _enemy = attackResolution.attacker;
          _player = attackResolution.defender;
        }
        motions.add(
          BattleCombatMotionCue(
            hook: BattleCombatAnimationHook.attackMotion,
            primarySide: side,
            secondarySide: isPlayer
                ? BattleCombatantSide.enemy
                : BattleCombatantSide.player,
            effectCount: max(1, attackResolution.hits.length),
            motionAsset: attackResolution.hits.isEmpty
                ? BattleCombatMotionAsset.sword
                : attackResolution.hits.first.motionAsset,
          ),
        );
        followUps.addAll(
          _followUpEntriesForItemActions(
            owner: isPlayer ? _player : _enemy,
            pattern: pattern,
            sourceChainKey: entry.chainKey,
            followUps: attackResolution.followUpItemActions,
          ),
        );
        break;
      case ItemActionType.block:
        if (isPlayer) {
          _player = _applyBarrierGain(
            _player,
            max(0, action.totalValue + modifiers.barrier),
          );
        } else {
          _enemy = _applyBarrierGain(
            _enemy,
            max(0, action.totalValue + modifiers.barrier),
          );
        }
        motions.add(
          BattleCombatMotionCue(
            hook: BattleCombatAnimationHook.blockMotion,
            primarySide: side,
            secondarySide: isPlayer
                ? BattleCombatantSide.enemy
                : BattleCombatantSide.player,
            motionAsset: BattleCombatMotionAsset.shield,
          ),
        );
        break;
      case ItemActionType.heal:
        if (isPlayer) {
          _player = _player.heal(action.totalValue + modifiers.heal);
        } else {
          _enemy = _enemy.heal(action.totalValue + modifiers.heal);
        }
        motions.add(
          BattleCombatMotionCue(
            hook: BattleCombatAnimationHook.healthGain,
            primarySide: side,
            motionAsset: BattleCombatMotionAsset.health,
          ),
        );
        break;
      case ItemActionType.none:
        final resolution = ItemEffectDispatcher.resolveCustomAction(
          owner: isPlayer ? _player : _enemy,
          opponent: isPlayer ? _enemy : _player,
          item: item,
          effect: action,
          pattern: pattern,
          previousActions: List<ActionEffect>.unmodifiable(resolvedActions),
        );
        if (isPlayer) {
          _player = resolution.owner;
          _enemy = resolution.opponent;
        } else {
          _enemy = resolution.owner;
          _player = resolution.opponent;
        }
        followUps.addAll(
          _followUpEntriesForItemActions(
            owner: isPlayer ? _player : _enemy,
            pattern: pattern,
            sourceChainKey: entry.chainKey,
            followUps: resolution.followUpItemActions,
          ),
        );
        followUps.addAll(
          _followUpEntriesForActions(
            sourceChainKey: entry.chainKey,
            sourceItem: item,
            actions: resolution.followUpActions,
          ),
        );
        break;
    }

    final itemResolution = isPlayer
        ? _applyPlayerItemActionResolvedEffects(
            action: action,
            item: item,
            pattern: pattern,
          )
        : _applyEnemyItemActionResolvedEffects(
            action: action,
            item: item,
            pattern: pattern,
          );
    if (isPlayer) {
      _player = itemResolution.owner;
      _enemy = itemResolution.opponent;
    } else {
      _enemy = itemResolution.owner;
      _player = itemResolution.opponent;
    }
    followUps.addAll(
      _followUpEntriesForItemActions(
        owner: isPlayer ? _player : _enemy,
        pattern: pattern,
        sourceChainKey: entry.chainKey,
        followUps: itemResolution.followUpItemActions,
      ),
    );
    followUps.addAll(
      _followUpEntriesForActions(
        sourceChainKey: entry.chainKey,
        sourceItem: item,
        actions: itemResolution.followUpActions,
      ),
    );
    if (entry.countsAsItemAction) {
      resolvedActions.add(action);
    }
    return (
      motions: List<BattleCombatMotionCue>.unmodifiable(motions),
      didBuff: false,
      followUps: List<BattlePatternActionPileEntry>.unmodifiable(followUps),
    );
  }

  List<BattlePatternActionPileEntry> _followUpEntriesForActions({
    required String sourceChainKey,
    required Item sourceItem,
    required List<ActionEffect> actions,
  }) {
    if (actions.isEmpty) return const <BattlePatternActionPileEntry>[];

    return List<BattlePatternActionPileEntry>.unmodifiable([
      for (var index = 0; index < actions.length; index++)
        BattlePatternActionPileEntry.itemAction(
          pointKey: 'followup:$sourceChainKey:$index',
          chainKey: 'followup-action:$sourceChainKey',
          item: sourceItem,
          action: actions[index],
        ),
    ]);
  }

  List<BattlePatternActionPileEntry> _followUpEntriesForItemActions({
    required Battler owner,
    required BattlePatternMatchContext pattern,
    required String sourceChainKey,
    required List<ItemFollowUpAction> followUps,
  }) {
    if (followUps.isEmpty) return const <BattlePatternActionPileEntry>[];

    final entries = <BattlePatternActionPileEntry>[];
    var followUpUseIndex = 0;
    var cursor = 0;
    while (cursor < followUps.length) {
      final item = followUps[cursor].item;
      var runLength = 0;
      while (cursor + runLength < followUps.length &&
          followUps[cursor + runLength].item == item) {
        runLength++;
      }

      final fullActionCount = max(
        1,
        _actionsForPatternItemUse(
          item: owner.itemWithCombatActionBonuses(item),
          pattern: pattern,
          pointKey: OperativePatternLayoutService.pointKeyForItem(
                player: owner,
                item: item,
              ) ??
              '',
        ).length,
      );
      final repeatCount = max(1, runLength ~/ fullActionCount);
      final baseActions = item.actionEffects;
      for (var repeat = 0; repeat < repeatCount; repeat++) {
        final chainKey = 'followup-item:$sourceChainKey:${followUpUseIndex++}';
        for (final action in baseActions) {
          entries.add(
            BattlePatternActionPileEntry.itemAction(
              pointKey: 'followup:${item.instanceId ?? item.catalogKey}',
              chainKey: chainKey,
              item: item,
              action: action,
            ),
          );
        }
      }
      cursor += runLength;
    }

    return List<BattlePatternActionPileEntry>.unmodifiable(entries);
  }

  Future<void> _playSimultaneousPatternActionBeatAnimations({
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
    required List<BattleCombatMotionCue> motions,
    required Set<BattleCombatantSide> buffSides,
  }) async {
    if (motions.isNotEmpty) {
      await _playCombatAnimation(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.simultaneousMotions,
          primarySide: BattleCombatantSide.player,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerBefore,
          enemyAfter: enemyBefore,
          simultaneousMotions:
              List<BattleCombatMotionCue>.unmodifiable(motions),
        ),
      );
      if (_isDisposed) return;
    }

    if (buffSides.isNotEmpty) {
      await _playCombatAnimation(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.actionBuff,
          primarySide: buffSides.first,
          secondarySide: buffSides.length > 1 ? buffSides.last : null,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerBefore,
          enemyAfter: enemyBefore,
          effectCount: 7,
        ),
      );
      if (_isDisposed) return;
    }

    final desafioWarningCues = _desafioWarningCuesForStateTransition(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
    );
    for (final cue in desafioWarningCues) {
      await _playCombatAnimation(cue);
      if (_isDisposed) return;
    }

    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.purgeDamage,
        primarySide: BattleCombatantSide.player,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerAfter,
        enemyAfter: enemyAfter,
        floatingNumbersBySide: <BattleCombatantSide,
            List<BattleCombatFloatingNumberCue>>{
          BattleCombatantSide.player: _floatingNumbersForActionBeat(
            before: playerBefore,
            after: playerAfter,
          ),
          BattleCombatantSide.enemy: _floatingNumbersForActionBeat(
            before: enemyBefore,
            after: enemyAfter,
          ),
        },
      ),
    );
  }

  List<BattleCombatAnimationCue> _desafioWarningCuesForStateTransition({
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    final cues = <BattleCombatAnimationCue>[];
    final playerDesafioGain =
        playerAfter.desafioValue - playerBefore.desafioValue;
    if (playerDesafioGain > 0) {
      cues.add(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.desafioWarning,
          primarySide: BattleCombatantSide.player,
          secondarySide: BattleCombatantSide.enemy,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerBefore,
          enemyAfter: enemyBefore,
          effectCount: max(4, playerDesafioGain),
        ),
      );
    }

    final enemyDesafioGain = enemyAfter.desafioValue - enemyBefore.desafioValue;
    if (enemyDesafioGain > 0) {
      cues.add(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.desafioWarning,
          primarySide: BattleCombatantSide.enemy,
          secondarySide: BattleCombatantSide.player,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerBefore,
          enemyAfter: enemyBefore,
          effectCount: max(4, enemyDesafioGain),
        ),
      );
    }

    return List<BattleCombatAnimationCue>.unmodifiable(cues);
  }

  List<BattleCombatFloatingNumberCue> _floatingNumbersForActionBeat({
    required Battler before,
    required Battler after,
  }) {
    return List<BattleCombatFloatingNumberCue>.unmodifiable([
      ...BattleCombatAnimationCueFactory.lossFloatingNumbers(
        before: before,
        after: after,
      ),
      ...BattleCombatAnimationCueFactory.gainFloatingNumbers(
        before: before,
        after: after,
        includeHealth: true,
        includeBarrier: true,
      ),
    ]);
  }

  Future<bool> _resolveTurnStartDesafio(BattleTurnState activeTurn) async {
    final isPlayerTurn = activeTurn == BattleTurnState.player;
    final attacker = isPlayerTurn ? _player : _enemy;
    if (attacker.desafioValue <= 0) return false;

    final playerBefore = _player;
    final enemyBefore = _enemy;
    final resolution = _resolveDesafioOnlyAction(
      attacker: attacker,
      defender: isPlayerTurn ? _enemy : _player,
    );
    await _playDesafioWarningAnimation(
      bearerSide:
          isPlayerTurn ? BattleCombatantSide.player : BattleCombatantSide.enemy,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
    );
    if (_isDisposed) return true;

    await _playAttackActionAnimations(
      attackerSide:
          isPlayerTurn ? BattleCombatantSide.player : BattleCombatantSide.enemy,
      attackerBefore: attacker,
      defenderBefore: isPlayerTurn ? _enemy : _player,
      resolution: resolution,
    );
    if (_isDisposed) return true;

    if (isPlayerTurn) {
      _player = resolution.attacker;
      _enemy = resolution.defender;
    } else {
      _enemy = resolution.attacker;
      _player = resolution.defender;
    }

    final finish = _turnEngine.finishFor(player: _player, enemy: _enemy);
    if (finish != null) {
      _finishCombat(
        resultType: finish.resultType,
        resultText: finish.resultText,
      );
      return true;
    }

    if (playerBefore != _player || enemyBefore != _enemy) {
      notifyListeners();
    }
    return false;
  }

  Future<void> _playDesafioWarningAnimation({
    required BattleCombatantSide bearerSide,
    required Battler playerBefore,
    required Battler enemyBefore,
  }) async {
    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.desafioWarning,
        primarySide: bearerSide,
        secondarySide: bearerSide == BattleCombatantSide.player
            ? BattleCombatantSide.enemy
            : BattleCombatantSide.player,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerBefore,
        enemyAfter: enemyBefore,
        effectCount: 6,
      ),
    );
  }

  void _resolveTurnStartDesafioWithoutAnimation(BattleTurnState activeTurn) {
    final isPlayerTurn = activeTurn == BattleTurnState.player;
    final attacker = isPlayerTurn ? _player : _enemy;
    if (attacker.desafioValue <= 0) return;

    final resolution = _resolveDesafioOnlyAction(
      attacker: attacker,
      defender: isPlayerTurn ? _enemy : _player,
    );
    if (isPlayerTurn) {
      _player = resolution.attacker;
      _enemy = resolution.defender;
    } else {
      _enemy = resolution.attacker;
      _player = resolution.defender;
    }

    final finish = _turnEngine.finishFor(player: _player, enemy: _enemy);
    if (finish != null) {
      _finishCombat(
        resultType: finish.resultType,
        resultText: finish.resultText,
      );
    }
  }

  Future<bool> _completeTurn(BattleTurnState completedTurn) async {
    final playerBefore = _player;
    final enemyBefore = _enemy;
    final resolution = _turnEngine.completeTurn(
      didPlayerAct: completedTurn == BattleTurnState.player,
      player: _player,
      enemy: _enemy,
      randomizer: _randomizer,
    );
    final turnEndFloatingNumbers = _buildTurnEndDebuffFloatingNumbers(
      completedTurn: completedTurn,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: resolution.player,
      enemyAfter: resolution.enemy,
    );

    await _playTurnEndDebuffDamageAnimations(
      completedTurn: completedTurn,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
    );
    if (_isDisposed) return true;

    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: resolution.player,
      enemyAfter: resolution.enemy,
      floatingNumbersBySide: turnEndFloatingNumbers,
    );
    if (_isDisposed) return true;
    _player = resolution.player;
    _enemy = resolution.enemy;

    if (resolution.finish != null) {
      _finishCombat(
        resultType: resolution.finish!.resultType,
        resultText: resolution.finish!.resultText,
      );
      return true;
    }

    final completedRound = _registerCompletedTurn();
    if (completedRound != null &&
        await _applyPurgeDamageForCompletedRound(completedRound)) {
      return true;
    }

    return false;
  }

  Future<void> _playTurnStartDebuffDamageAnimations({
    required BattleTurnState activeTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
  }) async {
    final affectedSide = activeTurn == BattleTurnState.player
        ? BattleCombatantSide.player
        : BattleCombatantSide.enemy;
    final affectedBefore =
        affectedSide == BattleCombatantSide.player ? playerBefore : enemyBefore;

    final burnApplicationCount = _burnApplicationCountFor(affectedBefore);
    if (burnApplicationCount <= 0) return;

    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.burnDamage,
        primarySide: affectedSide,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerBefore,
        enemyAfter: enemyBefore,
        effectCount: burnApplicationCount,
      ),
    );
  }

  Future<void> _playTurnEndDebuffDamageAnimations({
    required BattleTurnState completedTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
  }) async {
    final affectedSide = completedTurn == BattleTurnState.player
        ? BattleCombatantSide.player
        : BattleCombatantSide.enemy;
    final affectedBefore =
        affectedSide == BattleCombatantSide.player ? playerBefore : enemyBefore;

    final poisonStackCount = _poisonStackCountFor(affectedBefore);
    if (poisonStackCount > 0) {
      await _playCombatAnimation(
        BattleCombatAnimationCue(
          hook: BattleCombatAnimationHook.poisonDamage,
          primarySide: affectedSide,
          playerBefore: playerBefore,
          enemyBefore: enemyBefore,
          playerAfter: playerBefore,
          enemyAfter: enemyBefore,
          effectCount: poisonStackCount,
        ),
      );
    }
  }

  int _burnApplicationCountFor(Battler battler) {
    return _animationCueProducer.burnApplicationCountFor(battler);
  }

  int _poisonStackCountFor(Battler battler) {
    return _animationCueProducer.poisonStackCountFor(battler);
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      _buildTurnStartDebuffFloatingNumbers({
    required BattleTurnState activeTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    return _animationCueProducer.turnStartDebuffFloatingNumbers(
      activeTurn: activeTurn,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
    );
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      _buildTurnEndDebuffFloatingNumbers({
    required BattleTurnState completedTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    return _animationCueProducer.turnEndDebuffFloatingNumbers(
      completedTurn: completedTurn,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
    );
  }

  int? _registerCompletedTurn() {
    return _turnCoordinator.registerCompletedTurn();
  }

  Future<bool> _applyPurgeDamageForCompletedRound(int completedRound) async {
    final playerBefore = _player;
    final enemyBefore = _enemy;
    final resolution = _applyPurgeDamage(
      player: playerBefore,
      enemy: enemyBefore,
      round: completedRound,
    );
    if (resolution.player == playerBefore && resolution.enemy == enemyBefore) {
      return false;
    }

    await _playPurgeDamageAnimation(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: resolution.player,
      enemyAfter: resolution.enemy,
    );
    if (_isDisposed) return true;
    _player = resolution.player;
    _enemy = resolution.enemy;
    notifyListeners();

    final finish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (finish != null) {
      _finishCombat(
        resultType: finish.resultType,
        resultText: finish.resultText,
      );
      return true;
    }

    return false;
  }

  BattleTurnResolution _applyPurgeDamage({
    required Battler player,
    required Battler enemy,
    required int round,
  }) {
    return _purgeService.applyDamage(
      player: player,
      enemy: enemy,
      round: round,
      doctrine: _player.purgeDoctrine,
    );
  }

  Future<void> _playPurgeDamageAnimation({
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) async {
    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.purgeDamage,
        primarySide: BattleCombatantSide.player,
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerAfter,
        enemyAfter: enemyAfter,
        floatingNumbersBySide: <BattleCombatantSide,
            List<BattleCombatFloatingNumberCue>>{
          BattleCombatantSide.player: _buildPurgeFloatingNumbers(
            before: playerBefore,
            after: playerAfter,
          ),
          BattleCombatantSide.enemy: _buildPurgeFloatingNumbers(
            before: enemyBefore,
            after: enemyAfter,
          ),
        },
      ),
    );
  }

  List<BattleCombatFloatingNumberCue> _buildPurgeFloatingNumbers({
    required Battler before,
    required Battler after,
  }) {
    return _animationCueProducer.purgeFloatingNumbers(
      before: before,
      after: after,
    );
  }

  Future<void> _applyActionBarrierToPlayer(int amount) async {
    final playerBefore = _player;
    final enemyBefore = _enemy;
    final playerAfter = _applyActionBarrier(_player, amount);
    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyBefore,
    );
    if (_isDisposed) return;
    _player = playerAfter;
  }

  Future<void> _applyPlayerHealing(int amount) async {
    final playerBefore = _player;
    final enemyBefore = _enemy;
    final playerAfter = _player.heal(amount);
    await _playHealingActionAnimation(
      healerSide: BattleCombatantSide.player,
      healerBefore: playerBefore,
      opponentBefore: enemyBefore,
      healerAfter: playerAfter,
      opponentAfter: enemyBefore,
    );
    if (_isDisposed) return;
    _player = playerAfter;
  }

  Battler _applyActionBarrier(Battler battler, int amount) {
    return _stateReducer.gainActionBarrier(battler, amount);
  }

  Battler _applyBarrierGain(Battler battler, int amount) {
    return _stateReducer.gainBarrier(battler, amount);
  }

  int _playerCurrentBlockBarrierGain() {
    return max(0, _playerInitialBlockBarrier - _playerBlockUseCount);
  }

  EnemyTurnAction _rollEnemyTurnAction() {
    return _enemyAi.rollNextAction(
      enemy: _enemy,
      player: _player,
      randomizer: _randomizer,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimers();
    super.dispose();
  }
}

class _BattleUsedPattern {
  final List<String> pointKeys;
  final int usedRound;

  const _BattleUsedPattern({
    required this.pointKeys,
    required this.usedRound,
  });
}

class _ActionPileModifiers {
  int attack = 0;
  int barrier = 0;
  int heal = 0;
}

class _BattleAttackHitResolution {
  final _BattleAttackHitCombatant primaryCombatant;
  final BattleCombatMotionAsset motionAsset;
  final Battler attackerBefore;
  final Battler defenderBefore;
  final Battler attackerAfter;
  final Battler defenderAfter;
  final int damageDealt;

  const _BattleAttackHitResolution({
    required this.primaryCombatant,
    required this.motionAsset,
    required this.attackerBefore,
    required this.defenderBefore,
    required this.attackerAfter,
    required this.defenderAfter,
    required this.damageDealt,
  });
}

enum _BattleAttackHitCombatant {
  attacker,
  defender,
}

class _DirectDamageResolution {
  final Battler source;
  final Battler target;
  final int damageDealt;

  const _DirectDamageResolution({
    required this.source,
    required this.target,
    required this.damageDealt,
  });
}

class _DesafioConsumption {
  final Battler owner;
  final int value;
  final bool preventsCounterattack;

  const _DesafioConsumption({
    required this.owner,
    required this.value,
    required this.preventsCounterattack,
  });
}

class _UltimaPalabraResolution {
  final Battler owner;
  final Battler target;
  final int damageDealt;
  final List<_BattleAttackHitResolution> hits;

  const _UltimaPalabraResolution({
    required this.owner,
    required this.target,
    required this.damageDealt,
    required this.hits,
  });
}

class _BattleAttackHitVisualState {
  final Battler playerBefore;
  final Battler enemyBefore;
  final Battler playerAfter;
  final Battler enemyAfter;

  const _BattleAttackHitVisualState({
    required this.playerBefore,
    required this.enemyBefore,
    required this.playerAfter,
    required this.enemyAfter,
  });
}

class _BattleAttackActionResolution {
  final Battler attacker;
  final Battler defender;
  final int damageDealt;
  final List<_BattleAttackHitResolution> hits;
  final List<ItemFollowUpAction> followUpItemActions;

  const _BattleAttackActionResolution({
    required this.attacker,
    required this.defender,
    required this.damageDealt,
    required this.hits,
    this.followUpItemActions = const <ItemFollowUpAction>[],
  });
}

class _EnemyIntentAttackBreakdown {
  final int damagePerHit;
  final int hitCount;

  const _EnemyIntentAttackBreakdown({
    required this.damagePerHit,
    required this.hitCount,
  });
}

class _EnemyPreAttackResolution {
  final Battler enemy;
  final Battler player;

  const _EnemyPreAttackResolution({
    required this.enemy,
    required this.player,
  });
}

class _EnemyActionResolution {
  final Battler enemy;
  final Battler player;

  const _EnemyActionResolution({
    required this.enemy,
    required this.player,
  });
}
