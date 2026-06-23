import 'dart:math';

import '../../entities/_exports.dart';
import 'battle_combat_animation.dart';
import 'battle_combat_animation_cue_factory.dart';
import 'battle_turn_state.dart';

/// Converts combat state transitions into UI animation cues.
class BattleAnimationCueProducer {
  const BattleAnimationCueProducer();

  int burnApplicationCountFor(Battler battler) {
    return battler.statuses.whereType<QuemaduraStatus>().where((status) {
      return !status.isExpired && status.currentDamage(battler) > 0;
    }).length;
  }

  int poisonStackCountFor(Battler battler) {
    final poison = battler.statusById(IntoxicacionStatus.statusId);
    if (poison is! IntoxicacionStatus || poison.isExpired) return 0;
    return max(0, poison.currentDamage(battler));
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      turnStartDebuffFloatingNumbers({
    required BattleTurnState activeTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    final affectedSide = activeTurn == BattleTurnState.player
        ? BattleCombatantSide.player
        : BattleCombatantSide.enemy;
    final before =
        affectedSide == BattleCombatantSide.player ? playerBefore : enemyBefore;
    final after =
        affectedSide == BattleCombatantSide.player ? playerAfter : enemyAfter;
    if (burnApplicationCountFor(before) <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    return _damageFloatingNumbersBySide(
      side: affectedSide,
      before: before,
      after: after,
      healthTone: BattleCombatFloatingNumberTone.burnDamage,
    );
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      turnEndDebuffFloatingNumbers({
    required BattleTurnState completedTurn,
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
  }) {
    final affectedSide = completedTurn == BattleTurnState.player
        ? BattleCombatantSide.player
        : BattleCombatantSide.enemy;
    final before =
        affectedSide == BattleCombatantSide.player ? playerBefore : enemyBefore;
    final after =
        affectedSide == BattleCombatantSide.player ? playerAfter : enemyAfter;
    final poisonDamage = poisonStackCountFor(before);
    if (poisonDamage <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    if (barrierLoss <= 0 && healthLoss <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    final floatingNumbers = <BattleCombatFloatingNumberCue>[];
    var remainingHealthLoss = healthLoss;
    if (remainingHealthLoss > 0) {
      final poisonShown = min(poisonDamage, remainingHealthLoss);
      floatingNumbers.add(
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.poisonDamage,
          amount: poisonShown,
        ),
      );
      remainingHealthLoss -= poisonShown;
    }
    if (remainingHealthLoss > 0) {
      floatingNumbers.add(
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.healthDamage,
          amount: remainingHealthLoss,
        ),
      );
    }
    if (barrierLoss > 0) {
      floatingNumbers.add(
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.barrierDamage,
          amount: barrierLoss,
        ),
      );
    }

    return <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{
      affectedSide: List<BattleCombatFloatingNumberCue>.unmodifiable(
        floatingNumbers,
      ),
    };
  }

  List<BattleCombatFloatingNumberCue> purgeFloatingNumbers({
    required Battler before,
    required Battler after,
  }) {
    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    return List<BattleCombatFloatingNumberCue>.unmodifiable([
      if (healthLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.purgeDamage,
          amount: healthLoss,
        ),
      if (barrierLoss > 0)
        BattleCombatFloatingNumberCue(
          tone: BattleCombatFloatingNumberTone.purgeDamage,
          amount: barrierLoss,
        ),
    ]);
  }

  List<BattleCombatAnimationCue> stateTransitionCues({
    required Battler playerBefore,
    required Battler enemyBefore,
    required Battler playerAfter,
    required Battler enemyAfter,
    Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>> floatingNumbersBySide =
        const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{},
  }) {
    final cues = <BattleCombatAnimationCue>[];
    var visualPlayer = playerBefore;
    var visualEnemy = enemyBefore;
    final playerFragilidadDamage = playerBefore.health > playerAfter.health
        ? playerAfter.fragilidadTriggeredThisHit
        : 0;
    final enemyFragilidadDamage = enemyBefore.health > enemyAfter.health
        ? enemyAfter.fragilidadTriggeredThisHit
        : 0;
    final targetPlayerAfter = playerFragilidadDamage > 0
        ? playerAfter.copyWith(
            health: min(
              playerBefore.health,
              playerAfter.health + playerFragilidadDamage,
            ),
            statuses: playerBefore.statuses,
          )
        : playerAfter;
    final targetEnemyAfter = enemyFragilidadDamage > 0
        ? enemyAfter.copyWith(
            health: min(
              enemyBefore.health,
              enemyAfter.health + enemyFragilidadDamage,
            ),
            statuses: enemyBefore.statuses,
          )
        : enemyAfter;

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      final barrierLoss = after.currentBarrier < before.currentBarrier;
      final healthLoss = after.health < before.health;
      if (!barrierLoss && !healthLoss) continue;

      final hook = barrierLoss && healthLoss
          ? BattleCombatAnimationHook.damageTaken
          : healthLoss
              ? BattleCombatAnimationHook.healthLoss
              : BattleCombatAnimationHook.barrierLoss;
      final next = BattleCombatAnimationCueFactory.visualBattlerTransition(
        before: before,
        after: after,
        includeHealth: healthLoss,
        includeBarrier: barrierLoss,
      );
      cues.add(
        BattleCombatAnimationCueFactory.stateTransitionCue(
          hook: hook,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: floatingNumbersBySide[side] ??
              BattleCombatAnimationCueFactory.lossFloatingNumbers(
                before: before,
                after: after,
              ),
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      if (after.currentBarrier <= before.currentBarrier) continue;

      final next = BattleCombatAnimationCueFactory.visualBattlerTransition(
        before: before,
        after: after,
        includeBarrier: true,
      );
      cues.add(
        BattleCombatAnimationCueFactory.stateTransitionCue(
          hook: BattleCombatAnimationHook.barrierGain,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: BattleCombatAnimationCueFactory.gainFloatingNumbers(
            before: before,
            after: after,
            includeBarrier: true,
          ),
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      if (after.health <= before.health) continue;

      final next = BattleCombatAnimationCueFactory.visualBattlerTransition(
        before: before,
        after: after,
        includeHealth: true,
      );
      cues.add(
        BattleCombatAnimationCueFactory.stateTransitionCue(
          hook: BattleCombatAnimationHook.healthGain,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: BattleCombatAnimationCueFactory.gainFloatingNumbers(
            before: before,
            after: after,
            includeHealth: true,
          ),
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final fragilidadDamage = side == BattleCombatantSide.player
          ? playerFragilidadDamage
          : enemyFragilidadDamage;
      if (fragilidadDamage <= 0) continue;

      cues.add(
        BattleCombatAnimationCueFactory.stateTransitionCue(
          hook: BattleCombatAnimationHook.fragilidadBurst,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter:
              side == BattleCombatantSide.player ? playerAfter : visualPlayer,
          enemyAfter:
              side == BattleCombatantSide.enemy ? enemyAfter : visualEnemy,
          floatingNumbers: <BattleCombatFloatingNumberCue>[
            BattleCombatFloatingNumberCue(
              tone: BattleCombatFloatingNumberTone.fragilidadDamage,
              amount: fragilidadDamage,
            ),
          ],
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = playerAfter;
      } else {
        visualEnemy = enemyAfter;
      }
    }

    for (final side in BattleCombatantSide.values) {
      final before =
          side == BattleCombatantSide.player ? visualPlayer : visualEnemy;
      final after = side == BattleCombatantSide.player
          ? targetPlayerAfter
          : targetEnemyAfter;
      final moneyDelta = after.money - before.money;
      if (moneyDelta == 0) continue;

      final next = before.copyWith(money: after.money);
      cues.add(
        BattleCombatAnimationCueFactory.stateTransitionCue(
          hook: BattleCombatAnimationHook.moneyChange,
          side: side,
          playerBefore: visualPlayer,
          enemyBefore: visualEnemy,
          playerAfter: side == BattleCombatantSide.player ? next : visualPlayer,
          enemyAfter: side == BattleCombatantSide.enemy ? next : visualEnemy,
          floatingNumbers: <BattleCombatFloatingNumberCue>[
            BattleCombatFloatingNumberCue(
              tone: moneyDelta > 0
                  ? BattleCombatFloatingNumberTone.moneyGain
                  : BattleCombatFloatingNumberTone.moneyLoss,
              amount: moneyDelta.abs(),
            ),
          ],
        ),
      );
      if (side == BattleCombatantSide.player) {
        visualPlayer = next;
      } else {
        visualEnemy = next;
      }
    }

    return List<BattleCombatAnimationCue>.unmodifiable(cues);
  }

  Map<BattleCombatantSide, List<BattleCombatFloatingNumberCue>>
      _damageFloatingNumbersBySide({
    required BattleCombatantSide side,
    required Battler before,
    required Battler after,
    required BattleCombatFloatingNumberTone healthTone,
  }) {
    final barrierLoss = max(0, before.currentBarrier - after.currentBarrier);
    final healthLoss = max(0, before.health - after.health);
    if (barrierLoss <= 0 && healthLoss <= 0) {
      return const <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{};
    }

    return <BattleCombatantSide, List<BattleCombatFloatingNumberCue>>{
      side: List<BattleCombatFloatingNumberCue>.unmodifiable([
        if (healthLoss > 0)
          BattleCombatFloatingNumberCue(
            tone: healthTone,
            amount: healthLoss,
          ),
        if (barrierLoss > 0)
          BattleCombatFloatingNumberCue(
            tone: BattleCombatFloatingNumberTone.barrierDamage,
            amount: barrierLoss,
          ),
      ]),
    };
  }
}
