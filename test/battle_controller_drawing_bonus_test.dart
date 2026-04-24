import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies drawing attack, heal, and end-turn barrier bonuses', () {
    final controller = BattleController(
      player: const Battler(
        name: 'PLAYER',
        health: 7,
        money: 0,
        income: 0,
        baseStats: <BattlerStat, int>{
          BattlerStat.health: 10,
          BattlerStat.attack: 2,
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
          BattlerStat.attack: 1,
          BattlerStat.barrier: 0,
          BattlerStat.thorns: 0,
          BattlerStat.damageReduction: 0,
          BattlerStat.vampirism: 0,
        },
      ),
      phase: RunHourPhase.day,
      enemyTier: 1,
      enemyTurnDelay: const Duration(days: 1),
      combatEndDelay: const Duration(days: 1),
    );

    controller.handleAttack(
      drawingBonus: const BattleAttackDrawingBonus(
        attackBonus: 1,
        healAmount: 3,
        endTurnBarrierAmount: 1,
      ),
    );

    expect(controller.enemy.health, 17);
    expect(controller.player.health, 10);
    expect(controller.player.currentBarrier, 1);
    expect(controller.turn, BattleTurnState.enemy);

    controller.dispose();
  });
}
