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

class BattleController extends ChangeNotifier {
  final BattleResolver _resolver;
  final BattleTurnEngine _turnEngine;
  final BattlerEffectPipeline _effectPipeline;
  final RunRandomizer _randomizer;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;
  final EnemyAiDifficultyLevel _enemyAiDifficulty;

  Battler _enemy;
  Battler _player;
  EnemyTurnAction _enemyNextAction = EnemyTurnAction.attack;
  EnemyTurnAction? _enemyLastResolvedAction;
  int _enemySameActionStreak = 0;
  BattleTurnState _turn = BattleTurnState.player;
  String? _resultText;
  BattleFlowResult? _pendingExitResult;
  int _playerBlockUseCount = 0;
  late final int _playerInitialBlockBarrier;
  late final int _enemyInitialBlockBarrier;

  Timer? _enemyTurnTimer;
  Timer? _combatExitTimer;

  BattleController({
    required Battler enemy,
    required Battler player,
    required int enemyTier,
    required this.enemyTurnDelay,
    required this.combatEndDelay,
    RunRandomizer? randomizer,
    BattlerEffectPipeline effectPipeline = const BattlerEffectPipeline(),
    BattleResolver resolver = const BattleResolver(),
    BattleTurnEngine turnEngine = const BattleTurnEngine(),
  })  : _enemy = enemy.prepareForCombat(),
        _player = player.prepareForCombat(),
        _resolver = resolver,
        _effectPipeline = effectPipeline,
        _randomizer = randomizer ?? RunRandomizer(),
        _enemyAiDifficulty = _difficultyForEnemyTier(enemyTier),
        _turnEngine = turnEngine {
    _playerInitialBlockBarrier = max(0, _player.maxBarrier);
    _enemyInitialBlockBarrier = max(0, _enemy.maxBarrier);
    _enemyNextAction = _rollEnemyTurnAction();
    _beginTurn(BattleTurnState.player, notify: false);
  }

  Battler get enemy => _enemy;
  Battler get player => _player;
  BattleTurnState get turn => _turn;
  bool get isPlayerTurn => _turn == BattleTurnState.player;
  bool get isCombatFinished => _turn == BattleTurnState.finished;
  bool get canUseActions => isPlayerTurn && !isCombatFinished;
  int get playerBlockBarrierGain => _playerCurrentBlockBarrierGain();
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

  void togglePlayerAbility(BattlerAbility ability) {
    if (!canUseActions) return;

    final resolution = _effectPipeline.toggleAbilityActivation(
      owner: _player,
      abilityId: ability.id,
      screenContext: BattlerAbilityActivationContext.battle,
      opponent: _enemy,
    );
    _player = resolution.owner;
    _enemy = resolution.opponent;
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }
    notifyListeners();
  }

  void handleAttack({
    BattleAttackDrawingBonus drawingBonus = BattleAttackDrawingBonus.empty,
    BattleAttackDrawingPenalty drawingPenalty =
        BattleAttackDrawingPenalty.empty,
  }) {
    if (!canUseActions) return;

    if (drawingPenalty.hasAnyPenalty) {
      _applyDrawingPenalty(drawingPenalty);
      if (_finishImmediatelyIfPlayerIsDown()) {
        return;
      }
    }

    if (drawingBonus.healAmount > 0) {
      _player = _player.heal(drawingBonus.healAmount);
    }

    final resolution = _resolveAttackAction(
      attacker: _player,
      defender: _enemy,
      flatAttackBonus: drawingBonus.attackBonus,
    );

    _player = resolution.attacker;
    _enemy = resolution.defender;
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (_completeTurn(BattleTurnState.player)) {
      return;
    }

    if (drawingBonus.endTurnBarrierAmount > 0) {
      _player = _applyDrawingEndTurnBarrier(
        _player,
        drawingBonus.endTurnBarrierAmount,
      );
    }

    _beginTurn(BattleTurnState.enemy);
    if (_turn == BattleTurnState.enemy) {
      _scheduleEnemyTurn();
    }
  }

  void handleBlock({
    int barrierMultiplier = 1,
  }) {
    if (!canUseActions) return;

    final safeMultiplier = max(1, barrierMultiplier);
    final baseBarrierGain = _playerCurrentBlockBarrierGain();
    _playerBlockUseCount++;
    final totalBarrierGain = baseBarrierGain * safeMultiplier;
    final defendResolution = _resolveDefendAction(
      defender: _player,
      opponent: _enemy,
      barrierGain: totalBarrierGain,
    );
    _player = defendResolution.defender;
    _enemy = defendResolution.opponent;

    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (_completeTurn(BattleTurnState.player)) {
      return;
    }

    _beginTurn(BattleTurnState.enemy);
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
    _enemyTurnTimer = Timer(enemyTurnDelay, _resolveEnemyTurn);
  }

  void _resolveEnemyTurn() {
    if (_turn != BattleTurnState.enemy) return;

    final plannedAction = _enemyNextAction;
    final preAttackResolution = _resolveEnemyPreAttackState(
      enemy: _enemy,
      player: _player,
    );
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

    final enemyActionResolution = _resolveEnemyAction(
      enemy: _enemy,
      player: _player,
      action: plannedAction,
    );
    _enemy = enemyActionResolution.enemy;
    _player = enemyActionResolution.player;
    _registerEnemyResolvedAction(plannedAction);
    if (_finishImmediatelyIfPlayerIsDown()) {
      return;
    }

    if (_completeTurn(BattleTurnState.enemy)) {
      return;
    }

    _enemyNextAction = _rollEnemyTurnAction();
    _beginTurn(BattleTurnState.player);
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

  void _beginTurn(BattleTurnState nextTurn, {bool notify = true}) {
    _turn = nextTurn;
    final resolution = _turnEngine.beginTurn(
      isPlayerTurn: nextTurn == BattleTurnState.player,
      player: _player,
      enemy: _enemy,
      randomizer: _randomizer,
    );

    _player = resolution.player;
    _enemy = resolution.enemy;

    if (resolution.finish != null) {
      _finishCombat(
        resultType: resolution.finish!.resultType,
        resultText: resolution.finish!.resultText,
      );
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _completeTurn(BattleTurnState completedTurn) {
    final resolution = _turnEngine.completeTurn(
      didPlayerAct: completedTurn == BattleTurnState.player,
      player: _player,
      enemy: _enemy,
      randomizer: _randomizer,
    );

    _player = resolution.player;
    _enemy = resolution.enemy;

    if (resolution.finish != null) {
      _finishCombat(
        resultType: resolution.finish!.resultType,
        resultText: resolution.finish!.resultText,
      );
      return true;
    }

    return false;
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

  void _applyDrawingPenalty(BattleAttackDrawingPenalty penalty) {
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
