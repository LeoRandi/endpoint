import 'battle_turn_state.dart';

/// Owns the small state machine that advances combat turns and rounds.
class BattleTurnCoordinator {
  BattleTurnState _turn;
  int _currentRound;
  int _completedTurnsInCurrentRound;

  BattleTurnCoordinator({
    BattleTurnState initialTurn = BattleTurnState.player,
    int initialRound = 1,
  })  : _turn = initialTurn,
        _currentRound = initialRound,
        _completedTurnsInCurrentRound = 0;

  BattleTurnState get turn => _turn;
  int get currentRound => _currentRound;

  void begin(BattleTurnState turn) {
    _turn = turn;
  }

  void finish() {
    _turn = BattleTurnState.finished;
  }

  /// Returns the completed round after both combatants have acted.
  int? registerCompletedTurn() {
    _completedTurnsInCurrentRound++;
    if (_completedTurnsInCurrentRound < 2) return null;

    final completedRound = _currentRound;
    _completedTurnsInCurrentRound = 0;
    _currentRound++;
    return completedRound;
  }
}
