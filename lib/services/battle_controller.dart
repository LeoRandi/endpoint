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
        _resolver = resolver;

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

    _enemy = resolution.defender;

    if (_enemy.isDefeated) {
      _finishCombat(
        resultType: BattleFlowResultType.victory,
        resultText: 'Objetivo neutralizado.',
      );
      return;
    }

    _turn = BattleTurnState.enemy;
    notifyListeners();
    _scheduleEnemyTurn();
  }

  void handleAbility(BattlerAbility ability) {
    if (!canUseActions) return;

    switch (ability) {
      case BattlerAbility.defend:
        _turn = BattleTurnState.enemy;
        notifyListeners();
        _scheduleEnemyTurn();
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

    _player = resolution.defender;

    if (_player.isDefeated) {
      _finishCombat(
        resultType: BattleFlowResultType.defeat,
        resultText: 'La unidad ha caido.',
      );
      return;
    }

    // TODO: Add enemy ability selection once hostile AI supports more than basic attacks.
    _turn = BattleTurnState.player;
    notifyListeners();
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

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
