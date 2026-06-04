import '_imports.dart';

enum BattleTurnState {
  player,
  enemy,
  finished,
}

enum EnemyTurnAction {
  attack,
  defend,
}

enum EnemyAiDifficultyLevel {
  alpha,
  beta,
  omega,
}

enum BattleCombatantSide {
  player,
  enemy,
}

enum BattleCombatAnimationHook {
  attackMotion,
  blockMotion,
  burnDamage,
  poisonDamage,
  damageTaken,
  healthLoss,
  healthGain,
  barrierGain,
  barrierLoss,
  fragilidadBurst,
  moneyChange,
  purgeDamage,
}

enum BattleCombatMotionAsset {
  sword,
  shield,
  fist,
}

enum BattleCombatFloatingNumberTone {
  healthDamage,
  barrierDamage,
  burnDamage,
  poisonDamage,
  healing,
  barrierGain,
  fragilidadDamage,
  moneyGain,
  moneyLoss,
  purgeDamage,
}

class BattleCombatFloatingNumberCue {
  final BattleCombatFloatingNumberTone tone;
  final int amount;

  const BattleCombatFloatingNumberCue({
    required this.tone,
    required this.amount,
  }) : assert(amount > 0);
}

class BattleCombatAnimationCue {
  final BattleCombatAnimationHook hook;
  final BattleCombatantSide primarySide;
  final BattleCombatantSide? secondarySide;
  final Battler playerBefore;
  final Battler enemyBefore;
  final Battler playerAfter;
  final Battler enemyAfter;
  final int effectCount;
  final BattleCombatMotionAsset motionAsset;
  final List<BattleCombatFloatingNumberCue> floatingNumbers;
  final Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      floatingNumbersBySide;

  const BattleCombatAnimationCue({
    required this.hook,
    required this.primarySide,
    this.secondarySide,
    required this.playerBefore,
    required this.enemyBefore,
    required this.playerAfter,
    required this.enemyAfter,
    this.effectCount = 1,
    this.motionAsset = BattleCombatMotionAsset.sword,
    this.floatingNumbers = const <BattleCombatFloatingNumberCue>[],
    this.floatingNumbersBySide =
        const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{},
  });
}

typedef BattleCombatAnimationCallback = Future<void> Function(
  BattleCombatAnimationCue cue,
);

class BattleController extends ChangeNotifier {
  static const int _purgeStartRound = 5;
  static const int _purgeWarningRound = _purgeStartRound - 2;
  static const int _purgeRampRoundCount = 5;
  static const int _purgeInitialDamage = 1;
  static const int _purgeInitialDamagePerRound = 1;
  static const int _purgeLateDamagePerRound = 2;

  final BattleResolver _resolver;
  final BattleTurnEngine _turnEngine;
  final BattlerEffectPipeline _effectPipeline;
  final RunRandomizer _randomizer;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final BattleCombatAnimationCallback? onCombatAnimation;
  final EnemyAiDifficultyLevel _enemyAiDifficulty;

