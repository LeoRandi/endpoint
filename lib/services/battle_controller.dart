import '_imports.dart';

enum BattleTurnState {
  player,
  enemy,
  finished,
}

class BattleController extends ChangeNotifier {
  final BattleResolver _resolver;
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
    BattleResolver resolver = const BattleResolver(),
  })  : _enemy = enemy.materializeOwnedItems(),
        _player = player.materializeOwnedItems(),
        _resolver = resolver {
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

    final resolution = _resolver.resolveAttack(
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

  void handleAbility(BattlerAbility ability) {
    if (!canUseActions) return;

    switch (ability.id) {
      case BattlerAbilityId.defend:
        if (_completeTurn(BattleTurnState.player)) {
          return;
        }

        _beginTurn(BattleTurnState.enemy);
        if (_turn == BattleTurnState.enemy) {
          _scheduleEnemyTurn();
        }
        return;
      case BattlerAbilityId.overclock:
      case BattlerAbilityId.purge:
      case BattlerAbilityId.criticalScanner:
      case BattlerAbilityId.weaknessHunter:
      case BattlerAbilityId.ghostMesh:
      case BattlerAbilityId.cruelCatalysis:
      case BattlerAbilityId.venousOverload:
      case BattlerAbilityId.hardReset:
        // TODO: Implement additional battle ability effects once they are designed.
        return;
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

    final resolution = _resolver.resolveAttack(
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

    var updatedPlayer = _player.progressAbilityCooldownsOnTurnStart(
      isOwnerTurn: nextTurn == BattleTurnState.player,
    );
    var updatedEnemy = _enemy.progressAbilityCooldownsOnTurnStart(
      isOwnerTurn: nextTurn == BattleTurnState.enemy,
    );
    updatedPlayer = updatedPlayer.applyStatusTurnStart(
      opponent: _enemy,
      isOwnerTurn: nextTurn == BattleTurnState.player,
    );
    updatedEnemy = updatedEnemy.applyStatusTurnStart(
      opponent: updatedPlayer,
      isOwnerTurn: nextTurn == BattleTurnState.enemy,
    );
    final playerAbilityResolution = updatedPlayer.applyAbilityTurnStartEffects(
      opponent: updatedEnemy,
      isOwnerTurn: nextTurn == BattleTurnState.player,
    );
    updatedPlayer = playerAbilityResolution.owner;
    updatedEnemy = playerAbilityResolution.opponent;
    final enemyAbilityResolution = updatedEnemy.applyAbilityTurnStartEffects(
      opponent: updatedPlayer,
      isOwnerTurn: nextTurn == BattleTurnState.enemy,
    );
    updatedEnemy = enemyAbilityResolution.owner;
    updatedPlayer = enemyAbilityResolution.opponent;
    final playerItemResolution =
        updatedPlayer.applyEquippedItemTurnStartEffects(
      opponent: updatedEnemy,
      isOwnerTurn: nextTurn == BattleTurnState.player,
    );
    updatedPlayer = playerItemResolution.owner;
    updatedEnemy = playerItemResolution.opponent;
    final enemyItemResolution = updatedEnemy.applyEquippedItemTurnStartEffects(
      opponent: updatedPlayer,
      isOwnerTurn: nextTurn == BattleTurnState.enemy,
    );
    updatedEnemy = enemyItemResolution.owner;
    updatedPlayer = enemyItemResolution.opponent;

    _player = updatedPlayer;
    _enemy = updatedEnemy;

    if (_finishCombatFromCurrentState()) {
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _completeTurn(BattleTurnState completedTurn) {
    var updatedPlayer = _player.applyStatusTurnEnd(
      opponent: _enemy,
      isOwnerTurn: completedTurn == BattleTurnState.player,
    );
    var updatedEnemy = _enemy.applyStatusTurnEnd(
      opponent: updatedPlayer,
      isOwnerTurn: completedTurn == BattleTurnState.enemy,
    );
    final playerAbilityResolution = updatedPlayer.applyAbilityTurnEndEffects(
      opponent: updatedEnemy,
      isOwnerTurn: completedTurn == BattleTurnState.player,
    );
    updatedPlayer = playerAbilityResolution.owner;
    updatedEnemy = playerAbilityResolution.opponent;
    final enemyAbilityResolution = updatedEnemy.applyAbilityTurnEndEffects(
      opponent: updatedPlayer,
      isOwnerTurn: completedTurn == BattleTurnState.enemy,
    );
    updatedEnemy = enemyAbilityResolution.owner;
    updatedPlayer = enemyAbilityResolution.opponent;
    final playerItemResolution = updatedPlayer.applyEquippedItemTurnEndEffects(
      opponent: updatedEnemy,
      isOwnerTurn: completedTurn == BattleTurnState.player,
    );
    updatedPlayer = playerItemResolution.owner;
    updatedEnemy = playerItemResolution.opponent;
    final enemyItemResolution = updatedEnemy.applyEquippedItemTurnEndEffects(
      opponent: updatedPlayer,
      isOwnerTurn: completedTurn == BattleTurnState.enemy,
    );
    updatedEnemy = enemyItemResolution.owner;
    updatedPlayer = enemyItemResolution.opponent;

    if (completedTurn == BattleTurnState.player) {
      updatedPlayer = updatedPlayer.decrementStatusDurations();
    } else if (completedTurn == BattleTurnState.enemy) {
      updatedEnemy = updatedEnemy.decrementStatusDurations();
    }

    _player = updatedPlayer;
    _enemy = updatedEnemy;

    return _finishCombatFromCurrentState();
  }

  bool _finishCombatFromCurrentState() {
    if (_enemy.isDefeated) {
      _finishCombat(
        resultType: BattleFlowResultType.victory,
        resultText: 'Objetivo neutralizado.',
      );
      return true;
    }

    if (_player.isDefeated) {
      _finishCombat(
        resultType: BattleFlowResultType.defeat,
        resultText: 'La unidad ha caido.',
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
