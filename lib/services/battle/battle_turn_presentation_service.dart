import 'battle_turn_state.dart';

/// Keeps static combat copy outside the mutable battle controller.
abstract final class BattleTurnPresentationService {
  static String titleFor(BattleTurnState turn) {
    switch (turn) {
      case BattleTurnState.player:
        return 'TURNO DEL JUGADOR';
      case BattleTurnState.enemy:
        return 'TURNO ENEMIGO';
      case BattleTurnState.finished:
        return 'COMBATE FINALIZADO';
    }
  }

  static String descriptionFor({
    required BattleTurnState turn,
    String? resultText,
  }) {
    switch (turn) {
      case BattleTurnState.player:
        return 'Selecciona una acción.';
      case BattleTurnState.enemy:
        return 'El enemigo prepara su respuesta.';
      case BattleTurnState.finished:
        return resultText ?? 'Resolviendo salida del combate...';
    }
  }
}
