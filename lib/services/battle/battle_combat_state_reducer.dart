import 'dart:math';

import '../../entities/_exports.dart';
import '../runtime/battler_runtime_service.dart';

/// Pure combat-state transformations shared by battle action handlers.
class BattleCombatStateReducer {
  const BattleCombatStateReducer();

  Battler gainActionBarrier(Battler battler, int amount) {
    return battler.gainCombatBarrier(amount);
  }

  Battler gainBarrier(Battler battler, int amount) {
    return battler.gainCombatBarrier(amount);
  }

  Battler receiveDamageWithBarrierIgnore({
    required Battler owner,
    required int damage,
    int barrierIgnore = 0,
  }) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) return owner;

    final ownerBeforeDamage = owner
        .removeCombatFlagsFor(BattlerCombatFlag.barrierBrokenThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.barrierLostThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.healthLostThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.fragilidadTriggeredThisHit);
    final bypassDamage = min(
      safeDamage,
      min(max(0, barrierIgnore), ownerBeforeDamage.currentBarrier),
    ).toInt();
    final blockableDamage = max(0, safeDamage - bypassDamage).toInt();
    final absorbedByBarrier = min(
      ownerBeforeDamage.currentBarrier,
      blockableDamage,
    ).toInt();
    final healthDamage =
        (bypassDamage + max(0, blockableDamage - absorbedByBarrier)).toInt();

    var updatedOwner = ownerBeforeDamage;
    if (absorbedByBarrier > 0) {
      updatedOwner = updatedOwner
          .copyWith(
            currentBarrier: max(
              0,
              updatedOwner.currentBarrier - absorbedByBarrier,
            ),
          )
          .addCombatFlag(
            CombatRuntimeFlag.battler(
              BattlerCombatFlag.barrierLostThisHit,
              secondaryValue: absorbedByBarrier,
            ),
          );
      if (ownerBeforeDamage.currentBarrier > 0 &&
          updatedOwner.currentBarrier <= 0) {
        updatedOwner = updatedOwner.addCombatFlag(
          Battler.barrierBrokenThisHitFlag,
        );
      }
    }

    if (healthDamage <= 0) return updatedOwner;

    final damagedOwner = updatedOwner
        .copyWith(
          health: max(0, updatedOwner.health - healthDamage).toInt(),
        )
        .addCombatFlag(
          CombatRuntimeFlag.battler(
            BattlerCombatFlag.healthLostThisHit,
            secondaryValue: healthDamage,
          ),
        );
    if (damagedOwner.health > 0) return damagedOwner;

    return damagedOwner.applyEquippedItemFatalDamageEffects(
      incomingDamage: healthDamage,
    );
  }
}
