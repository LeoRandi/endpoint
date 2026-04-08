import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/battle_drawing_bonus_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = BattleDrawingBonusResolver();

  test('activates at most one equipped item per recognized matching shape', () {
    final resolution = resolver.resolve(
      equippedItems: const <Item>[
        woodenStickItem,
        crackedBatteryItem,
      ],
      recognizedCounts: const <ItemBonusShape, int>{
        ItemBonusShape.triangle: 2,
        ItemBonusShape.circle: 3,
      },
    );

    expect(resolution.activatedItems, hasLength(2));
    expect(resolution.bonus.attackBonus, 1);
    expect(resolution.bonus.healAmount, 3);
    expect(resolution.bonus.endTurnBarrierAmount, 0);
  });

  test('stacks repeated equipped items of the same shape up to the draw count',
      () {
    final resolution = resolver.resolve(
      equippedItems: const <Item>[
        shieldItem,
        guardShieldItem,
      ],
      recognizedCounts: const <ItemBonusShape, int>{
        ItemBonusShape.square: 3,
      },
    );

    expect(resolution.activatedItems, hasLength(2));
    expect(resolution.bonus.attackBonus, 0);
    expect(resolution.bonus.healAmount, 0);
    expect(resolution.bonus.endTurnBarrierAmount, 2);
  });
}