  Battler _enemy;
  Battler _player;
  EnemyTurnAction _enemyNextAction = EnemyTurnAction.attack;
  EnemyTurnAction? _enemyLastResolvedAction;
  int _enemySameActionStreak = 0;
  int _currentRound = 1;
  int _completedTurnsInCurrentRound = 0;
  BattleTurnState _turn = BattleTurnState.player;
  String? _resultText;
  BattleFlowResult? _pendingExitResult;
  int _playerBlockUseCount = 0;
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
    this.onCombatAnimation,
  })  : _enemy = enemy.prepareForCombat(
          phase: phase,
        ),
        _player = player.prepareForCombat(
          phase: phase,
        ),
        _resolver = resolver,
        _effectPipeline = effectPipeline,
        _randomizer = randomizer ?? RunRandomizer(),
        _enemyAiDifficulty = _difficultyForEnemyTier(enemyTier),
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
  BattleTurnState get turn => _turn;
  bool get isPlayerTurn => _turn == BattleTurnState.player;
  bool get isEnemyTurn => _turn == BattleTurnState.enemy;
  bool get isCombatFinished => _turn == BattleTurnState.finished;
  bool get canUseActions => isPlayerTurn && !isCombatFinished;
  bool get canResolveEnemyPattern => isEnemyTurn && !isCombatFinished;
  int get currentRound => _currentRound;
  int get currentPurgeDamageAmount => _purgeDamageForRound(
        max(_purgeStartRound, _currentRound),
      );
  bool get isPurgeWarningVisible => _currentRound >= _purgeWarningRound;
  bool get isPurgeActive => _currentRound >= _purgeStartRound;
  int get playerPurgeDamagePreview => _purgeDamageForBattler(
        battler: _player,
        round: max(_purgeStartRound, _currentRound),
      );
  int get enemyPurgeDamagePreview => _purgeDamageForBattler(
        battler: _enemy,
        round: max(_purgeStartRound, _currentRound),
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
    switch (_turn) {
      case BattleTurnState.player:
        return 'TURNO DEL JUGADOR';
      case BattleTurnState.enemy:
        return 'TURNO ENEMIGO';
      case BattleTurnState.finished:
        return 'COMBATE FINALIZADO';
    }
  }

  String get turnDescription {
    switch (_turn) {
      case BattleTurnState.player:
        return 'Selecciona una accion.';
      case BattleTurnState.enemy:
        return 'El enemigo prepara su respuesta.';
      case BattleTurnState.finished:
        return _resultText ?? 'Resolviendo salida del combate...';
    }
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
    var resolvedActionBonus = actionBonus;

    if (resolvedActionBonus.healAmount > 0) {
      await _applyPlayerHealing(resolvedActionBonus.healAmount);
    }

    final resolvedPatternContext = patternContext;
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
      resolvedActionBonus = resolvedActionBonus.copyWith(
        attackBonus: max(
          0,
          resolvedActionBonus.attackBonus +
              preAttackItemResolution.attackBonusDelta,
        ),
        immediateBarrierAmount: max(
          0,
          resolvedActionBonus.immediateBarrierAmount +
              preAttackItemResolution.barrierBonusDelta,
        ),
      );
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

    final countsAsAttack = resolvedActionBonus.attackBonus >=
        resolvedActionBonus.immediateBarrierAmount;
    final countsAsDefend = resolvedActionBonus.immediateBarrierAmount >=
        resolvedActionBonus.attackBonus;

    final attackerBefore = _player;
    final defenderBefore = _enemy;
    final attackResolution = _resolveAttackAction(
      attacker: _player,
      defender: _enemy,
      flatAttackBonus: resolvedActionBonus.attackBonus,
      triggerAttackResolvedEffects: countsAsAttack,
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

    if (countsAsDefend || resolvedActionBonus.immediateBarrierAmount > 0) {
      final patternDefenderBefore = _player;
      final patternOpponentBefore = _enemy;
      final defendResolution = _resolveDefendAction(
        defender: _player,
        opponent: _enemy,
        barrierGain: resolvedActionBonus.immediateBarrierAmount,
      );
      await _playBlockResolutionAnimation(
        defenderSide: BattleCombatantSide.player,
        defenderBefore: patternDefenderBefore,
        opponentBefore: patternOpponentBefore,
        defenderAfter: defendResolution.defender,
        opponentAfter: defendResolution.opponent,
      );
      if (_isDisposed || !canUseActions) return;

      _player = defendResolution.defender;
      _enemy = defendResolution.opponent;
    }

    if (resolvedPatternContext != null) {
      final playerBeforeItemUse = _player;
      final enemyBeforeItemUse = _enemy;
      final itemUseResolution = _player.applyEquippedItemPatternUsedEffects(
        opponent: _enemy,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBeforeItemUse,
        enemyBefore: enemyBeforeItemUse,
        playerAfter: itemUseResolution.owner,
        enemyAfter: itemUseResolution.opponent,
      );
      if (_isDisposed || !canUseActions) return;

      _player = itemUseResolution.owner;
      _enemy = itemUseResolution.opponent;
      final itemUseFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (itemUseFinish != null) {
        _finishCombat(
          resultType: itemUseFinish.resultType,
          resultText: itemUseFinish.resultText,
        );
        return;
      }
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

  Future<void> handleEnemyPatternMatch({
    BattleActionBonus actionBonus = BattleActionBonus.empty,
    BattlePatternMatchContext? patternContext,
  }) async {
    if (!canResolveEnemyPattern) return;

    var resolvedActionBonus = actionBonus;
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
      resolvedActionBonus = resolvedActionBonus.copyWith(
        attackBonus: max(
          0,
          resolvedActionBonus.attackBonus +
              preAttackItemResolution.attackBonusDelta,
        ),
        immediateBarrierAmount: max(
          0,
          resolvedActionBonus.immediateBarrierAmount +
              preAttackItemResolution.barrierBonusDelta,
        ),
      );
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

    final attackerBefore = _enemy;
    final defenderBefore = _player;
    final attackResolution = _resolveAttackAction(
      attacker: _enemy,
      defender: _player,
      flatAttackBonus: resolvedActionBonus.attackBonus,
      triggerAttackResolvedEffects: true,
    );
    await _playAttackActionAnimations(
      attackerSide: BattleCombatantSide.enemy,
      attackerBefore: attackerBefore,
      defenderBefore: defenderBefore,
      resolution: attackResolution,
    );
    if (_isDisposed || _turn != BattleTurnState.enemy) return;

    _enemy = attackResolution.attacker;
    _player = attackResolution.defender;

    if (resolvedActionBonus.immediateBarrierAmount > 0) {
      final defenderBeforeBarrier = _enemy;
      final opponentBeforeBarrier = _player;
      final defendResolution = _resolveDefendAction(
        defender: _enemy,
        opponent: _player,
        barrierGain: resolvedActionBonus.immediateBarrierAmount,
      );
      await _playBlockResolutionAnimation(
        defenderSide: BattleCombatantSide.enemy,
        defenderBefore: defenderBeforeBarrier,
        opponentBefore: opponentBeforeBarrier,
        defenderAfter: defendResolution.defender,
        opponentAfter: defendResolution.opponent,
      );
      if (_isDisposed || _turn != BattleTurnState.enemy) return;
      _enemy = defendResolution.defender;
      _player = defendResolution.opponent;
    }

    if (resolvedPatternContext != null) {
      final itemUseEnemyBefore = _enemy;
      final itemUsePlayerBefore = _player;
      final itemUseResolution = _enemy.applyEquippedItemPatternUsedEffects(
        opponent: _player,
        pattern: resolvedPatternContext,
      );
      await _playCombatStateTransitionAnimations(
        playerBefore: itemUsePlayerBefore,
        enemyBefore: itemUseEnemyBefore,
        playerAfter: itemUseResolution.opponent,
        enemyAfter: itemUseResolution.owner,
      );
      if (_isDisposed || _turn != BattleTurnState.enemy) return;
      _enemy = itemUseResolution.owner;
      _player = itemUseResolution.opponent;

      final itemUseFinish = _turnEngine.finishFor(
        player: _player,
        enemy: _enemy,
      );
      if (itemUseFinish != null) {
        _finishCombat(
          resultType: itemUseFinish.resultType,
          resultText: itemUseFinish.resultText,
        );
        return;
      }
    }

    _registerEnemyResolvedAction(EnemyTurnAction.attack);
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.enemy)) {
      return;
    }

    _enemyNextAction = _rollEnemyTurnAction();
    await _beginTurn(BattleTurnState.player);
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

    _registerEnemyResolvedAction(plannedAction);
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
        _combatDurabilityOf(initialPlayer) -
            _combatDurabilityOf(predictedPlayer));
    final barrierGain =
        max(0, predictedEnemy.currentBarrier - initialEnemy.currentBarrier);

    return EnemyTurnIntentPreview(
      action: plannedAction,
      activatedBattleAbility: preAttackResolution.activatedBattleAbility,
      damage: damage,
      attackHitDamage: attackBreakdown?.damagePerHit ?? damage,
      attackHitCount: attackBreakdown?.hitCount ?? 1,
      barrierGain: barrierGain,
      appliedDebuffs: _buildAppliedDebuffIntents(
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
      _combatDurabilityOf(_enemy) -
          _combatDurabilityOf(attackResolution.defender),
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
      attackEffects: _buildPlayerActionEffectIntents(
        ownerBefore: _player,
        ownerAfter: attackResolution.attacker,
        opponentBefore: _enemy,
        opponentAfter: attackResolution.defender,
        includeAttackResolvedAbilities: true,
      ),
      blockEffects: _buildPlayerActionEffectIntents(
        ownerBefore: _player,
        ownerAfter: defendResolution.defender,
        opponentBefore: _enemy,
        opponentAfter: defendResolution.opponent,
        includeAttackResolvedAbilities: false,
      ),
    );
  }

  int _combatDurabilityOf(Battler battler) {
    return max(0, battler.health) + max(0, battler.currentBarrier);
  }

  List<PlayerActionEffectIntent> _buildPlayerActionEffectIntents({
    required Battler ownerBefore,
    required Battler ownerAfter,
    required Battler opponentBefore,
    required Battler opponentAfter,
    required bool includeAttackResolvedAbilities,
  }) {
    final intents = <PlayerActionEffectIntent>[];
    final ownerHealthGain = max(0, ownerAfter.health - ownerBefore.health);
    if (ownerHealthGain > 0) {
      intents.add(PlayerActionEffectIntent.heal(ownerHealthGain));
    }

    intents.addAll(
      _buildStatusDeltaIntents(
        before: ownerBefore,
        after: ownerAfter,
      ),
    );
    intents.addAll(
      _buildStatusDeltaIntents(
        before: opponentBefore,
        after: opponentAfter,
      ),
    );

    final abilityIntents = _buildAbilityEffectIntents(
      before: ownerBefore,
      after: ownerAfter,
      includeAttackResolvedAbilities: includeAttackResolvedAbilities,
      hasVisibleActionDelta: intents.isNotEmpty,
    );
    intents.addAll(abilityIntents);

    return List<PlayerActionEffectIntent>.unmodifiable(intents);
  }

  List<PlayerActionEffectIntent> _buildStatusDeltaIntents({
    required Battler before,
    required Battler after,
  }) {
    final beforeById = _statusIntentAmountsById(before);
    final afterById = _statusIntentAmountsById(after);
    final intents = <PlayerActionEffectIntent>[];

    for (final entry in afterById.entries) {
      final beforeAmount = beforeById[entry.key] ?? 0;
      final delta = entry.value - beforeAmount;
      if (delta <= 0) continue;

      final status = after.statusById(entry.key)?.resolved(after);
      if (status == null) continue;
      intents.add(PlayerActionEffectIntent.status(status, amount: delta));
    }

    return List<PlayerActionEffectIntent>.unmodifiable(intents);
  }

  Map<BattlerStatusId, int> _statusIntentAmountsById(Battler battler) {
    final amounts = <BattlerStatusId, int>{};
    for (final status in battler.statuses) {
      final resolvedStatus = status.resolved(battler);
      amounts.update(
        resolvedStatus.id,
        (value) => value + _statusIntentAmount(resolvedStatus),
        ifAbsent: () => _statusIntentAmount(resolvedStatus),
      );
    }
    return amounts;
  }

  int _statusIntentAmount(BattlerStatus status) {
    if (status.value > 0) return status.value;
    if (!status.isIndefinite && status.remainingTurns > 0) {
      return status.remainingTurns;
    }
    return 1;
  }

  List<PlayerActionEffectIntent> _buildAbilityEffectIntents({
    required Battler before,
    required Battler after,
    required bool includeAttackResolvedAbilities,
    required bool hasVisibleActionDelta,
  }) {
    final intents = <PlayerActionEffectIntent>[];
    final addedAbilityIds = <BattlerAbilityId>{};

    for (final ability in before.abilities) {
      final updatedAbility = after.abilityById(ability.id);
      if (updatedAbility == null) continue;
      if (!_didAbilityRuntimeChange(ability, updatedAbility)) continue;

      intents.add(PlayerActionEffectIntent.ability(ability));
      addedAbilityIds.add(ability.id);
    }

    if (!includeAttackResolvedAbilities || !hasVisibleActionDelta) {
      return List<PlayerActionEffectIntent>.unmodifiable(intents);
    }

    for (final abilityId in before.abilityIdsForHook(
      BattlerAbilityHook.attackResolved,
    )) {
      if (addedAbilityIds.contains(abilityId)) continue;
      final ability = before.abilityById(abilityId);
      if (ability == null || !ability.isPassive || !ability.isImplemented) {
        continue;
      }

      intents.add(PlayerActionEffectIntent.ability(ability));
      addedAbilityIds.add(ability.id);
    }

    return List<PlayerActionEffectIntent>.unmodifiable(intents);
  }

  bool _didAbilityRuntimeChange(
    BattlerAbility before,
    BattlerAbility after,
  ) {
    return before.isActive != after.isActive ||
        before.remainingCooldownTurns != after.remainingCooldownTurns ||
        before.runtimeValueBonus != after.runtimeValueBonus;
  }

  List<EnemyTurnDebuffIntent> _buildAppliedDebuffIntents({
    required Battler before,
    required Battler after,
  }) {
    final beforeCounts = <String, int>{};
    for (final status in before.statuses) {
      if (status.type != BattlerStatusType.debuff) continue;
      final resolvedStatus = status.resolved(before);
      final key = _statusIntentKey(resolvedStatus);
      beforeCounts[key] = (beforeCounts[key] ?? 0) + 1;
    }

    final intents = <EnemyTurnDebuffIntent>[];
    for (final status in after.statuses) {
      if (status.type != BattlerStatusType.debuff) continue;
      final resolvedStatus = status.resolved(after);
      final key = _statusIntentKey(resolvedStatus);
      final previousCount = beforeCounts[key] ?? 0;
      if (previousCount > 0) {
        beforeCounts[key] = previousCount - 1;
        continue;
      }

      intents.add(
        EnemyTurnDebuffIntent(
          status: resolvedStatus,
          amountLabel: resolvedStatus.badgeLabelFor(after),
        ),
      );
    }

    return List<EnemyTurnDebuffIntent>.unmodifiable(intents);
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

  String _statusIntentKey(BattlerStatus status) {
    return '${status.id.name}|${status.remainingTurns}|${status.value}';
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

  _DefendActionResolution _resolveDefendAction({
    required Battler defender,
    required Battler opponent,
    required int barrierGain,
  }) {
    final updatedDefender = barrierGain > 0
        ? _applyBarrierGain(
            defender,
            barrierGain,
          )
        : defender;
    final itemResolution =
        updatedDefender.applyEquippedItemDefendResolvedEffects(
      opponent: opponent,
    );
    return _DefendActionResolution(
      defender: itemResolution.owner,
      opponent: itemResolution.opponent,
    );
  }

  _BattleAttackActionResolution _resolveAttackAction({
    required Battler attacker,
    required Battler defender,
    int flatAttackBonus = 0,
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
    var updatedOwner = owner;
    for (final item in owner.equippedItems) {
      if (item.id != ItemId.guanteReto) continue;
      if (updatedOwner.itemCombatFlagUseCount(
            item: item,
            kind: ItemCombatFlagKind.guanteRetoTriggered,
          ) >=
          1) {
        continue;
      }

      updatedOwner = updatedOwner
          .addItemCombatFlagUse(
            item: item,
            kind: ItemCombatFlagKind.guanteRetoTriggered,
          )
          .gainDesafio(max(1, item.value));
    }

    return updatedOwner;
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
    var barrierIgnore = 0;
    for (final item in owner.equippedItems) {
      if (item.id != ItemId.visorApertura) continue;
      barrierIgnore = max(barrierIgnore, max(1, item.value));
    }

    return barrierIgnore;
  }

  Battler _applySeguroRotoAfterDesafioCounter(Battler owner) {
    var updatedOwner = owner;
    for (final item in owner.equippedItems) {
      if (item.id != ItemId.seguroRoto) continue;
      updatedOwner = updatedOwner.applyStatus(
        DesafioExcitanteStatus(value: max(1, item.value)),
        applyEquipmentModifiers: false,
      );
    }

    return updatedOwner;
  }

  Battler _applyAceleradorRetoAfterSurvivingCounter(Battler owner) {
    var updatedOwner = owner;
    for (final item in owner.equippedItems) {
      if (item.id != ItemId.aceleradorReto) continue;
      if (updatedOwner.itemCombatFlagUseCount(
            item: item,
            kind: ItemCombatFlagKind.aceleradorRetoTriggered,
          ) >=
          max(1, item.value)) {
        continue;
      }

      updatedOwner = updatedOwner
          .applyStatus(
            DesafioExcitanteStatus(value: max(1, item.value)),
            applyEquipmentModifiers: false,
          )
          .addItemCombatFlagUse(
            item: item,
            kind: ItemCombatFlagKind.aceleradorRetoTriggered,
          );
    }

    return updatedOwner;
  }

  _UltimaPalabraResolution _resolveUltimaPalabraAfterCounter({
    required Battler owner,
    required Battler target,
  }) {
    var updatedOwner = owner;
    var updatedTarget = target;
    var totalDamageDealt = 0;
    final hits = <_BattleAttackHitResolution>[];

    for (final item in owner.equippedItems) {
      if (item.id != ItemId.ultimaPalabra) continue;
      final alreadyTriggered = updatedOwner.itemCombatFlagValue(
            item: item,
            kind: ItemCombatFlagKind.ultimaPalabraTriggeredThisTurn,
          ) ==
          updatedOwner.combatRound;
      if (alreadyTriggered) continue;

      final ownerBefore = updatedOwner;
      final targetBefore = updatedTarget;
      final resolution = _resolver.resolveAttack(
        attacker: updatedOwner,
        defender: updatedTarget,
        flatAttackBonus: max(0, item.value),
      );
      updatedOwner = resolution.attacker.addCombatFlag(
        CombatRuntimeFlag.item(
          itemFlag: ItemCombatFlagKind.ultimaPalabraTriggeredThisTurn,
          itemId: item.id,
          itemInstanceId: item.instanceId,
          value: updatedOwner.combatRound,
        ),
      );
      updatedTarget = resolution.defender;
      totalDamageDealt += resolution.damageDealt;
      hits.add(
        _BattleAttackHitResolution(
          primaryCombatant: _BattleAttackHitCombatant.attacker,
          motionAsset: BattleCombatMotionAsset.sword,
          attackerBefore: ownerBefore,
          defenderBefore: targetBefore,
          attackerAfter: updatedOwner,
          defenderAfter: updatedTarget,
          damageDealt: resolution.damageDealt,
        ),
      );

      if (updatedOwner.isDefeated || updatedTarget.isDefeated) break;
    }

    return _UltimaPalabraResolution(
      owner: updatedOwner,
      target: updatedTarget,
      damageDealt: totalDamageDealt,
      hits: List<_BattleAttackHitResolution>.unmodifiable(hits),
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
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) return owner;

    final ownerBeforeDamage = owner
        .removeCombatFlagsFor(BattlerCombatFlag.barrierBrokenThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.barrierLostThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.healthLostThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.fragilidadTriggeredThisHit);
    final bypassDamage = min(
      safeDamage,
      min(max(0, barrierIgnore), ownerBeforeDamage.currentBarrier),
    ).toInt();
    final blockableDamage = max(0, safeDamage - bypassDamage).toInt();
    final absorbedByBarrier = min(
      ownerBeforeDamage.currentBarrier,
      blockableDamage,
    ).toInt();
    final healthDamage =
        (bypassDamage + max(0, blockableDamage - absorbedByBarrier)).toInt();

    var updatedOwner = ownerBeforeDamage;
    if (absorbedByBarrier > 0) {
      updatedOwner = updatedOwner
          .copyWith(
            currentBarrier: max(
              0,
              updatedOwner.currentBarrier - absorbedByBarrier,
            ),
          )
          .addCombatFlag(
            CombatRuntimeFlag.battler(
              BattlerCombatFlag.barrierLostThisHit,
              secondaryValue: absorbedByBarrier,
            ),
          );
      if (ownerBeforeDamage.currentBarrier > 0 &&
          updatedOwner.currentBarrier <= 0) {
        updatedOwner = updatedOwner.addCombatFlag(
          Battler.barrierBrokenThisHitFlag,
        );
      }
    }

    if (healthDamage <= 0) return updatedOwner;

    final damagedOwner = updatedOwner
        .copyWith(
          health: max(0, updatedOwner.health - healthDamage).toInt(),
        )
        .addCombatFlag(
          CombatRuntimeFlag.battler(
            BattlerCombatFlag.healthLostThisHit,
            secondaryValue: healthDamage,
          ),
        );
    if (damagedOwner.health > 0) return damagedOwner;

    return damagedOwner.applyEquippedItemFatalDamageEffects(
      incomingDamage: healthDamage,
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

  Future<void> _playCombatStateTransitionAnimations({
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
    Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>> floatingNumbersBySide =
        const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{},
  }) async {
    var visualPlayer = playerBefore;
    var visualEnemy = enemyBefore;
    final playerFragilidadDamage = playerBefore.health > playerAfter.health
        ? playerAfter.fragilidadTriggeredThisHit
        : 0;
    final enemyFragilidadDamage = enemyBefore.health > enemyAfter.health
        ? enemyAfter.fragilidadTriggeredThisHit
        : 0;
    final targetPlayerAfter = playerFragilidadDamage > 0
        ? playerAfter.copyWith(
            health: min(playerBefore.health,
                playerAfter.health + playerFragilidadDamage),
            statuses: playerBefore.statuses,
          )
        : playerAfter;
    final targetEnemyAfter = enemyFragilidadDamage > 0
        ? enemyAfter.copyWith(
            health: min(
                enemyBefore.health, enemyAfter.health + enemyFragilidadDamage),
            statuses: enemyBefore.statuses,
          )
        : enemyAfter;

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      final barrierLoss = after.currentBarrier < before.currentBarrier;
      final healthLoss = after.health < before.health;
      if (!barrierLoss && !healthLoss) continue;

      final hook = barrierLoss && healthLoss
          ? BattleCombatAnimationHook.damageTaken
          : healthLoss
              ? BattleCombatAnimationHook.healthLoss
              : BattleCombatAnimationHook.barrierLoss;
      final next = _buildVisualBattlerTransition(
        before: before,
        after: after,
        includeHealth: healthLoss,
        includeBarrier: barrierLoss,
      );
      final floatingNumbers = floatingNumbersBySide[side] ??
          _buildLossFloatingNumbers(
            before: before,
            after: after,
          );
      await _playCombatAnimation(
        _stateTransitionCue(
          hook: hook,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: floatingNumbers,
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      if (after.currentBarrier <= before.currentBarrier) continue;

      final next = _buildVisualBattlerTransition(
        before: before,
        after: after,
        includeBarrier: true,
      );
      await _playCombatAnimation(
        _stateTransitionCue(
          hook: BattleCombatAnimationHook.barrierGain,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: _buildGainFloatingNumbers(
            before: before,
            after: after,
            includeBarrier: true,
          ),
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      if (after.health <= before.health) continue;

      final next = _buildVisualBattlerTransition(
        before: before,
        after: after,
        includeHealth: true,
      );
      await _playCombatAnimation(
        _stateTransitionCue(
          hook: BattleCombatAnimationHook.healthGain,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: _buildGainFloatingNumbers(
            before: before,
            after: after,
            includeHealth: true,
          ),
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final fragilidadDamage = side == BattleCombatantSide.player
          ? playerFragilidadDamage
          : enemyFragilidadDamage;
      if (fragilidadDamage <= 0) continue;

      await _playCombatAnimation(
        _stateTransitionCue(
          hook: BattleCombatAnimationHook.fragilidadBurst,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter:
              side == BattleCombatantSide.player ? playerAfter : visualPlayer,
          enemyAfter:
              side == BattleCombatantSide.enemy ? enemyAfter : visualEnemy,
          floatingNumbers: <BattleCombatFloatingNumberCue>[
            BattleCombatFloatingNumberCue(
              tone: BattleCombatFloatingNumberTone.fragilidadDamage,
              amount: fragilidadDamage,
            ),
          ],
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = playerAfter;
      } else {
        visualEnemy = enemyAfter;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      final moneyDelta = after.money - before.money;
      if (moneyDelta == 0) continue;

      final next = before.copyWith(money: after.money);
      await _playCombatAnimation(
        _stateTransitionCue(
          hook: BattleCombatAnimationHook.moneyChange,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: <BattleCombatFloatingNumberCue>[
            BattleCombatFloatingNumberCue(
              tone: moneyDelta > 0
                  ? BattleCombatFloatingNumberTone.moneyGain
                  : BattleCombatFloatingNumberTone.moneyLoss,
              amount: moneyDelta.abs(),
            ),
          ],
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }
  }

  BattleCombatAnimationCue _stateTransitionCue({
    required BattleCombatAnimationHook hook,
    required BattleCombatantSide side,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
    List<BattleCombatFloatingNumberCue> floatingNumbers =
        const <BattleCombatFloatingNumberCue>[],
  }) {
    return BattleCombatAnimationCue(
      hook: hook,
      primarySide: side,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
      floatingNumbers: floatingNumbers,
    );
  }

  List<BattleCombatFloatingNumberCue> _buildLossFloatingNumbers({
    required Battler before,
    required Battler after,
  }) {
    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    return List<BattleCombatFloatingNumberCue>.unmodifiable([
      if (healthLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.healthDamage,
          amount: healthLoss,
        ),
      if (barrierLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierDamage,
          amount: barrierLoss,
        ),
    ]);
  }

  List<BattleCombatFloatingNumberCue> _buildGainFloatingNumbers({
    required Battler before,
    required Battler after,
    bool includeHealth = false,
    bool includeBarrier = false,
  }) {
    final healthGain = includeHealth ? max(0, after.health - before.health) : 0;
    final barrierGain = includeBarrier
        ? max(0, after.currentBarrier - before.currentBarrier)
        : 0;
    return List<BattleCombatFloatingNumberCue>.unmodifiable([
      if (healthGain > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.healing,
          amount: healthGain,
        ),
      if (barrierGain > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierGain,
          amount: barrierGain,
        ),
    ]);
  }

  Battler _buildVisualBattlerTransition({
    required Battler before,
    required Battler after,
    bool includeHealth = false,
    bool includeBarrier = false,
  }) {
    return before.copyWith(
      health: includeHealth ? after.health : before.health,
      currentBarrier:
          includeBarrier ? after.currentBarrier : before.currentBarrier,
    );
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

  Future<void> _resolveEmergencyPlatingAutoBlockForTurnStart(
    BattleTurnState activeTurn,
  ) async {
    final side = _combatantSideForTurn(activeTurn);
    if (side == null) return;

    final defender = side == BattleCombatantSide.player ? _player : _enemy;
    final opponent = side == BattleCombatantSide.player ? _enemy : _player;
    final item = _eligibleEmergencyPlatingAutoBlockItem(defender);
    if (item == null) return;

    final defendResolution = _resolveEmergencyPlatingAutoBlock(
      defender: defender,
      opponent: opponent,
      side: side,
      item: item,
    );
    await _playBlockResolutionAnimation(
      defenderSide: side,
      defenderBefore: defender,
      opponentBefore: opponent,
      defenderAfter: defendResolution.defender,
      opponentAfter: defendResolution.opponent,
    );
    if (_isDisposed) return;
    _applyDefendResolutionForSide(
      side: side,
      resolution: defendResolution,
    );
  }

  void _resolveEmergencyPlatingAutoBlockForTurnStartWithoutAnimation(
    BattleTurnState activeTurn,
  ) {
    final side = _combatantSideForTurn(activeTurn);
    if (side == null) return;

    final defender = side == BattleCombatantSide.player ? _player : _enemy;
    final opponent = side == BattleCombatantSide.player ? _enemy : _player;
    final item = _eligibleEmergencyPlatingAutoBlockItem(defender);
    if (item == null) return;

    final defendResolution = _resolveEmergencyPlatingAutoBlock(
      defender: defender,
      opponent: opponent,
      side: side,
      item: item,
    );
    _applyDefendResolutionForSide(
      side: side,
      resolution: defendResolution,
    );
  }

  _DefendActionResolution _resolveEmergencyPlatingAutoBlock({
    required Battler defender,
    required Battler opponent,
    required BattleCombatantSide side,
    required Item item,
  }) {
    final defendResolution = _resolveDefendAction(
      defender: defender,
      opponent: opponent,
      barrierGain: _blockBarrierGainForSide(side),
    );
    return _DefendActionResolution(
      defender: defendResolution.defender.addItemCombatFlagUse(
        item: item,
        kind: ItemCombatFlagKind.emergencyPlatingAutoBlockUsed,
      ),
      opponent: defendResolution.opponent,
    );
  }

  Item? _eligibleEmergencyPlatingAutoBlockItem(Battler battler) {
    if (battler.isDefeated ||
        battler.maxHealth <= 0 ||
        battler.health * 2 >= battler.maxHealth) {
      return null;
    }

    for (final item in battler.equippedItems) {
      if (item.id != ItemId.emergencyPlating) continue;
      final maxUses = max(1, item.value);
      final used = battler.itemCombatFlagUseCount(
        item: item,
        kind: ItemCombatFlagKind.emergencyPlatingAutoBlockUsed,
      );
      if (used < maxUses) {
        return item;
      }
    }

    return null;
  }

  BattleCombatantSide? _combatantSideForTurn(BattleTurnState activeTurn) {
    switch (activeTurn) {
      case BattleTurnState.player:
        return BattleCombatantSide.player;
      case BattleTurnState.enemy:
        return BattleCombatantSide.enemy;
      case BattleTurnState.finished:
        return null;
    }
  }

  int _blockBarrierGainForSide(BattleCombatantSide side) {
    return side == BattleCombatantSide.player
        ? _playerCurrentBlockBarrierGain()
        : _enemyInitialBlockBarrier;
  }

  void _applyDefendResolutionForSide({
    required BattleCombatantSide side,
    required _DefendActionResolution resolution,
  }) {
    if (side == BattleCombatantSide.player) {
      _player = resolution.defender;
      _enemy = resolution.opponent;
      return;
    }

    _enemy = resolution.defender;
    _player = resolution.opponent;
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

    await _resolveEmergencyPlatingAutoBlockForTurnStart(nextTurn);
    if (_isDisposed) return;
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
    _resolveEmergencyPlatingAutoBlockForTurnStartWithoutAnimation(nextTurn);

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
    return battler.statuses.whereType<QuemaduraStatus>().where((status) {
      return !status.isExpired && status.currentDamage(battler) > 0;
    }).length;
  }

  int _poisonStackCountFor(Battler battler) {
    final poison = battler.statusById(IntoxicacionStatus.statusId);
    if (poison is! IntoxicacionStatus || poison.isExpired) {
      return 0;
    }

    return max(0, poison.currentDamage(battler));
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      _buildTurnStartDebuffFloatingNumbers({
    required BattleTurnState activeTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    final affectedSide = activeTurn == BattleTurnState.player
        ? BattleCombatantSide.player
        : BattleCombatantSide.enemy;
    final before =
        affectedSide == BattleCombatantSide.player ? playerBefore : enemyBefore;
    final after =
        affectedSide == BattleCombatantSide.player ? playerAfter : enemyAfter;
    if (_burnApplicationCountFor(before) <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    if (barrierLoss <= 0 && healthLoss <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    final floatingNumbers = <BattleCombatFloatingNumberCue>[
      if (healthLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.burnDamage,
          amount: healthLoss,
        ),
      if (barrierLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierDamage,
          amount: barrierLoss,
        ),
    ];

    return <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{
      affectedSide: List<BattleCombatFloatingNumberCue>.unmodifiable(
        floatingNumbers,
      ),
    };
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      _buildTurnEndDebuffFloatingNumbers({
    required BattleTurnState completedTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    final affectedSide = completedTurn == BattleTurnState.player
        ? BattleCombatantSide.player
        : BattleCombatantSide.enemy;
    final before =
        affectedSide == BattleCombatantSide.player ? playerBefore : enemyBefore;
    final after =
        affectedSide == BattleCombatantSide.player ? playerAfter : enemyAfter;
    final poisonDamage = _poisonStackCountFor(before);
    if (poisonDamage <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    if (barrierLoss <= 0 && healthLoss <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    final floatingNumbers = <BattleCombatFloatingNumberCue>[];

    var remainingHealthLoss = healthLoss;
    if (poisonDamage > 0 && remainingHealthLoss > 0) {
      final poisonShown = min(poisonDamage, remainingHealthLoss);
      floatingNumbers.add(
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.poisonDamage,
          amount: poisonShown,
        ),
      );
      remainingHealthLoss -= poisonShown;
    }
    if (remainingHealthLoss > 0) {
      floatingNumbers.add(
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.healthDamage,
          amount: remainingHealthLoss,
        ),
      );
    }
    if (barrierLoss > 0) {
      floatingNumbers.add(
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierDamage,
          amount: barrierLoss,
        ),
      );
    }

    return <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{
      affectedSide: List<BattleCombatFloatingNumberCue>.unmodifiable(
        floatingNumbers,
      ),
    };
  }

  int? _registerCompletedTurn() {
    _completedTurnsInCurrentRound++;
    if (_completedTurnsInCurrentRound < 2) {
      return null;
    }

    final completedRound = _currentRound;
    _completedTurnsInCurrentRound = 0;
    _currentRound++;
    return completedRound;
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
    final playerDamage = _purgeDamageForBattler(
      battler: player,
      round: round,
    );
    final enemyDamage = _purgeDamageForBattler(
      battler: enemy,
      round: round,
    );

    return BattleTurnResolution(
      player: playerDamage > 0 ? player.receiveDamage(playerDamage) : player,
      enemy: enemyDamage > 0 ? enemy.receiveDamage(enemyDamage) : enemy,
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
    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    return List<BattleCombatFloatingNumberCue>.unmodifiable([
      if (healthLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.purgeDamage,
          amount: healthLoss,
        ),
      if (barrierLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.purgeDamage,
          amount: barrierLoss,
        ),
    ]);
  }

  int _purgeDamageForBattler({
    required Battler battler,
    required int round,
  }) {
    final purgeDamage = _purgeDamageForRound(round);
    if (battler.isDefeated || purgeDamage <= 0) {
      return 0;
    }

    return purgeDamage;
  }

  int _purgeDamageForRound(int round) {
    if (round < _purgeStartRound) {
      return 0;
    }

    final purgeCount = round - _purgeStartRound + 1;
    if (purgeCount <= _purgeRampRoundCount) {
      return _purgeInitialDamage +
          ((purgeCount - 1) * _purgeInitialDamagePerRound);
    }

    final rampEndDamage = _purgeInitialDamage +
        ((_purgeRampRoundCount - 1) * _purgeInitialDamagePerRound);
    return rampEndDamage +
        ((purgeCount - _purgeRampRoundCount) * _purgeLateDamagePerRound);
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
    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyBefore,
    );
    if (_isDisposed) return;
    _player = playerAfter;
  }

  Battler _applyActionBarrier(Battler battler, int amount) {
    // Los bonus de accion representan barrera temporal y no deben anularse
    // solo porque el tope base del battler sea cero.
    return battler.gainCombatBarrier(amount);
  }

  Battler _applyBarrierGain(Battler battler, int amount) {
    return battler.gainCombatBarrier(amount);
  }

  int _playerCurrentBlockBarrierGain() {
    return max(0, _playerInitialBlockBarrier - _playerBlockUseCount);
  }

  EnemyTurnAction _rollEnemyTurnAction() {
    final forcedAction = _forcedEnemyActionForDifficulty();
    if (forcedAction != null) {
      return forcedAction;
    }

    return _randomizer.chance(_enemyAttackChance())
        ? EnemyTurnAction.attack
        : EnemyTurnAction.defend;
  }

  EnemyTurnAction? _forcedEnemyActionForDifficulty() {
    if (_enemyAiDifficulty == EnemyAiDifficultyLevel.alpha ||
        _enemyLastResolvedAction == null ||
        _enemySameActionStreak < 2) {
      return null;
    }

    return _enemyLastResolvedAction == EnemyTurnAction.attack
        ? EnemyTurnAction.defend
        : EnemyTurnAction.attack;
  }

  double _enemyAttackChance() {
    final hasOmegaPriorityCheck =
        _enemyAiDifficulty == EnemyAiDifficultyLevel.omega &&
            _enemy.health < _player.health;
    if (hasOmegaPriorityCheck) {
      return 0.9;
    }

    final isAboveHalfHealth =
        _enemy.maxHealth > 0 && (_enemy.health * 2) > _enemy.maxHealth;
    return isAboveHalfHealth ? 0.75 : 0.25;
  }

  void _registerEnemyResolvedAction(EnemyTurnAction resolvedAction) {
    if (_enemyLastResolvedAction == resolvedAction) {
      _enemySameActionStreak++;
      return;
    }

    _enemyLastResolvedAction = resolvedAction;
    _enemySameActionStreak = 1;
  }

  static EnemyAiDifficultyLevel _difficultyForEnemyTier(int enemyTier) {
    final normalizedTier = max(1, enemyTier);
    if (normalizedTier >= RarityTier.yellow.factor) {
      return EnemyAiDifficultyLevel.omega;
    }
    if (normalizedTier >= RarityTier.blue.factor) {
      return EnemyAiDifficultyLevel.beta;
    }
    return EnemyAiDifficultyLevel.alpha;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimers();
    super.dispose();
  }
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

class _DefendActionResolution {
  final Battler defender;
  final Battler opponent;

  const _DefendActionResolution({
    required this.defender,
    required this.opponent,
  });
}

class EnemyTurnDebuffIntent {
  final BattlerStatus status;
  final String amountLabel;

  const EnemyTurnDebuffIntent({
    required this.status,
    required this.amountLabel,
  });
}

enum PlayerActionEffectIntentKind {
  heal,
  buff,
  debuff,
  ability,
}

class PlayerActionEffectIntent {
  final PlayerActionEffectIntentKind kind;
  final BattlerStatus? status;
  final BattlerAbility? ability;
  final int amount;

  const PlayerActionEffectIntent._({
    required this.kind,
    this.status,
    this.ability,
    this.amount = 0,
  });

  factory PlayerActionEffectIntent.heal(int amount) {
    return PlayerActionEffectIntent._(
      kind: PlayerActionEffectIntentKind.heal,
      amount: max(0, amount),
    );
  }

  factory PlayerActionEffectIntent.status(
    BattlerStatus status, {
    required int amount,
  }) {
    return PlayerActionEffectIntent._(
      kind: status.type == BattlerStatusType.buff
          ? PlayerActionEffectIntentKind.buff
          : PlayerActionEffectIntentKind.debuff,
      status: status,
      amount: max(0, amount),
    );
  }

  factory PlayerActionEffectIntent.ability(BattlerAbility ability) {
    return PlayerActionEffectIntent._(
      kind: PlayerActionEffectIntentKind.ability,
      ability: ability,
    );
  }
}

class PlayerActionIntentPreview {
  final int attackDamage;
  final int attackHitDamage;
  final int attackHitCount;
  final int blockBarrierGain;
  final List<PlayerActionEffectIntent> attackEffects;
  final List<PlayerActionEffectIntent> blockEffects;

  const PlayerActionIntentPreview({
    this.attackDamage = 0,
    this.attackHitDamage = 0,
    this.attackHitCount = 1,
    this.blockBarrierGain = 0,
    this.attackEffects = const <PlayerActionEffectIntent>[],
    this.blockEffects = const <PlayerActionEffectIntent>[],
  });

  String get attackDamageLabel {
    final resolvedHitCount = max(1, attackHitCount);
    if (resolvedHitCount > 1 && attackHitDamage > 0) {
      return '${max(0, attackHitDamage)}x$resolvedHitCount';
    }

    return '${max(0, attackDamage)}';
  }
}

class EnemyTurnIntentPreview {
  final EnemyTurnAction action;
  final BattlerAbility? activatedBattleAbility;
  final int damage;
  final int attackHitDamage;
  final int attackHitCount;
  final int barrierGain;
  final List<EnemyTurnDebuffIntent> appliedDebuffs;

  const EnemyTurnIntentPreview({
    this.action = EnemyTurnAction.attack,
    this.activatedBattleAbility,
    this.damage = 0,
    this.attackHitDamage = 0,
    this.attackHitCount = 1,
    this.barrierGain = 0,
    this.appliedDebuffs = const <EnemyTurnDebuffIntent>[],
  });

  String get damageLabel {
    final resolvedDamage =
        max(0, attackHitDamage > 0 ? attackHitDamage : damage);
    final resolvedHitCount = max(1, attackHitCount);
    if (resolvedHitCount <= 1) return '$resolvedDamage';

    return '${resolvedDamage}x$resolvedHitCount';
  }

  bool get hasAnyEffect {
    return activatedBattleAbility != null ||
        damage > 0 ||
        barrierGain > 0 ||
        appliedDebuffs.isNotEmpty;
  }
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
