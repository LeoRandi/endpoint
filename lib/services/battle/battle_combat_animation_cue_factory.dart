import 'dart:math';

import '../../entities/_exports.dart';
import 'battle_combat_animation.dart';

abstract final class BattleCombatAnimationCueFactory {
  static BattleCombatAnimationCue stateTransitionCue({
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

  static List<BattleCombatFloatingNumberCue> lossFloatingNumbers({
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

  static List<BattleCombatFloatingNumberCue> gainFloatingNumbers({
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

  static Battler visualBattlerTransition({
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
}
