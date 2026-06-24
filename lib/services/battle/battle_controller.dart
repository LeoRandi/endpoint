import '_imports.dart';

class BattleController extends ChangeNotifier {
  static const int patternBanRoundCount = 3;
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

    final playerAbilityCombatStart =
        _effectPipeline.applyAbilityCombatStartOpponentEffects(
      owner: _player,
      opponent: _enemy,
    );
    _player = playerAbilityCombatStart.owner;
    _enemy = playerAbilityCombatStart.opponent;

    final enemyAbilityCombatStart =
        _effectPipeline.applyAbilityCombatStartOpponentEffects(
      owner: _enemy,
      opponent: _player,
    );
    _enemy = enemyAbilityCombatStart.owner;
    _player = enemyAbilityCombatStart.opponent;

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

  Future<void> togglePlayerAbility(BattlerAbility ability) async {
    if (!canUseActions) return;

    final playerBefore = _player;
    final enemyBefore = _enemy;
    final selectedAbility = playerBefore.abilityById(ability.id);
    final shouldResolveCargaTemerariaAttack = selectedAbility?.id ==
            BattlerAbilityId.cargaTemeraria &&
        selectedAbility!.canActivateOn(BattlerAbilityActivationContext.battle);
    final shouldResolveMarcaDeCazaAttack =
        selectedAbility?.id == BattlerAbilityId.marcaDeCaza &&
            selectedAbility!.canActivateOn(
              BattlerAbilityActivationContext.battle,
            ) &&
            !_hasAnyDebuff(enemyBefore);
    final resolution = _effectPipeline.toggleAbilityActivation(
      owner: _player,
      abilityId: ability.id,
      screenContext: BattlerAbilityActivationContext.battle,
      opponent: _enemy,
    );
    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: resolution.owner,
      enemyAfter: resolution.opponent,
    );
    if (_isDisposed || !canUseActions) return;
    _player = resolution.owner;
    _enemy = resolution.opponent;

    final abilityFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (abilityFinish != null) {
      _finishCombat(
        resultType: abilityFinish.resultType,
        resultText: abilityFinish.resultText,
      );
      return;
    }

    if (shouldResolveMarcaDeCazaAttack) {
      final attackerBefore = _player;
      final defenderBefore = _enemy;
      final attackResolution = _resolveAttackAction(
        attacker: _player,
        defender: _enemy,
      );
      await _playAttackActionAnimations(
        attackerSide: BattleCombatantSide.player,
        attackerBefore: attackerBefore,
        defenderBefore: defenderBefore,
        resolution: attackResolution,
      );
      if (_isDisposed || !canUseActions) return;

      _player = attackResolution.attacker;
      _enemy = attackResolution.defender;
      final attackFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (attackFinish != null) {
        _finishCombat(
          resultType: attackFinish.resultType,
          resultText: attackFinish.resultText,
        );
        return;
      }
    }

    if (shouldResolveCargaTemerariaAttack) {
      final attackerBefore = _player;
      final defenderBefore = _enemy;
      final attackResolution = _resolveAttackAction(
        attacker: _player,
        defender: _enemy,
        challengeCounterattackBonus: 3,
      );
      await _playAttackActionAnimations(
        attackerSide: BattleCombatantSide.player,
        attackerBefore: attackerBefore,
        defenderBefore: defenderBefore,
        resolution: attackResolution,
      );
      if (_isDisposed || !canUseActions) return;

      _player = attackResolution.attacker;
      _enemy = attackResolution.defender;
      final attackFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (attackFinish != null) {
        _finishCombat(
          resultType: attackFinish.resultType,
          resultText: attackFinish.resultText,
        );
        return;
      }
    }

