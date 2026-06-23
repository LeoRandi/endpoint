import '../../entities/_exports.dart';
import '../runtime/battler_runtime_service.dart';
import 'battle_combat_state_reducer.dart';

class BattleDefendActionResolution {
  final Battler defender;
  final Battler opponent;

  const BattleDefendActionResolution({
    required this.defender,
    required this.opponent,
  });
}

/// Resolves player/enemy actions that do not require UI sequencing.
class BattleActionHandlers {
  final BattleCombatStateReducer stateReducer;

  const BattleActionHandlers({
    this.stateReducer = const BattleCombatStateReducer(),
  });

  BattleDefendActionResolution resolveDefend({
    required Battler defender,
    required Battler opponent,
    required int barrierGain,
  }) {
    final updatedDefender = barrierGain > 0
        ? stateReducer.gainBarrier(defender, barrierGain)
        : defender;
    final itemResolution =
        updatedDefender.applyEquippedItemDefendResolvedEffects(
      opponent: opponent,
    );
    return BattleDefendActionResolution(
      defender: itemResolution.owner,
      opponent: itemResolution.opponent,
    );
  }
}
