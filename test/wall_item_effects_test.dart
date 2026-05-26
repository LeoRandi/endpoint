import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Muralla combat runtime', () {
    test('battle starts with two player walls and one enemy wall', () {
      final controller = BattleController(
        player: defaultPlayerBattler,
        enemy: defaultEnemyBattler,
        phase: RunHourPhase.day,
        enemyTier: 1,
        enemyTurnDelay: Duration.zero,
        combatEndDelay: Duration.zero,
        randomizer: RunRandomizer(seed: 3),
      );
      addTearDown(controller.dispose);

      expect(controller.player.combatWallSegments, hasLength(2));
      expect(controller.enemy.combatWallSegments, hasLength(1));
    });

    test('Taladron destroys crossed enemy walls after its point', () {
      final item = taladronItem.toOwnedInstance();
      final owner = defaultPlayerBattler.copyWith(
        equippedItems: [item],
        patternItemPointKeys: {
          item.instanceId!: const OperativePatternPoint(x: 0, y: 0).key,
        },
      );
      const wall = OperativePatternWallSegment(
        a: OperativePatternPoint(x: 0, y: 0),
        b: OperativePatternPoint(x: 1, y: 0),
      );
      final opponent = defaultEnemyBattler.copyWith(
        combatWallSegments: const [wall],
      );

      final resolution = item.effect!.onPatternUsed(
        owner: owner,
        opponent: opponent,
        item: item,
        pattern: const BattlePatternMatchContext(
          patternPoints: [
            OperativePatternPoint(x: 0, y: 0),
            OperativePatternPoint(x: 1, y: 0),
          ],
          attackBonus: 0,
          barrierBonus: 0,
        ),
      );

      expect(resolution.opponent.combatWallSegments, isEmpty);
      expect(resolution.owner.combatDestroyedWallCount, 1);
    });

    test('Medidor de Rotura gains attack from destroyed walls', () {
      final item = medidorRoturaItem.toOwnedInstance();
      final owner = defaultPlayerBattler
          .copyWith(equippedItems: [item]).recordDestroyedCombatWalls(2);

      expect(
        owner.attack,
        defaultPlayerBattler.attack + item.modifier(BattlerStat.attack) + 2,
      );
    });
  });
}