    notifyListeners();
  }

  bool _hasAnyDebuff(Battler battler) {
    return battler.statuses.any(
      (status) => status.type == BattlerStatusType.debuff,
    );
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
      final playerBeforePatternAbilities = _player;
      final enemyBeforePatternAbilities = _enemy;
      final abilityResolution = _player.applyAbilityPatternMatchResolvedEffects(
        opponent: _enemy,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforePatternAbilities,
        enemyBefore: enemyBeforePatternAbilities,
        playerAfter: abilityResolution.owner,
        enemyAfter: abilityResolution.opponent,
      );
      if (_isDisposed || !canUseActions) return;

      _player = abilityResolution.owner;
      _enemy = abilityResolution.opponent;
      final abilityFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (abilityFinish != null) {
        _finishCombat(
          resultType: abilityFinish.resultType,
          resultText: abilityFinish.resultText,
        );
        return;
      }

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
      final actions = _actionsForPatternItemUse(
        item: item,
        pattern: pattern,
        pointKey: pointKey,
      );
      var didResolveAction = false;
      final pendingActions = <({ActionEffect action, bool allowFollowUps})>[
        for (final action in actions) (action: action, allowFollowUps: true),
      ];

      while (pendingActions.isNotEmpty) {
        final pendingAction = pendingActions.removeAt(0);
        final action = pendingAction.action;
        didResolveAction = true;
        switch (action.actionType) {
          case ItemActionType.attack:
            final attackerBefore = _player;
            final defenderBefore = _enemy;
            final attackResolution = _resolveAttackAction(
              attacker: _player,
              defender: _enemy,
              baseDamageOverride: max(0, action.value + attackModifier),
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
            break;
          case ItemActionType.block:
            final playerBefore = _player;
            final enemyBefore = _enemy;
            _player = _applyBarrierGain(
              _player,
              max(0, action.value + blockModifier),
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
            _player = _player.heal(action.value + healModifier);
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
              effect: action,
              previousActions: List<ActionEffect>.unmodifiable(resolvedActions),
            );
            _player = resolution.owner;
            _enemy = resolution.opponent;
            if (pendingAction.allowFollowUps &&
                resolution.followUpActions.isNotEmpty) {
              pendingActions.insertAll(0, <({
                ActionEffect action,
                bool allowFollowUps,
              })>[
                for (final followUp in resolution.followUpActions)
                  (action: followUp, allowFollowUps: false),
              ]);
            }
            break;
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
      final enemyBeforePatternAbilities = _enemy;
      final playerBeforePatternAbilities = _player;
      final abilityResolution = _enemy.applyAbilityPatternMatchResolvedEffects(
        opponent: _player,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforePatternAbilities,
        enemyBefore: enemyBeforePatternAbilities,
        playerAfter: abilityResolution.opponent,
        enemyAfter: abilityResolution.owner,
      );
      if (_isDisposed || _turn != BattleTurnState.enemy) return;

      _enemy = abilityResolution.owner;
      _player = abilityResolution.opponent;
      final abilityFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (abilityFinish != null) {
        _finishCombat(
          resultType: abilityFinish.resultType,
          resultText: abilityFinish.resultText,
        );
        return;
      }

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
      final actions = _actionsForPatternItemUse(
        item: item,
        pattern: pattern,
        pointKey: pointKey,
      );
      var didResolveAction = false;
      final pendingActions = <({ActionEffect action, bool allowFollowUps})>[
        for (final action in actions) (action: action, allowFollowUps: true),
      ];

      while (pendingActions.isNotEmpty) {
        final pendingAction = pendingActions.removeAt(0);
        final action = pendingAction.action;
        didResolveAction = true;
        switch (action.actionType) {
          case ItemActionType.attack:
            final enemyBefore = _enemy;
            final playerBefore = _player;
            final attackResolution = _resolveAttackAction(
              attacker: _enemy,
              defender: _player,
              baseDamageOverride: max(0, action.value + attackModifier),
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
            break;
          case ItemActionType.block:
            final enemyBefore = _enemy;
            final playerBefore = _player;
            _enemy = _applyBarrierGain(
              _enemy,
              max(0, action.value + blockModifier),
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
            _enemy = _enemy.heal(action.value + healModifier);
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
              effect: action,
              previousActions: List<ActionEffect>.unmodifiable(resolvedActions),
            );
            _enemy = resolution.owner;
            _player = resolution.opponent;
            if (pendingAction.allowFollowUps &&
                resolution.followUpActions.isNotEmpty) {
              pendingActions.insertAll(0, <({
                ActionEffect action,
                bool allowFollowUps,
              })>[
                for (final followUp in resolution.followUpActions)
                  (action: followUp, allowFollowUps: false),
              ]);
            }
            break;
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
    history.removeWhere(
      (entry) => _currentRound - entry.usedRound >= patternBanRoundCount,
    );
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
    final abilityFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (abilityFinish != null) {
      _finishCombat(
        resultType: abilityFinish.resultType,
        resultText: abilityFinish.resultText,
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
    var updatedEnemy = enemy;
    var updatedPlayer = player;
    BattlerAbility? activatedBattleAbility;

    final hardReset = updatedEnemy.abilityById(BattlerAbilityId.hardReset);
    if (hardReset != null &&
        hardReset
            .canActivateOn(BattlerAbilityActivationContext.pathSelection) &&
        _shouldEnemyUseHardReset(updatedEnemy)) {
      final hardResetResolution = _effectPipeline.toggleAbilityActivation(
        owner: updatedEnemy,
        abilityId: hardReset.id,
        screenContext: BattlerAbilityActivationContext.pathSelection,
        opponent: updatedPlayer,
      );
      updatedEnemy = hardResetResolution.owner;
      updatedPlayer = hardResetResolution.opponent;
    }

    final manualBattleAbility = _pickEnemyBattleAbilityToActivate(updatedEnemy);
    if (manualBattleAbility != null) {
      final battleAbilityResolution = _effectPipeline.toggleAbilityActivation(
        owner: updatedEnemy,
        abilityId: manualBattleAbility.id,
        screenContext: BattlerAbilityActivationContext.battle,
        opponent: updatedPlayer,
      );
      updatedEnemy = battleAbilityResolution.owner;
      updatedPlayer = battleAbilityResolution.opponent;
      activatedBattleAbility =
          updatedEnemy.abilityById(manualBattleAbility.id) ??
              manualBattleAbility;
    }

    return _EnemyPreAttackResolution(
      enemy: updatedEnemy,
      player: updatedPlayer,
      activatedBattleAbility: activatedBattleAbility,
    );
  }

  BattlerAbility? _pickEnemyBattleAbilityToActivate(Battler enemy) {
    if (!enemy
        .canActivateManualAbilities(BattlerAbilityActivationContext.battle)) {
      return null;
    }

    for (final ability in enemy.abilities) {
      if (ability.canActivateOn(BattlerAbilityActivationContext.battle) &&
          ability.isImplemented) {
        return ability;
      }
    }

    return null;
  }

  bool _shouldEnemyUseHardReset(Battler enemy) {
    return enemy.statuses.any(
      (status) =>
          status.isPurgeable &&
          (status is QuemaduraStatus || status is IntoxicacionStatus),
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
      activatedBattleAbility: preAttackResolution.activatedBattleAbility,
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
        includeAttackResolvedAbilities: true,
      ),
      blockEffects: _actionIntentProducer.playerActionEffects(
        ownerBefore: _player,
        ownerAfter: defendResolution.defender,
        opponentBefore: _enemy,
        opponentAfter: defendResolution.opponent,
        includeAttackResolvedAbilities: false,
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
  }) {
    var updatedAttacker = attacker.removeCombatFlag(
      Battler.pendingBasicAttackFollowUpFlag,
    );
    var updatedDefender = defender;
    var totalDamageDealt = 0;
    final attackCount = attacker.basicAttackCount;
    final hits = <_BattleAttackHitResolution>[];

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
      );
      updatedAttacker = resolution.attacker.removeCombatFlag(
        Battler.pendingBasicAttackFollowUpFlag,
      );
      updatedDefender = resolution.defender;
      totalDamageDealt += resolution.damageDealt;
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

      final counterBeforeAttacker = updatedAttacker;
      final counterBeforeDefender = updatedDefender;
      final counterDamage = (max(1, (consumedDesafioValue + 1) ~/ 2) +
              max(0, challengeCounterattackBonus))
          .toInt();
      final counterResolution = _resolveDirectDamageOnly(
        source: updatedDefender,
        target: updatedAttacker,
        damage: counterDamage,
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
        updatedAttacker = _applySeguroRotoAfterDesafioCounter(updatedAttacker);
        updatedAttacker =
            _applyAceleradorRetoAfterSurvivingCounter(updatedAttacker);
      }

      if (updatedAttacker.isDefeated || updatedDefender.isDefeated) {
        continue;
      }

      final ultimaPalabraResolution = _resolveUltimaPalabraAfterCounter(
        owner: updatedAttacker,
        target: updatedDefender,
      );
      updatedAttacker = ultimaPalabraResolution.owner;
      updatedDefender = ultimaPalabraResolution.target;
      totalDamageDealt += ultimaPalabraResolution.damageDealt;
      hits.addAll(ultimaPalabraResolution.hits);
    }

    return _BattleAttackActionResolution(
      attacker: updatedAttacker.removeCombatFlag(
        Battler.pendingBasicAttackFollowUpFlag,
      ),
      defender: updatedDefender,
      damageDealt: totalDamageDealt,
      hits: List<_BattleAttackHitResolution>.unmodifiable(hits),
    );
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

    var updatedOwner = owner.removeStatusInstance(status);
    var preventsCounterattack = false;
    final mandato = updatedOwner.abilityById(BattlerAbilityId.mandatoColiseo);
    if (mandato != null &&
        !updatedOwner.hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.mandatoColiseoCounterPreventedThisTurn,
          ),
        )) {
      preventsCounterattack = true;
      updatedOwner = updatedOwner.addCombatFlag(
        const CombatRuntimeFlag.battler(
          BattlerCombatFlag.mandatoColiseoCounterPreventedThisTurn,
        ),
      );
    }

    return _DesafioConsumption(
      owner: updatedOwner,
      value: max(0, status.resolved(owner).value),
      preventsCounterattack: preventsCounterattack,
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
    final incomingAbilityModifiedDamage =
        _effectPipeline.applyAbilityIncomingDamageModifiers(
      owner: target,
      source: source,
      damage: incomingStatusModifiedDamage,
    );
    final incomingItemModifiedDamage =
        _effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: target,
      source: source,
      damage: incomingAbilityModifiedDamage,
    );
    final incomingEffectResolution = _effectPipeline.applyIncomingDamageEffects(
      owner: target,
      source: source,
      damage: incomingItemModifiedDamage,
      kind: DamageKind.direct,
    );
    final damageDealt = incomingEffectResolution.damage;
    var updatedTarget = _receiveDamageWithBarrierIgnore(
      owner: incomingEffectResolution.owner,
      damage: damageDealt,
      barrierIgnore: barrierIgnore,
    );
    if (updatedTarget.isDefeated && damageDealt > 0) {
      updatedTarget = _effectPipeline.applyAbilityFatalDamageEffects(
        owner: updatedTarget,
        incomingDamage: damageDealt,
      );
    }
    var updatedSource = source;

    updatedTarget = _effectPipeline.applyReceiveDamageResolvedEffects(
      owner: updatedTarget,
      source: updatedSource,
      damageTaken: damageDealt,
    );
    final receiveAbilityResolution =
        _effectPipeline.applyAbilityReceiveDamageResolvedEffects(
      owner: updatedTarget,
      source: updatedSource,
      damageTaken: damageDealt,
    );
    updatedTarget = receiveAbilityResolution.owner;
    updatedSource = receiveAbilityResolution.opponent;
    final receiveItemResolution =
        _effectPipeline.applyEquippedItemReceiveDamageResolvedEffects(
      owner: updatedTarget,
      source: updatedSource,
      damageTaken: damageDealt,
    );
    updatedTarget = receiveItemResolution.owner;
    updatedSource = receiveItemResolution.opponent;

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

  const _BattleAttackActionResolution({
    required this.attacker,
    required this.defender,
    required this.damageDealt,
    required this.hits,
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
  final BattlerAbility? activatedBattleAbility;

  const _EnemyPreAttackResolution({
    required this.enemy,
    required this.player,
    required this.activatedBattleAbility,
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
