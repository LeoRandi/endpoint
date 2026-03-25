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

    switch (ability) {
      case BattlerAbility.defend:
        if (_completeTurn(BattleTurnState.player)) {
          return;
        }

        _beginTurn(BattleTurnState.enemy);
        if (_turn == BattleTurnState.enemy) {
          _scheduleEnemyTurn();
        }
        return;
      case BattlerAbility.overclock:
      case BattlerAbility.purge:
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

    final playerBeforeHooks = _player;
    final enemyBeforeHooks = _enemy;

    _player = playerBeforeHooks.applyStatusTurnStart(
      opponent: enemyBeforeHooks,
      isOwnerTurn: nextTurn == BattleTurnState.player,
    );
    _enemy = enemyBeforeHooks.applyStatusTurnStart(
      opponent: playerBeforeHooks,
      isOwnerTurn: nextTurn == BattleTurnState.enemy,
    );

    if (_finishCombatFromCurrentState()) {
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _completeTurn(BattleTurnState completedTurn) {
    final playerBeforeHooks = _player;
    final enemyBeforeHooks = _enemy;

    _player = playerBeforeHooks.applyStatusTurnEnd(
      opponent: enemyBeforeHooks,
      isOwnerTurn: completedTurn == BattleTurnState.player,
    );
    _enemy = enemyBeforeHooks.applyStatusTurnEnd(
      opponent: playerBeforeHooks,
      isOwnerTurn: completedTurn == BattleTurnState.enemy,
    );

    if (completedTurn == BattleTurnState.player) {
      _player = _player.decrementStatusDurations();
    } else if (completedTurn == BattleTurnState.enemy) {
      _enemy = _enemy.decrementStatusDurations();
    }

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
