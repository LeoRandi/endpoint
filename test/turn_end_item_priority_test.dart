import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('turn end item priority', () {
    test('Bastidor de Respuesta does not recover barrier after poison damage',
        () {
      final item = responseFrameItem.toOwnedInstance();
      final player = defaultPlayerBattler.copyWith(
        health: 10,
        currentBarrier: 0,
        baseStats: {
          ...defaultPlayerBattler.baseStats,
          BattlerStat.barrier: 5,
        },
        statuses: const [
          IntoxicacionStatus(value: 2),
        ],
        equippedItems: [item],
        combatFlags: {
          Battler.combatActiveFlag,
        },
      );
      const enemy = defaultEnemyBattler;
      const engine = BattleTurnEngine();

      final turnStart = engine.beginTurn(
        isPlayerTurn: true,
        player: player,
        enemy: enemy,
      );
      final turnEnd = engine.completeTurn(
        didPlayerAct: true,
        player: turnStart.player,
        enemy: turnStart.enemy,
      );

      expect(turnEnd.player.health, 8);
      expect(turnEnd.player.currentBarrier, 0);
    });

    test('Bastidor de Respuesta recovers barrier when no damage was taken', () {
      final item = responseFrameItem.toOwnedInstance();
      final player = defaultPlayerBattler.copyWith(
        health: 10,
        currentBarrier: 0,
        baseStats: {
          ...defaultPlayerBattler.baseStats,
          BattlerStat.barrier: 5,
        },
        equippedItems: [item],
        combatFlags: {
          Battler.combatActiveFlag,
        },
      );
      const enemy = defaultEnemyBattler;
      const engine = BattleTurnEngine();

      final turnStart = engine.beginTurn(
        isPlayerTurn: true,
        player: player,
        enemy: enemy,
      );
      final turnEnd = engine.completeTurn(
        didPlayerAct: true,
        player: turnStart.player,
        enemy: turnStart.enemy,
      );

      expect(turnEnd.player.health, 10);
      expect(turnEnd.player.currentBarrier, item.value);
    });
  });
}
