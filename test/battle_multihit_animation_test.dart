import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'multi-hit basic attacks emit one staggered motion and split damage cues',
      () async {
    final cues = <BattleCombatAnimationCue>[];
    final controller = BattleController(
      player: const Battler(
        name: 'PLAYER',
        health: 10,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 10,
          BattlerStat.attack: 6,
          BattlerStat.barrier: 0,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
        equippedItems: <Item>[sunglassesItem],
      ),
      enemy: const Battler(
        name: 'ENEMY',
        health: 20,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 20,
          BattlerStat.attack: 1,
          BattlerStat.barrier: 4,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
      ),
      phase: RunHourPhase.day,
      enemyTier: 1,
      enemyTurnDelay: const Duration(days: 1),
      combatEndDelay: const Duration(days: 1),
      onCombatAnimation: (cue) async {
        cues.add(cue);
      },
    );

    await controller.handleAttack();

    final attackCues = cues
        .where((cue) => cue.hook == BattleCombatAnimationHook.attackMotion)
        .toList(growable: false);
    expect(attackCues, hasLength(1));
    expect(attackCues.single.effectCount, 2);

    final lossCues = cues
        .where(
          (cue) =>
              cue.primarySide == BattleCombatantSide.enemy &&
              (cue.hook == BattleCombatAnimationHook.barrierLoss ||
                  cue.hook == BattleCombatAnimationHook.damageTaken),
        )
        .toList(growable: false);
    expect(lossCues, hasLength(2));
    expect(lossCues.first.hook, BattleCombatAnimationHook.barrierLoss);
    expect(
      lossCues.first.floatingNumbers.single.tone,
      BattleCombatFloatingNumberTone.barrierDamage,
    );
    expect(lossCues.first.floatingNumbers.single.amount, 3);

    expect(lossCues.last.hook, BattleCombatAnimationHook.damageTaken);
    expect(
      lossCues.last.floatingNumbers.map((number) => number.amount),
      <int>[2, 1],
    );
    expect(controller.enemy.health, 18);
    expect(controller.enemy.currentBarrier, 0);

    controller.dispose();
  });
}
