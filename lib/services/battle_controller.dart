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
  damageTaken,
  healthLoss,
  healthGain,
  barrierGain,
  barrierLoss,
}

class BattleCombatAnimationCue {
  final BattleCombatAnimationHook hook;
  final BattleCombatantSide primarySide;
  final BattleCombatantSide? secondarySide;
  final Battler playerBefore;
  final Battler enemyBefore;
  final Battler playerAfter;
  final Battler enemyAfter;

  const BattleCombatAnimationCue({
    required this.hook,
    required this.primarySide,
    this.secondarySide,
    required this.playerBefore,
    required this.enemyBefore,
    required this.playerAfter,
    required this.enemyAfter,
  });
}

typedef BattleCombatAnimationCallback = Future<void> Function(
  BattleCombatAnimationCue cue,
);

class BattleController extends ChangeNotifier {
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
    _playerInitialBlockBarrier = max(0, _player.maxBarrier);
    _enemyInitialBlockBarrier = max(0, _enemy.maxBarrier);
    _enemyNextAction = _rollEnemyTurnAction();
    _beginTurnWithoutAnimation(BattleTurnState.player, notify: false);
  }

  Battler get enemy => _enemy;
  Battler get player => _player;
  BattleTurnState get turn => _turn;
  bool get isPlayerTurn => _turn == BattleTurnState.player;
  bool get isCombatFinished => _turn == BattleTurnState.finished;
  bool get canUseActions => isPlayerTurn && !isCombatFinished;
  int get currentRound => _currentRound;
  int get playerBlockBarrierGain => _playerCurrentBlockBarrierGain();
  int get playerInitialBarrier => _playerInitialBlockBarrier;
  EnemyTurnIntentPreview get enemyTurnIntentPreview =>
      _buildEnemyTurnIntentPreview();

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
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }
    notifyListeners();
  }

  Future<void> handleAttack({
    BattleAttackDrawingBonus drawingBonus = BattleAttackDrawingBonus.empty,
    BattleAttackDrawingPenalty drawingPenalty =
        BattleAttackDrawingPenalty.empty,
  }) async {
    if (!canUseActions) return;

    if (drawingPenalty.hasAnyPenalty) {
      await _applyDrawingPenalty(drawingPenalty);
      if (_finishImmediatelyIfPlayerIsDown()) {
        return;
      }
    }

    if (drawingBonus.healAmount > 0) {
      await _applyPlayerHealing(drawingBonus.healAmount);
    }

    final attackerBefore = _player;
    final defenderBefore = _enemy;
    final resolution = _resolveAttackAction(
      attacker: _player,
      defender: _enemy,
      flatAttackBonus: drawingBonus.attackBonus,
    );

    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.attackMotion,
        primarySide: BattleCombatantSide.player,
        secondarySide: BattleCombatantSide.enemy,
        playerBefore: attackerBefore,
        enemyBefore: defenderBefore,
        playerAfter: attackerBefore,
        enemyAfter: defenderBefore,
      ),
    );
    if (_isDisposed || !canUseActions) return;

    await _playCombatStateTransitionAnimations(
      playerBefore: attackerBefore,
      enemyBefore: defenderBefore,
      playerAfter: resolution.attacker,
      enemyAfter: resolution.defender,
    );
    if (_isDisposed || !canUseActions) return;

    _player = resolution.attacker;
    _enemy = resolution.defender;
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (await _completeTurn(BattleTurnState.player)) {
      return;
    }

    if (drawingBonus.endTurnBarrierAmount > 0) {
      await _applyDrawingEndTurnBarrierToPlayer(
        drawingBonus.endTurnBarrierAmount,
      );
    }

    await _beginTurn(BattleTurnState.enemy);
    if (_turn == BattleTurnState.enemy) {
      _scheduleEnemyTurn();
    }
  }

  Future<void> handleBlock({
    BattleAttackDrawingBonus drawingBonus = BattleAttackDrawingBonus.empty,
    BattleAttackDrawingPenalty drawingPenalty =
        BattleAttackDrawingPenalty.empty,
  }) async {
    if (!canUseActions) return;

    if (drawingPenalty.hasAnyPenalty) {
      await _applyDrawingPenalty(drawingPenalty);
      if (_finishImmediatelyIfPlayerIsDown()) {
        return;
      }
    }

    if (drawingBonus.healAmount > 0) {
      await _applyPlayerHealing(drawingBonus.healAmount);
    }

    if (drawingBonus.attackBonus > 0) {
      _player = _player.applyStatus(
        PotenciaStatus(value: drawingBonus.attackBonus),
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

    if (drawingBonus.endTurnBarrierAmount > 0) {
      await _applyDrawingEndTurnBarrierToPlayer(
        drawingBonus.endTurnBarrierAmount,
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

    final shouldResolveAttack = _turnEngine.finishFor(
          player: predictedPlayer,
          enemy: predictedEnemy,
        ) ==
        null;
    if (shouldResolveAttack) {
      final actionResolution = _resolveEnemyAction(
        enemy: predictedEnemy,
        player: predictedPlayer,
        action: plannedAction,
      );
      predictedEnemy = actionResolution.enemy;
      predictedPlayer = actionResolution.player;
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
      barrierGain: barrierGain,
      appliedDebuffs: _buildAppliedDebuffIntents(
        before: initialPlayer,
        after: predictedPlayer,
      ),
    );
  }

  int _combatDurabilityOf(Battler battler) {
    return max(0, battler.health) + max(0, battler.currentBarrier);
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
    await _playCombatAnimation(
      BattleCombatAnimationCue(
        hook: BattleCombatAnimationHook.attackMotion,
        primarySide: BattleCombatantSide.enemy,
        secondarySide: BattleCombatantSide.player,
        playerBefore: player,
        enemyBefore: enemy,
        playerAfter: player,
        enemyAfter: enemy,
      ),
    );
    await _playCombatStateTransitionAnimations(
      playerBefore: player,
      enemyBefore: enemy,
      playerAfter: attackResolution.defender,
      enemyAfter: attackResolution.attacker,
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

  BattleAttackResolution _resolveAttackAction({
    required Battler attacker,
    required Battler defender,
    int flatAttackBonus = 0,
  }) {
    var updatedAttacker = attacker.removeCombatFlag(
      Battler.pendingBasicAttackFollowUpFlag,
    );
    var updatedDefender = defender;
    var totalDamageDealt = 0;
    final attackCount = attacker.basicAttackCount;

    for (var attackIndex = 0; attackIndex < attackCount; attackIndex++) {
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

      final resolution = _resolver.resolveAttack(
        attacker: updatedAttacker,
        defender: updatedDefender,
        flatAttackBonus: flatAttackBonus,
      );
      updatedAttacker = resolution.attacker.removeCombatFlag(
        Battler.pendingBasicAttackFollowUpFlag,
      );
      updatedDefender = resolution.defender;
      totalDamageDealt += resolution.damageDealt;
    }

    return BattleAttackResolution(
      attacker: updatedAttacker.removeCombatFlag(
        Battler.pendingBasicAttackFollowUpFlag,
      ),
      defender: updatedDefender,
      damageDealt: totalDamageDealt,
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
  }) async {
    var visualPlayer = playerBefore;
    var visualEnemy = enemyBefore;

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after =
          side == BattleCombatantSide.player ? playerAfter : enemyAfter;
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
      await _playCombatAnimation(
        _stateTransitionCue(
          hook: hook,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
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
      final after =
          side == BattleCombatantSide.player ? playerAfter : enemyAfter;
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
      final after =
          side == BattleCombatantSide.player ? playerAfter : enemyAfter;
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
  }) {
    return BattleCombatAnimationCue(
      hook: hook,
      primarySide: side,
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: playerAfter,
      enemyAfter: enemyAfter,
    );
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

  Future<void> _beginTurn(
    BattleTurnState nextTurn, {
    bool notify = true,
  }) async {
    _turn = nextTurn;
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

    if (resolution.finish != null) {
      await _playCombatStateTransitionAnimations(
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: nextPlayer,
        enemyAfter: nextEnemy,
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

    final pressureResolution = _applyTurnPressureDamageIfNeeded(
      player: nextPlayer,
      enemy: nextEnemy,
    );
    nextPlayer = pressureResolution.player;
    nextEnemy = pressureResolution.enemy;
    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: nextPlayer,
      enemyAfter: nextEnemy,
    );
    if (_isDisposed) return;
    _player = nextPlayer;
    _enemy = nextEnemy;
    final pressureFinish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (pressureFinish != null) {
      _finishCombat(
        resultType: pressureFinish.resultType,
        resultText: pressureFinish.resultText,
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

    final pressureResolution = _applyTurnPressureDamageIfNeeded(
      player: resolution.player,
      enemy: resolution.enemy,
    );
    _player = pressureResolution.player;
    _enemy = pressureResolution.enemy;

    final finish = _turnEngine.finishFor(
      player: _player,
      enemy: _enemy,
    );
    if (finish != null) {
      _finishCombat(
        resultType: finish.resultType,
        resultText: finish.resultText,
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

    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: resolution.player,
      enemyAfter: resolution.enemy,
    );
    if (_isDisposed) return true;
    _player = resolution.player;
    _enemy = resolution.enemy;
    _registerCompletedTurn();

    if (resolution.finish != null) {
      _finishCombat(
        resultType: resolution.finish!.resultType,
        resultText: resolution.finish!.resultText,
      );
      return true;
    }

    return false;
  }

  void _registerCompletedTurn() {
    _completedTurnsInCurrentRound++;
    if (_completedTurnsInCurrentRound < 2) {
      return;
    }

    _completedTurnsInCurrentRound = 0;
    _currentRound++;
  }

  BattleTurnResolution _applyTurnPressureDamageIfNeeded({
    required Battler player,
    required Battler enemy,
  }) {
    final pressurePercent = _turnPressureDamagePercentForRound(_currentRound);
    if (pressurePercent <= 0) {
      return BattleTurnResolution(player: player, enemy: enemy);
    }

    final playerDamage = _turnPressureDamageForBattler(
      battler: player,
      pressurePercent: pressurePercent,
    );
    final enemyDamage = _turnPressureDamageForBattler(
      battler: enemy,
      pressurePercent: pressurePercent,
    );

    return BattleTurnResolution(
      player: playerDamage > 0 ? player.receiveDamage(playerDamage) : player,
      enemy: enemyDamage > 0 ? enemy.receiveDamage(enemyDamage) : enemy,
    );
  }

  int _turnPressureDamageForBattler({
    required Battler battler,
    required int pressurePercent,
  }) {
    if (battler.isDefeated || pressurePercent <= 0) {
      return 0;
    }

    final rawDamage = (battler.health * pressurePercent / 100).ceil();
    return max(1, rawDamage);
  }

  int _turnPressureDamagePercentForRound(int round) {
    if (round < 10) {
      return 0;
    }

    return (round - 9) * 10;
  }

  Future<void> _applyDrawingEndTurnBarrierToPlayer(int amount) async {
    final playerBefore = _player;
    final enemyBefore = _enemy;
    final playerAfter = _applyDrawingEndTurnBarrier(_player, amount);
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

  Battler _applyDrawingEndTurnBarrier(Battler battler, int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || battler.isDefeated) return battler;

    // El bonus de dibujo representa una barrera temporal y no debe anularse
    // solo porque el tope base del battler sea cero.
    return Battler(
      name: battler.name,
      iconEmoji: battler.iconEmoji,
      archetypeId: battler.archetypeId,
      health: battler.health,
      currentBarrier: battler.currentBarrier + safeAmount,
      money: battler.money,
      income: battler.baseIncome,
      equipmentCapacity: battler.equipmentCapacity,
      level: battler.level,
      experience: battler.experience,
      baseStats: battler.baseStats,
      abilities: battler.abilities,
      statuses: battler.statuses,
      inventoryItems: battler.inventoryItems,
      equippedItems: battler.equippedItems,
      combatFlags: battler.combatFlags,
    );
  }

  Battler _applyBarrierGain(Battler battler, int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || battler.isDefeated) return battler;

    return battler.copyWith(
      currentBarrier: battler.currentBarrier + safeAmount,
    );
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

  Future<void> _applyDrawingPenalty(BattleAttackDrawingPenalty penalty) async {
    final playerBefore = _player;
    final enemyBefore = _enemy;
    if (penalty.directDamage > 0) {
      _player = _player.receiveDirectDamage(
        penalty.directDamage,
        source: _enemy,
      );
    }

    if (penalty.barrierTransferAmount > 0) {
      final transferredBarrier = min(
        _player.currentBarrier,
        penalty.barrierTransferAmount,
      );
      if (transferredBarrier > 0) {
        _player = _player.copyWith(
          currentBarrier: _player.currentBarrier - transferredBarrier,
        );
        _enemy = _enemy.copyWith(
          currentBarrier: _enemy.currentBarrier + transferredBarrier,
        );
      }
    }

    if (penalty.healthTransferAmount > 0) {
      final transferredHealth = min(
        _player.health,
        penalty.healthTransferAmount,
      );
      if (transferredHealth > 0) {
        _player = _player.copyWith(
          health: max(0, _player.health - transferredHealth),
        );
        _enemy = _enemy.heal(transferredHealth);
      }
    }

    if (penalty.transferBuffs) {
      final transferResolution = _transferBuffStatuses(
        source: _player,
        target: _enemy,
      );
      _player = transferResolution.source;
      _enemy = transferResolution.target;
    }

    await _playCombatStateTransitionAnimations(
      playerBefore: playerBefore,
      enemyBefore: enemyBefore,
      playerAfter: _player,
      enemyAfter: _enemy,
    );
  }

  _DrawingBuffTransferResolution _transferBuffStatuses({
    required Battler source,
    required Battler target,
  }) {
    final transferableBuffs = source.statuses
        .where((status) => status.type == BattlerStatusType.buff)
        .toList(growable: false);
    if (transferableBuffs.isEmpty) {
      return _DrawingBuffTransferResolution(
        source: source,
        target: target,
      );
    }

    final sourceWithoutBuffs = source.copyWith(
      statuses: List<BattlerStatus>.unmodifiable(
        source.statuses
            .where((status) => status.type != BattlerStatusType.buff)
            .toList(growable: false),
      ),
    );
    var targetWithStolenBuffs = target;
    for (final buff in transferableBuffs) {
      targetWithStolenBuffs = targetWithStolenBuffs.applyStatus(
        buff.copyWith(),
        applyEquipmentModifiers: false,
      );
    }

    return _DrawingBuffTransferResolution(
      source: sourceWithoutBuffs,
      target: targetWithStolenBuffs,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimers();
    super.dispose();
  }
}

class _DrawingBuffTransferResolution {
  final Battler source;
  final Battler target;

  const _DrawingBuffTransferResolution({
    required this.source,
    required this.target,
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

class EnemyTurnIntentPreview {
  final EnemyTurnAction action;
  final BattlerAbility? activatedBattleAbility;
  final int damage;
  final int barrierGain;
  final List<EnemyTurnDebuffIntent> appliedDebuffs;

  const EnemyTurnIntentPreview({
    this.action = EnemyTurnAction.attack,
    this.activatedBattleAbility,
    this.damage = 0,
    this.barrierGain = 0,
    this.appliedDebuffs = const <EnemyTurnDebuffIntent>[],
  });

  bool get hasAnyEffect {
    return activatedBattleAbility != null ||
        damage > 0 ||
        barrierGain > 0 ||
        appliedDebuffs.isNotEmpty;
  }
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
