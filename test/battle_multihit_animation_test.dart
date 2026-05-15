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

  test('enemy intent shows damage per hit for multi-hit attacks', () {
    final controller = BattleController(
      player: const Battler(
        name: 'PLAYER',
        health: 20,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 20,
          BattlerStat.attack: 1,
          BattlerStat.barrier: 0,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
      ),
      enemy: const Battler(
        name: 'ENEMY',
        health: 20,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 20,
          BattlerStat.attack: 8,
          BattlerStat.barrier: 0,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
        equippedItems: <Item>[sunglassesItem],
      ),
      phase: RunHourPhase.day,
      enemyTier: 1,
      enemyTurnDelay: const Duration(days: 1),
      combatEndDelay: const Duration(days: 1),
      randomizer: RunRandomizer(seed: 1),
    );

    final intent = controller.enemyTurnIntentPreview;

    expect(intent.action, EnemyTurnAction.attack);
    expect(intent.damage, 8);
    expect(intent.attackHitDamage, 4);
    expect(intent.attackHitCount, 2);
    expect(intent.damageLabel, '4x2');

    controller.dispose();
  });

  test('Fragilidad explosion uses a separate animation and damage cue',
      () async {
    final cues = <BattleCombatAnimationCue>[];
    final controller = BattleController(
      player: const Battler(
        name: 'PLAYER',
        health: 20,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 20,
          BattlerStat.attack: 4,
          BattlerStat.barrier: 0,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
      ),
      enemy: const Battler(
        name: 'ENEMY',
        health: 30,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 30,
          BattlerStat.attack: 1,
          BattlerStat.barrier: 0,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
        statuses: <BattlerStatus>[
          FragilidadStatus(value: FragilidadStatus.maxValue),
        ],
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

    final enemyDamageCues = cues
        .where(
          (cue) =>
              cue.primarySide == BattleCombatantSide.enemy &&
              (cue.hook == BattleCombatAnimationHook.healthLoss ||
                  cue.hook == BattleCombatAnimationHook.fragilidadBurst),
        )
        .toList(growable: false);

    expect(enemyDamageCues, hasLength(2));
    expect(enemyDamageCues.first.hook, BattleCombatAnimationHook.healthLoss);
    expect(enemyDamageCues.first.floatingNumbers.single.amount, 4);
    expect(
      enemyDamageCues.last.hook,
      BattleCombatAnimationHook.fragilidadBurst,
    );
    expect(
      enemyDamageCues.last.floatingNumbers.single.tone,
      BattleCombatFloatingNumberTone.fragilidadDamage,
    );
    expect(enemyDamageCues.last.floatingNumbers.single.amount, 10);
    expect(controller.enemy.health, 16);
    expect(controller.enemy.hasStatus(FragilidadStatus.statusId), isFalse);

    controller.dispose();
  });
}
