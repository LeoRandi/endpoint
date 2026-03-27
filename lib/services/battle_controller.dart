import '_imports.dart';

enum BattleTurnState {
  player,
  enemy,
  finished,
}

class BattleController extends ChangeNotifier {
  final BattleResolver _resolver;
  final BattleTurnEngine _turnEngine;
  final RunRandomizer _randomizer;
  final Duration enemyTurnDelay;
  final Duration combatEndDelay;

  Battler _enemy;
  Battler _player;
  BattleTurnState _turn = BattleTurnState.player;
  String? _resultText;
  BattleFlowResult? _pendingExitResult;

  Timer? _enemyTurnTimer;
  Timer? _combatExitTimer;

  BattleController({
    required Battler enemy,
    required Battler player,
    required this.enemyTurnDelay,
    required this.combatEndDelay,
    RunRandomizer? randomizer,
    BattleResolver resolver = const BattleResolver(),
    BattleTurnEngine turnEngine = const BattleTurnEngine(),
  })  : _enemy = enemy
            .materializeOwnedItems()
            .clearCombatFlags()
            .addCombatFlag(Battler.combatActiveFlag),
        _player = player
            .materializeOwnedItems()
            .clearCombatFlags()
            .addCombatFlag(Battler.combatActiveFlag),
        _resolver = resolver,
        _randomizer = randomizer ?? RunRandomizer(),
        _turnEngine = turnEngine {
    _beginTurn(BattleTurnState.player, notify: false);
  }

  Battler get enemy => _enemy;
  Battler get player => _player;
  BattleTurnState get turn => _turn;
  bool get isPlayerTurn => _turn == BattleTurnState.player;
  bool get isCombatFinished => _turn == BattleTurnState.finished;
  bool get canUseActions => isPlayerTurn && !isCombatFinished;

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

    final resolution = _player.toggleAbilityActivation(
      abilityId: ability.id,
      screenContext: BattlerAbilityActivationContext.battle,
      opponent: _enemy,
    );
    _player = resolution.owner;
    _enemy = resolution.opponent;
    notifyListeners();
  }

  void handleAttack() {
    if (!canUseActions) return;

    final resolution = _resolveAttackAction(
      attacker: _player,
      defender: _enemy,
    );

    _player = resolution.attacker;
    _enemy = resolution.defender;

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

    _tryResolveEnemyPreAttackAbility();
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

    final resolution = _resolveAttackAction(
      attacker: _enemy,
      defender: _player,
    );

    _enemy = resolution.attacker;
    _player = resolution.defender;

    if (_completeTurn(BattleTurnState.enemy)) {
      return;
    }

    // TODO: Add enemy ability selection once hostile AI supports more than basic attacks.
    _beginTurn(BattleTurnState.player);
  }

  void _tryResolveEnemyPreAttackAbility() {
    final hardReset = _enemy.abilityById(BattlerAbilityId.hardReset);
    if (hardReset == null ||
        !hardReset.canActivateOn(BattlerAbilityActivationContext.pathSelection) ||
        !_shouldEnemyUseHardReset()) {
      return;
    }

    final resolution = _enemy.toggleAbilityActivation(
      abilityId: hardReset.id,
      screenContext: BattlerAbilityActivationContext.pathSelection,
      opponent: _player,
    );
    _enemy = resolution.owner;
    _player = resolution.opponent;
  }

  bool _shouldEnemyUseHardReset() {
    return _enemy.statuses.any(
      (status) =>
          status.isPurgeable &&
          (status is QuemaduraStatus || status is IntoxicacionStatus),
    );
  }

  BattleAttackResolution _resolveAttackAction({
    required Battler attacker,
    required Battler defender,
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
    _cancelTimers();
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

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
