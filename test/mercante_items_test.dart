import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mercante item presets', () {
    test('new Mercante items are registered in presets and Mercante pool', () {
      const expectedIds = {
        ItemId.shoppingChecklist,
        ItemId.laCuenta,
        ItemId.seguroBolsillo,
        ItemId.bolsoR33m,
        ItemId.selloMercante,
        ItemId.compraAgresiva,
        ItemId.subastaRelampago,
        ItemId.bolsaRiesgo,
        ItemId.camaraArbitraje,
        ItemId.bancoAmbulante,
      };

      expect(
          itemPresets.map((item) => item.id).toSet(), containsAll(expectedIds));
      expect(mercanteItemPool.map((item) => item.id).toSet(),
          containsAll(expectedIds));
    });

    test('La Cuenta, Bolso R33M and Sello Mercante react to credit movement',
        () {
      final laCuenta = laCuentaItem.toOwnedInstance();
      final bolso = bolsoR33mItem.toOwnedInstance();
      final sello = selloMercanteItem.toOwnedInstance();
      final owner = defaultPlayerBattler.copyWith(
        money: 10,
        health: defaultPlayerBattler.maxHealth - 5,
        equippedItems: [laCuenta, bolso, sello],
        combatFlags: {Battler.combatActiveFlag},
      );

      final afterSpend = owner.spendMoney(4);

      expect(afterSpend.money, 10);
      expect(afterSpend.health, owner.health + sello.value);
      expect(
        afterSpend.itemCombatFlagUseCount(
          item: laCuenta,
          kind: ItemCombatFlagKind.laCuentaPendingAttackBonus,
        ),
        1,
      );
      expect(
        laCuenta.effect!.modifyOutgoingDamage(
          owner: afterSpend,
          target: defaultEnemyBattler,
          item: laCuenta,
          damage: 5,
        ),
        8,
      );
    });

    test('Compra agresiva unlocks one blocking point after three payments', () {
      final item = compraAgresivaItem.toOwnedInstance();
      var owner = defaultPlayerBattler.copyWith(
        money: 20,
        equippedItems: [item],
        combatFlags: {Battler.combatActiveFlag},
      );
      final baseBlockingPoints =
          OperativePatternCombatRules.maxBlockingPointsFor(
        owner,
      );

      for (var index = 0; index < 3; index++) {
        owner = item.effect!
            .onTurnEnd(
              owner: owner,
              opponent: defaultEnemyBattler,
              item: item,
              isOwnerTurn: true,
            )
            .owner;
      }

      expect(
        owner.itemCombatFlagUseCount(
          item: item,
          kind: ItemCombatFlagKind.compraAgresivaPaid,
        ),
        3,
      );
      expect(
        OperativePatternCombatRules.maxBlockingPointsFor(owner),
        baseBlockingPoints + 1,
      );
    });

    test('Subasta Relampago lets a repeated item point score twice', () {
      const repeatedPoint = OperativePatternPoint(x: 0, y: 0);
      final resolution = OperativePatternResolutionService.resolve(
        patternPoints: const [
          repeatedPoint,
          OperativePatternPoint(x: 1, y: 0),
          repeatedPoint,
          OperativePatternPoint(x: 0, y: 1),
          repeatedPoint,
        ],
        equippedItemsByPointKey: {
          repeatedPoint.key: ironSwordItem.copyWith(
            patternRequirementOverride:
                const OperativePatternRequirement.first(),
          ),
          const OperativePatternPoint(x: 1, y: 0).key: subastaRelampagoItem,
        },
        bonusesByPointKey: const {},
      );

      expect(resolution.attackBonus, ironSwordItem.patternBonusAmount * 2);
    });

    test('Subasta Relampago pays once per turn for repeated item points', () {
      final item = subastaRelampagoItem.toOwnedInstance();
      final owner = defaultPlayerBattler.copyWith(
        money: 0,
        equippedItems: [item],
        combatFlags: {Battler.combatActiveFlag},
      );
      const pattern = BattlePatternMatchContext(
        patternPoints: [
          OperativePatternPoint(x: 0, y: 0),
          OperativePatternPoint(x: 1, y: 0),
          OperativePatternPoint(x: 0, y: 0),
        ],
        attackBonus: 0,
        barrierBonus: 0,
        usedItemPointKeys: ['0,0', '0,0'],
        repeatedItemPointKeys: {'0,0'},
        firstRepeatedItemPointKey: '0,0',
      );

      final resolution = owner.applyEquippedItemPatternUsedEffects(
        opponent: defaultEnemyBattler,
        pattern: pattern,
      );

      expect(resolution.owner.money, item.value);
    });
  });
}
